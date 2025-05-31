import os
import re
import subprocess
from datetime import datetime, timezone
from functools import lru_cache

from flask import Flask, render_template, send_from_directory, Response, request

# Environment-aware paths
ENV = os.getenv("FLASK_ENV", "production")
STATIC_DIR = "./static" if ENV == "development" else "/opt/baroboys/static"
TEMPLATE_DIR = "./templates" if ENV == "development" else "/opt/baroboys/templates"
LOG_DIR = "./dev/logs" if ENV == "development" else "/home/bwinter_sc81/baroboys/VRising/logs"
STATUS_DIR = "./dev/status" if ENV == "development" else "/dev/null"

if ENV == "development":
    print("🧪 Flask running in development mode – using stubbed logs.")

app = Flask(__name__, template_folder=TEMPLATE_DIR)


@lru_cache(maxsize=1)
def get_server_password():
    return subprocess.run(
        ["gcloud", "secrets", "versions", "access", "latest", "--secret=server-password"],
        capture_output=True, text=True, check=True
    ).stdout.strip()


def mcrcon_cmd(cmd):
    try:
        result = subprocess.run(
            ["mcrcon", "-H", "127.0.0.1", "-P", "25575", "-p", get_server_password(), cmd],
            capture_output=True, text=True, timeout=5, check=True
        )
        print(f"🛰️ RCON command: {cmd}")
        print(f"📥 stdout: {result.stdout.strip()}")
        print(f"⚠️ stderr: {result.stderr.strip()}")
        return result
    except subprocess.CalledProcessError as e:
        print(f"RCON Error: {e.stderr.strip()}")
        return e
    except subprocess.TimeoutExpired:
        print("RCON Timeout")
        return None
    except Exception as e:
        print(f"RCON Exception: {type(e).__name__}: {e}")
        return None


@app.route("/")
def serve_admin():
    return send_from_directory(STATIC_DIR, "admin.html")


@app.route("/api/ping")
def ping():
    return "pong", 200


@app.route("/api/trigger-shutdown", methods=["POST"])
def trigger_shutdown():
    try:
        subprocess.Popen(["systemctl", "start", "shutdown.service"])
        now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
        return {"status": "Shutdown triggered", "time": now}, 200
    except Exception as e:
        return {"status": f"Shutdown Failed: {type(e).__name__}: {e}"}, 500


@app.route("/api/check-status")
def check_status():
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

    if ENV == "development":
        try:
            with open(os.path.join(STATUS_DIR, "vrising.status"), "r", encoding="utf-8") as f:
                content = f.read().strip()
            return f"⏱ Refreshed: {now}\n\n{content}", 200, {"Content-Type": "text/plain"}
        except Exception as e:
            return f"⏱ Refreshed: {now}\n\n⚠️ Dev status file error: {type(e).__name__}: {e}", 200, {
                "Content-Type": "text/plain"}

    # Production: live systemctl
    try:
        output = subprocess.check_output(
            ["systemctl", "status", "vrising.service", "--no-pager"],
            stderr=subprocess.STDOUT, text=True
        ).strip()
        return f"⏱ Refreshed: {now}\n\n{output}", 200, {"Content-Type": "text/plain"}
    except Exception as e:
        return f"⏱ Refreshed: {now}\n\n⚠️ {type(e).__name__}: {e}", 200, {"Content-Type": "text/plain"}


@app.route("/api/logs/<name>")
def tail_log(name):
    log_map = {
        "VRisingServer.log": os.path.join(LOG_DIR, "VRisingServer.log"),
        "startup.log": os.path.join(LOG_DIR, "startup.log"),
        "shutdown.log": os.path.join(LOG_DIR, "shutdown.log"),
        "vrising_idle_check.log": os.path.join(LOG_DIR, "vrising_idle_check.log"),
        "admin_server.log": os.path.join(LOG_DIR, "admin_server.log"),
        "nginx_access": ["tail", "-n", "100", "/var/log/nginx/access.log"],
        "nginx_error": ["tail", "-n", "100", "/var/log/nginx/error.log"],
    }

    if ENV == "development":
        log_map.update({
            "nginx_access": os.path.join(LOG_DIR, "nginx_access.log"),
            "nginx_error": os.path.join(LOG_DIR, "nginx_error.log"),
        })

    cmd = log_map.get(name)
    if cmd is None:
        return f"Unknown log: {name}", 404
    try:
        if isinstance(cmd, str):
            with open(cmd, encoding="utf-8", errors="ignore") as f:
                return Response("".join(f.readlines()[-100:]), mimetype="text/html")
        else:
            out = subprocess.check_output(cmd, stderr=subprocess.STDOUT, text=True)
            return Response(out, mimetype="text/html")
    except Exception as e:
        return f"Error loading log: {type(e).__name__}: {e}", 500


