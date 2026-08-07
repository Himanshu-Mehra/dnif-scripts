#!/usr/bin/env python3
"""
credentials.py
============================================================
Loads secrets from a hidden dotfile instead of requiring them typed
into `export` commands (which land in shell history) every time.

DEFAULT LOCATION
  /opt/shadowserver/.shadowserver.api

  Override with the CREDENTIALS_FILE environment variable if you want
  it somewhere else (e.g. a path managed by a secrets tool that drops
  a file on disk).

FORMAT -- simple KEY=VALUE, one per line, like a .env file
  # lines starting with # are comments, blank lines are ignored
  DNIF_EMAIL=himanshu.mehra@dnif.it
  DNIF_PASSWORD=correct-horse-battery-staple

  One file, not one per script -- if this ever needs to also hold
  Shadowserver's own API_KEY/SECRET (the ones shadowserver_relay.py
  originally used) or anything else this pipeline needs, just add
  more KEY=VALUE lines; nothing about the loader is DNIF-specific.

PRECEDENCE
  An already-set environment variable of the same name WINS over
  whatever is in the file. That's deliberate -- it means you can
  still override one value ad hoc (e.g. testing against a different
  account) without editing the file, while the file remains the
  normal day-to-day source of truth for cron runs.

PERMISSIONS
  This file holds plaintext secrets. On load, this warns loudly (does
  NOT refuse to run -- your call whether that should be a hard stop)
  if the file is readable/writable by anyone other than its owner.
  Fix with: chmod 600 /opt/shadowserver/.shadowserver.api

USAGE
  from credentials import load_credentials
  creds = load_credentials()
  email = creds.get("DNIF_EMAIL")
============================================================
"""

import os
import re
import stat
from pathlib import Path

DEFAULT_CREDENTIALS_FILE = Path("/DNIF/SHADOWSERVER_API_INTEGRATION/tool/.shadowserver.api")

_SECTION_HEADER_RE = re.compile(r"^\[.*\]$")


def _check_permissions(path: Path):
    mode = path.stat().st_mode
    # Anything in the group/other bits (readable OR writable by
    # non-owner) is worth a loud warning -- this file holds plaintext
    # secrets.
    if mode & (stat.S_IRWXG | stat.S_IRWXO):
        print(f"  WARNING: {path} is readable/writable by group or other "
              f"(mode {oct(mode)[-3:]}). Recommend: chmod 600 {path}")


def _mask(value: str) -> str:
    """For the debug summary only -- never print a real secret whole."""
    if not value:
        return "(empty)"
    if len(value) <= 4:
        return "*" * len(value)
    return f"{value[:2]}{'*' * (len(value) - 4)}{value[-2:]} (len={len(value)})"


def load_credentials(path: Path = None, debug: bool = True) -> dict:
    """
    Returns a dict of every KEY=VALUE line found in the credentials
    file, with any already-set environment variable of the same name
    taking precedence over the file's value -- including keys that
    exist ONLY as an environment variable and never appeared in the
    file at all.

    Missing file is NOT an error here -- callers decide whether a
    specific key being absent (from both file and environment) is
    fatal for what they need. This just returns whatever it found.

    Tolerant of a few things people commonly do to this kind of file:
      - INI-style [section] headers -- ignored silently, not treated
        as a malformed line, since they're a valid (if unnecessary
        for this flat parser) way to organize a credentials file.
      - Quoted values (KEY="value" or KEY='value') -- quotes stripped.
      - Stray \\r from a file ever saved/edited on Windows.
    """
    if path is None:
        path = Path(os.environ.get("CREDENTIALS_FILE", DEFAULT_CREDENTIALS_FILE))

    creds = {}

    if path.exists():
        _check_permissions(path)
        with open(path) as f:
            for lineno, raw_line in enumerate(f, start=1):
                line = raw_line.strip().rstrip("\r")
                if not line or line.startswith("#"):
                    continue
                if _SECTION_HEADER_RE.match(line):
                    continue  # e.g. "[api]" -- valid INI section marker, not an error
                if "=" not in line:
                    print(f"  WARNING: {path}:{lineno} doesn't look like KEY=VALUE, skipping: {line!r}")
                    continue
                key, _, value = line.partition("=")
                key = key.strip()
                value = value.strip().rstrip("\r")
                if len(value) >= 2 and value[0] == value[-1] and value[0] in ("'", '"'):
                    value = value[1:-1]
                creds[key] = value
    else:
        print(f"  no credentials file at {path} -- relying on environment variables only")

    # Environment variables override the file, and also count even if
    # a key never appeared in the file at all -- restricted to the
    # KEY_ prefixes this pipeline actually uses, so we don't
    # accidentally hoover up unrelated environment variables.
    relevant_prefixes = ("DNIF_", "SHADOWSERVER_")
    for env_key, env_value in os.environ.items():
        if env_key in creds or env_key.startswith(relevant_prefixes):
            creds[env_key] = env_value

    if debug:
        print(f"  credentials loaded from {path if path.exists() else '(file not found)'}:")
        for key in sorted(creds.keys()):
            print(f"    {key} = {_mask(creds[key])}")

    return creds


def require(creds: dict, *keys):
    """Fail loudly and specifically if any of `keys` is missing/empty,
    naming exactly which ones and where to set them -- rather than a
    generic KeyError three calls later."""
    missing = [k for k in keys if not creds.get(k)]
    if missing:
        raise SystemExit(
            f"Missing required credential(s): {', '.join(missing)}\n"
            f"Set them either in {DEFAULT_CREDENTIALS_FILE} (KEY=VALUE per line) "
            f"or as environment variables."
        )
