#!/usr/bin/env python3
"""
dnif_client.py
============================================================
Shared DNIF console API client.

AUTH -- two methods, "login" is the default now
  "login" (default): POSTs to /lc/users/login with an email + a
    password hash, gets a fresh SSID back directly in the response --
    confirmed from your captured HAR file. This is what fixes the
    original problem (script fails when nobody's logged in via
    browser, because Redis has nothing to scrape): the script logs
    itself in, so it no longer depends on anyone else's active
    session. It also removes the docker/redis-cli dependency
    entirely -- this can now run from any host with network access to
    DNIF, not just one with a docker exec into the console container.

  "redis" (legacy, kept for compatibility): the original Redis-scrape
    approach from dnif_audit2.py. Still requires an active browser
    session to have populated Redis, and still requires docker exec
    access to the console container. Use this only if you have a
    specific reason to keep it -- the login method solves the actual
    problem you raised.

CST PASS FORMAT -- ASSUMPTION TO CONFIRM
  The captured request body was {"cstPass": "<32-char hex>",
  "emailId": "..."}. That's the shape of an unsalted MD5 hash of the
  plaintext password, computed client-side. This client assumes
  cstPass = hashlib.md5(password.encode()).hexdigest() -- if login
  fails with a real password, that's the first thing to check; the
  actual hashing (case, encoding, any extra salt) might differ
  slightly from this guess.

  Separately, worth flagging to whoever owns DNIF's auth if not
  already known: unsalted MD5 sent over the wire is weak from a
  security standpoint. Not something this client can fix, just
  surfacing it since it's directly relevant to what this does.

TENANT AUTO-DISCOVERY
  The login response includes clusterId per entry in `access` --
  that's the same value used as the tenant path segment on every
  other endpoint (confirmed: it matches the hardcoded tenant used in
  the eventstore captures). So `tenant` is now optional -- if omitted,
  it's read from the first entry in the login response's `access`
  list. If the account has access to more than one cluster, this
  prints a warning and picks the first; pass tenant= explicitly to
  choose a specific one.

EVENTSTORE METHODS (unchanged from before) -- reverse-engineered from
captured browser traffic:

  POST /api/event_store/list    -> list existing eventstores
  POST /api/event_store/upload  -> multipart (scope_id, name, file),
                                    returns a dispatcher task id
  GET  /wrk/api/dispatcher/task/state/<task_id>
                                 -> poll until task_state == "SUCCESS"

UPLOAD IS ASYNC. The /upload call only confirms DNIF accepted the
file and queued a job:
    {"message": "Event store uploaded", "data": ["<task_id>"]}
That does NOT mean the store is populated yet. Your captures show
the dispatcher task going STARTED/EXECUTING -> SUCCESS/EXECUTED --
you have to poll task/state and see SUCCESS before it's safe to
assume the eventstore has the new data (e.g. before triggering
anything downstream that depends on it, or before deleting the
source CSV).

ONE THING IN YOUR CAPTURES I CAN'T FULLY EXPLAIN: one request
returned {"status":"failed","message":"Invalid store name"} before a
later successful attempt with the SAME name ("TESTINGEVT") went
through and the store then appeared in event_store/list. That points
to either a transient issue, or a validation rule on `name` (e.g. no
spaces/special characters) that the retry happened to satisfy -- I
don't have the failed request's exact payload to pin down which. This
client surfaces that failure message as-is rather than guessing a
rule to enforce client-side. If you hit it again, capture that
specific failing request's payload/headers and I'll nail down the
actual constraint and validate for it before upload.
============================================================
"""

import base64
import hashlib
import subprocess
import sys
import time

import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