@app.route("/api/players")
def api_players():
    if ENV == "development":
        return {"players": ["Alice", "Bob", "Charlie"]}
    try:
        lines = mcrcon_cmd("ListUsers").splitlines()
        players = [l.split()[0] for l in lines if "@" in l and not l.startswith("No players")]
        return {"players": players}
    except Exception as e:
        return {"error": f"Fetch failed: {type(e).__name__}: {e}"}, 500


@app.route("/api/time")
def api_time():
    result = mcrcon_cmd("GetTime")
    if result and result.stdout:
        return {"time": result.stdout.strip()}
    else:
        return {"error": "Failed to fetch time"}, 500


@app.route("/api/shutdown")
def api_shutdown():
    if ENV == "development":
        return {
            "scheduled": True,
            "in_minutes": 8,
            "raw": "Server shutdown scheduled in 8 minutes"
        }
    try:
        raw = mcrcon_cmd("GetShutdown")
        match = re.search(r"in (\d+) minutes", raw)
        return {
            "scheduled": "in" in raw.lower(),
            "in_minutes": int(match.group(1)) if match else None,
            "raw": raw.strip()
        }
    except Exception as e:
        return {"error": f"Failed to fetch shutdown info: {type(e).__name__}: {e}"}, 500


@app.route("/api/settings")
def api_settings():
    if ENV == "development":
        return {
            "GameModeType": "PvE",
            "AllowGlobalChat": "true",
            "BloodBoundEquipment": "false"
        }
    try:
        lines = mcrcon_cmd("ServerSettings").splitlines()
        return {k.strip(): v.strip() for line in lines if "=" in line for k, v in [line.split("=", 1)]}
    except Exception as e:
        return {"error": f"Fetch failed: {type(e).__name__}: {e}"}, 500


@app.route("/directory")
def directory():
    sections = [
        {
            "icon": "🛠",
            "title": "Admin",
            "links": [
                ("/", "Admin Panel", "GET"),
                ("/directory", "Site Directory", "GET"),
                ("/api/ping", "Health Check", "GET"),
            ]
        },
        {
            "icon": "🎮",
            "title": "Game Control",
            "links": [
                ("/api/check-status", "Live Server Status", "GET"),
                ("/api/trigger-shutdown", "Trigger Graceful Shutdown", "POST"),
            ]
        },
        {
            "icon": "📄",
            "title": "Game Logs",
            "links": [
                ("/api/logs/VRisingServer.log", "V Rising Server Logs", "GET"),
                ("/api/logs/startup.log", "VM Startup Logs", "GET"),
                ("/api/logs/shutdown.log", "VM Shutdown Logs", "GET"),
                ("/api/logs/vrising_idle_check.log", "V Rising Idle Check Logs", "GET"),
            ]
        },
        {
            "icon": "🌀",
            "title": "System Logs",
            "links": [
                ("/api/logs/admin", "Admin Server Logs", "GET"),
            ]
        },
        {
            "icon": "🌐",
            "title": "Nginx Logs",
            "links": [
                ("/api/logs/nginx/access", "Nginx Access Log", "GET"),
                ("/api/logs/nginx/error", "Nginx Error Log", "GET"),
            ]
        },
    ]
    return render_template("directory.html", sections=sections)


@app.errorhandler(404)
def not_found(e):
    return render_template("404.html", path=request.path,
                           timestamp=datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")), 404


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

get_server_password()  # warm secret cache
