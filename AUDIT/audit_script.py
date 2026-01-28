import os
import yaml
import csv
import subprocess
import paramiko
import logging
from getpass import getpass
from crypto_utils import encrypt_password, decrypt_password

YAML_FILE = "servers.yml"
CSV_FILE = "audit_report.csv"
CSV_FILE_2 = "audit_report_overview.csv"

# ---------------- LOGGING ----------------
logging.basicConfig(
    filename="audit.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

# ---------------- COMMANDS ----------------

LOCAL_CHECKS = [
    {
        "service": "hadoop-namenode",
        "command": "systemctl is-active hadoop-namenode.service",
        "expected": "active"
    },
    {
        "service": "core_container",
        "command": "docker ps --filter 'name=core-v9' --filter 'status=running' --format '{{.Names}}'",
        "expected_contains": "core-v9"
    },
    {
        "service": "core_supervisor",
        "command": "docker exec core-v9 /etc/init.d/supervisor status",
        "expected_contains": "supervisord is running"
    },
    {
        "service": "core_supervisor_services",
        "command": "docker exec core-v9 supervisorctl status",
        "mode": "supervisor_all_running"
    },
    {
        "service": "core_cron",
        "command": "docker exec core-v9 /etc/init.d/cron status",
        "expected_contains": "cron is running"
    },
    {
        "service": "core_etcd",
        "command": "docker exec core-v9 /etc/init.d/etcd status",
        "expected_contains": "etcd is running"
    },
    {
        "service": "core_postgresql",
        "command": "docker exec core-v9 /etc/init.d/postgresql status",
        "expected_contains": "online"
    },
    {
        "service": "core_redis",
        "command": "docker exec core-v9 /etc/init.d/redis-server status",
        "expected_contains": "redis-server is running"
    },
    {
        "service": "datanode-master_container",
        "command": "docker ps --filter 'name=datanode-master-v9' --filter 'status=running' --format '{{.Names}}'",
        "expected_contains": "datanode-master-v9"
    },
    {
        "service": "datanode-master_supervisor",
        "command": "docker exec datanode-master-v9 /etc/init.d/supervisor status",
        "expected_contains": "supervisord is running"
    },
    {
        "service": "datanode-master_supervisor_services",
        "command": "docker exec datanode-master-v9 supervisorctl status",
        "mode": "supervisor_all_running"
    },
    {
        "service": "datanode-master_cron",
        "command": "docker exec datanode-master-v9 /etc/init.d/cron status",
        "expected_contains": "cron is running"
    },
    {
        "service": "datanode-master_ssdb",
        "command": "ps -ef | grep ssdb-server | grep -v grep",
        "expected_contains": "ssdb-master"
    }
]

DATANODE_CHECKS = [
    {
        "service": "hadoop-datanode",
        "command": "systemctl is-active hadoop-datanode.service",
        "expected": "active"
    },
    {
        "service": "spark-master",
        "command": "systemctl is-active spark-master.service",
        "expected": "active"
    },
    {
        "service": "spark-slave",
        "command": "systemctl is-active spark-slave.service",
        "expected": "active"
    },
    {
        "service": "datanode_container",
        "command": "docker ps --filter 'name=datanode-v9' --filter 'status=running' --format '{{.Names}}'",
        "expected_contains": "datanode-v9"
    },
    {
        "service": "datanode_supervisor",
        "command": "docker exec datanode-v9 /etc/init.d/supervisor status",
        "expected_contains": "supervisord is running"
    },
    {
        "service": "datanode_supervisor_services",
        "command": "docker exec datanode-v9 supervisorctl status",
        "mode": "supervisor_all_running"
    },
    {
        "service": "datanode_cron",
        "command": "docker exec datanode-v9 /etc/init.d/cron status",
        "expected_contains": "cron is running"
    },
    {
        "service": "datanode_ssdb",
        "command": "ps -ef | grep ssdb-server | grep -v grep",
        "expected_contains": "ssdb-master"
    },
    {
        "service": "query_server",
        "command": "ps -aux | grep '[q]uery_server'",
        "expected_contains": "query_server"
    },
    {
        "service": "correlation_server",
        "command": "ps -aux | grep '[c]orrelation_server'",
        "expected_contains": "correlation_server"
    },
    {
        "service": "report_server",
        "command": "ps -aux | grep '[r]eport_server'",
        "expected_contains": "report_server"
    }
]

ADAPTER_CHECKS = [
    {
        "service": "adapter_container",
        "command": "docker ps --filter 'name=adapter-v9' --filter 'status=running' --format '{{.Names}}'",
        "expected_contains": "adapter-v9"
    },
    {
        "service": "adapter_supervisor",
        "command": "docker exec adapter-v9 /etc/init.d/supervisor status",
        "expected_contains": "supervisord is running"
    },
    {
        "service": "adapter_supervisor_services",
        "command": "docker exec adapter-v9 supervisorctl status",
        "mode": "supervisor_all_running"
    },
    {
        "service": "adapter_cron",
        "command": "docker exec adapter-v9 /etc/init.d/cron status",
        "expected_contains": "cron is running"
    },
    {
        "service": "adapter_redis",
        "command": "docker exec adapter-v9 /etc/init.d/redis-server status",
        "expected_contains": "redis-server is running"
    },
    {
        "service": "adapter_rabbitmq",
        "command": "docker exec adapter-v9 rabbitmqctl -n rabbit@dnif ping",
        "expected_contains": "Ping succeeded"
    }
]

PICO_CHECKS = [
    {
        "service": "pico_container",
        "command": "docker ps --filter 'name=pico-v9' --filter 'status=running' --format '{{.Names}}'",
        "expected_contains": "pico-v9"
    },
    {
        "service": "pico_supervisor",
        "command": "docker exec pico-v9 /etc/init.d/supervisor status",
        "expected_contains": "supervisord is running"
    },
    {
        "service": "pico_supervisor_services",
        "command": "docker exec pico-v9 supervisorctl status",
        "mode": "supervisor_all_running"
    },
    {
        "service": "pico_cron",
        "command": "docker exec pico-v9 /etc/init.d/cron status",
        "expected_contains": "cron is running"
    },
    {
        "service": "pico_redis",
        "command": "docker exec pico-v9 /etc/init.d/redis-server status",
        "expected_contains": "redis-server is running"
    },
    {
        "service": "pico_rabbitmq",
        "command": "docker exec pico-v9 rabbitmqctl -n rabbit@dnif ping",
        "expected_contains": "Ping succeeded"
    }
]

CHECKS_BY_TYPE = {
    "LOCAL": LOCAL_CHECKS,
    "DATANODE": DATANODE_CHECKS,
    "ADAPTER": ADAPTER_CHECKS,
    "PICO": PICO_CHECKS
}

# ---------------- YAML HANDLING ----------------
def load_or_create_yaml():
    if not os.path.exists(YAML_FILE):
        print("\nservers.yml not found. Creating a new one...\n")
        data = {"servers": {}}
        add_servers(data)
        save_yaml(data)
        return data

    with open(YAML_FILE) as f:
        data = yaml.safe_load(f) or {"servers": {}}

    print("\nExisting servers:")
    for name, s in data["servers"].items():
        print(f"  - {name} [{s['type']}] -> {s['ip']} {s['username']}")

    manage_existing = input("\nDo you want to modify the existing data? (y/n): ").lower()
    if manage_existing == "y":
        manage_servers(data)
        save_yaml(data)

    return data


def save_yaml(data):
    with open(YAML_FILE, "w") as f:
        yaml.dump(data, f)
    print("\nservers.yml updated successfully\n")


def add_servers(data):
    while True:
        name = input("Enter server name (DN1 / AD1 / PC1): ").strip()

        server_type = input(
            "Enter server type (DATANODE / ADAPTER / PICO): "
        ).upper().strip()

        if server_type not in COMMANDS_BY_TYPE:
            print("Invalid server type!")
            continue

        ip = input("Enter IP address: ").strip()
        username = input("Enter username: ").strip()
        password = getpass("Enter password: ")

        data["servers"][name] = {
            "type": server_type,
            "ip": ip,
            "username": username,
            "password": encrypt_password(password)
        }

        if input("Add another server? (y/n): ").lower() != "y":
            break


def manage_servers(data):
    while True:
        print("\n1. Add new server")
        print("2. Update existing server")
        print("3. Done")
        choice = input("Choose an option: ")

        if choice == "1":
            add_servers(data)

        elif choice == "2":
            name = input("Enter server name to update: ").strip()
            if name not in data["servers"]:
                print("Server not found!")
                continue

            server = data["servers"][name]
            print(f"Updating {name} (leave blank to keep existing)")

            new_type = input(
                "Enter server type "
                "(DATANODE / ADAPTER / PICO) "
                f"[{server.get('type')}]: "
            ).upper().strip()

            if new_type:
                if new_type not in COMMANDS_BY_TYPE:
                    print("Invalid server type. Update aborted.")
                    continue
                server_type = new_type
            else:
                server_type = server.get("type")

            if not server_type:
                print("Server type is mandatory!")
                continue

            ip = input(f"IP [{server['ip']}]: ") or server["ip"]
            username = input(f"Username [{server['username']}]: ").strip() or server["username"]
            change_pwd = input("Change password? (y/n): ").lower()

            if change_pwd == "y":
                password = encrypt_password(getpass("New password: "))
            else:
                password = server["password"]

            data["servers"][name] = {
                "type": server_type,
                "ip": ip,
                "username": username,
                "password": password
            }
            print(f"{name} updated successfully ✔")

        elif choice == "3":
            break

        else:
            print("Invalid choice")

# ---------------- STATUS EVALUATOR ----------------
def evaluate_status(output, check):
    output = output.strip()

    # Supervisor: ALL must be RUNNING
    if check.get("mode") == "supervisor_all_running":
        lines = [l for l in output.splitlines() if l.strip()]
        if not lines:
            return "NOT RUNNING"
        for line in lines:
            if "RUNNING" not in line:
                return "NOT RUNNING"
        return "RUNNING"

    # Exact expected match
    if "expected" in check:
        return "RUNNING" if output == check["expected"] else "NOT RUNNING"

    # Substring match
    if "expected_contains" in check:
        return "RUNNING" if check["expected_contains"] in output else "NOT RUNNING"

    return "UNKNOWN"

# ---------------- LOCAL EXECUTION ----------------
def run_local_checks(results):
    for check in CHECKS_BY_TYPE["LOCAL"]:
        result = subprocess.run(
            check["command"],
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        output = result.stdout + result.stderr
        status = evaluate_status(output, check)

        results.append([
            "LOCAL",
            "CO",
            check["service"],
            status,
            output
        ])


# ---------------- REMOTE EXECUTION ----------------
def run_remote_checks(name, server, results):
    server_type = server["type"]
    checks = CHECKS_BY_TYPE.get(server_type, [])

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        ssh.connect(
            server["ip"],
            username=server["username"],
            password=decrypt_password(server["password"]),
            timeout=10
        )

        for check in checks:
            _, stdout, stderr = ssh.exec_command(check["command"])
            output = stdout.read().decode() + stderr.read().decode()

            status = evaluate_status(output, check)

            results.append([
                name,
                server_type,
                check["service"],
                status,
                output
            ])

        ssh.close()

    except Exception as e:
        logging.error(f"{name} FAILED: {e}")
        results.append([
            name,
            server_type,
            "connection",
            "FAILED"
        ])

# ---------------- CSV ----------------
def write_csv(results):
    with open(CSV_FILE, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["HOST", "TYPE", "SERVICE", "STATUS", "OUTPUT"])
        writer.writerows(results)

def summarize_results(results):
    summary = {}

    # Collect data per host
    for row in results:
        host = row[0]     # HOST
        comp_type = row[1]  # TYPE
        status = row[3]   # STATUS

        if host not in summary:
            summary[host] = {
                "type": comp_type,
                "statuses": []
            }

        summary[host]["statuses"].append(status)

    print("\n===== COMPONENT HEALTH SUMMARY =====")

    with open(CSV_FILE_2, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["HOST", "TYPE", "COMPONENT_STATUS"])

        for host, data in summary.items():
            statuses = data["statuses"]
            comp_type = data["type"]

            if all(s == "RUNNING" for s in statuses):
                final_status = "ALL SERVICES RUNNING"
                print(f"{host} → All services running ✅")
            else:
                final_status = "SOME SERVICES NOT RUNNING"
                print(f"{host} → Some services are NOT running ❌")

            writer.writerow([host, comp_type, final_status])


# ---------------- MAIN ----------------
def main():
    data = load_or_create_yaml()
    results = []

    run_local_checks(results)

    for name, server in data["servers"].items():
        run_remote_checks(name, server, results)

    write_csv(results)
    summarize_results(results)

    print("\nAudit completed ✔")
    print(f"CSV report generated: {CSV_FILE}\n")


if __name__ == "__main__":
    main()