class DnifClient:
    def __init__(self, host, tenant=None, auth_method="login",
                 email=None, password=None,
                 redis_container="console-v9", redis_password_b64=None,
                 verify_ssl=False):
        self.host = host
        self.verify_ssl = verify_ssl
        self.auth_method = auth_method

        if auth_method == "login":
            if not email or not password:
                raise ValueError("email and password are required for auth_method='login'")
            self.ssid, discovered_tenant = self._login(email, password)
            self.tenant = tenant or discovered_tenant
        elif auth_method == "redis":
            if not tenant:
                raise ValueError("tenant is required for auth_method='redis'")
            self.tenant = tenant
            self.ssid = self._get_ssid_via_redis(redis_container, redis_password_b64)
        else:
            raise ValueError(f"unknown auth_method: {auth_method!r} (use 'login' or 'redis')")

        self.base_url = f"https://{self.host}/{self.tenant}"
        self.headers = {
            "accept": "application/json",
            "ssid": self.ssid,
        }

    def _login(self, email, password):
        """POST /lc/users/login -- note this hits the host root, NOT
        the tenant-scoped base_url, since the tenant isn't known until
        this response tells us."""
        cst_pass = hashlib.md5(password.encode()).hexdigest()  # CONFIRM: see docstring above

        resp = requests.post(
            f"https://{self.host}/lc/users/login",
            headers={"accept": "application/json", "content-type": "application/json"},
            json={"emailId": email, "cstPass": cst_pass},
            verify=self.verify_ssl,
            timeout=30,
        )
        if resp.status_code != 200:
            # DNIF's actual reason (if any) is almost always more useful
            # than a bare "400 Client Error" -- surface it before failing,
            # rather than letting raise_for_status() hide the response body.
            try:
                detail = resp.json()
            except ValueError:
                detail = resp.text
            raise RuntimeError(
                f"DNIF login returned {resp.status_code} for emailId={email!r}: {detail}\n"
                f"If this is an auth failure rather than a malformed request, double-check: "
                f"(1) the password value loaded correctly from the credentials file -- see the "
                f"masked credentials summary printed at startup, (2) the cstPass hashing "
                f"assumption (unsalted MD5 of the plaintext password) still matches what DNIF "
                f"expects -- this was never confirmed against a real login, only inferred from "
                f"one successful captured request."
            )
        body = resp.json()
        if body.get("status") != "success":
            raise RuntimeError(f"DNIF login failed: {body}")

        data = body["data"]
        ssid = data["SSID"]
        access_list = data.get("access", [])
        if not access_list:
            raise RuntimeError(f"login succeeded but returned no cluster access: {body}")
        if len(access_list) > 1:
            print(f"  WARNING: this account has access to {len(access_list)} clusters -- "
                  f"using the first ({access_list[0].get('clusterName')}). Pass tenant= "
                  f"explicitly to pick a specific one instead.")
        cluster_id = access_list[0]["clusterId"]
        return ssid, cluster_id

    def _get_ssid_via_redis(self, redis_container, redis_password_b64):
        """Legacy path -- requires an active browser session and
        docker exec access to the console container. Prefer
        auth_method='login' unless you have a specific reason not to."""
        result = subprocess.run(
            ["docker", "ps", "--format", "{{.Names}}"],
            capture_output=True, text=True,
        )
        if redis_container not in result.stdout.splitlines():
            sys.exit(f"Docker container {redis_container} not running")

        redis_password = base64.b64decode(redis_password_b64).decode("utf-8")
        redis_cmd = (
            f"redis-cli -a '{redis_password}' -p 6379 "
            f"--scan --pattern 'ssid:*' 2>/dev/null"
        )
        result = subprocess.run(
            ["docker", "exec", redis_container, "sh", "-c", redis_cmd],
            capture_output=True, text=True,
        )
        ssid_lines = [l for l in result.stdout.splitlines() if l.startswith("ssid:")]
        if not ssid_lines:
            sys.exit("Could not fetch SSID from Redis -- no active browser session? "
                      "Consider switching to auth_method='login' instead.")
        return ssid_lines[-1].split(":", 1)[1]

    def eventstore_list(self, scope_id="default", pageno=1, pagesize=100):
        resp = requests.post(
            f"{self.base_url}/api/event_store/list",
            headers={**self.headers, "content-type": "application/json"},
            json={"pageno": pageno, "pagesize": pagesize, "scope_id": scope_id},
            verify=self.verify_ssl,
            timeout=30,
        )
        resp.raise_for_status()
        return resp.json()

    def eventstore_exists(self, name, scope_id="default"):
        data = self.eventstore_list(scope_id=scope_id, pagesize=1000)
        return any(row.get("name") == name for row in data.get("data", []))

    def eventstore_delete(self, store_name, scope_id="default"):
        """
        POST /api/event_store/delete -- confirmed via captured traffic.
        Payload: {"scope_id": ..., "name": ...}
        Response on success: {"status":"success","data":"Delete event
        store Successfully"}. Only call this when the store is known
        to exist (see eventstore_exists) -- behavior when it doesn't
        exist wasn't captured, so this doesn't guess at it.
        """
        resp = requests.post(
            f"{self.base_url}/api/event_store/delete",
            headers={**self.headers, "content-type": "application/json"},
            json={"scope_id": scope_id, "name": store_name},
            verify=self.verify_ssl,
            timeout=30,
        )
        resp.raise_for_status()
        body = resp.json()
        if body.get("status") != "success":
            raise RuntimeError(f"eventstore delete failed: {body}")
        return body

    def eventstore_upload(self, csv_path, store_name, scope_id="default"):

        """POST the multipart upload. Returns the dispatcher task id."""
        with open(csv_path, "rb") as f:
            resp = requests.post(
                f"{self.base_url}/api/event_store/upload",
                headers=self.headers,  # let requests set multipart content-type/boundary
                data={"scope_id": scope_id, "name": store_name},
                files={"file": (csv_path.split("/")[-1], f, "application/csv")},
                verify=self.verify_ssl,
                timeout=60,
            )
        resp.raise_for_status()
        body = resp.json()
        if body.get("status") != "success":
            raise RuntimeError(f"eventstore upload rejected: {body}")
        return body["data"][0]  # task id, e.g. "5479fbbf-2d24-4fcc-90e3-e64e44e91b28-id-1"

    def wait_for_task(self, task_id, poll_interval=2, timeout=120):
        deadline = time.time() + timeout
        while time.time() < deadline:
            resp = requests.get(
                f"{self.base_url}/wrk/api/dispatcher/task/state/{task_id}",
                headers=self.headers,
                verify=self.verify_ssl,
                timeout=30,
            )
            resp.raise_for_status()
            body = resp.json()
            state = body.get("task_state")
            if state == "SUCCESS":
                return body
            if state in ("FAILURE", "FAILED", "ERROR"):
                raise RuntimeError(f"eventstore task {task_id} failed: {body}")
            time.sleep(poll_interval)
        raise TimeoutError(f"eventstore task {task_id} did not finish within {timeout}s")

    def upload_and_wait(self, csv_path, store_name, scope_id="default"):
        """Upload a CSV and block until DNIF finishes processing it."""
        task_id = self.eventstore_upload(csv_path, store_name, scope_id=scope_id)
        return self.wait_for_task(task_id)

    def replace_and_upload(self, csv_path, store_name, scope_id="default"):
        """
        Delete-then-upload. DNIF rejects re-uploading to a store name
        that already exists, so a daily refresh has to clear the old
        store first, then upload fresh -- this is what makes sure no
        stale IOC/exposure rows linger past their refresh cycle.
        """
        if self.eventstore_exists(store_name, scope_id=scope_id):
            print(f"  '{store_name}' already exists -- deleting before re-upload")
            self.eventstore_delete(store_name, scope_id=scope_id)
        return self.upload_and_wait(csv_path, store_name, scope_id=scope_id)

