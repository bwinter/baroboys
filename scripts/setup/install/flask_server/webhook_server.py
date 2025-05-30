import os
import re
from datetime import datetime, timezone
from functools import lru_cache
import subprocess
from flask import Flask, render_template, send_from_directory, Response, request

# Environment-based path handling
if os.getenv("FLASK_ENV") == "development":
    STATIC_DIR = "./static"
    TEMPLATE_DIR = "./templates"
    LOG_DIR = "./dev/logs"
    STATUS_PATH = "./dev/status/vrising.status"
else:
    STATIC_DIR = "/opt/baroboys/static"
    TEMPLATE_DIR = "/opt/baroboys/templates"
    LOG_DIR = "/home/bwinter_sc81/baroboys/VRising/logs"

app = Flask(__name__, template_folder=TEMPLATE_DIR)

# Utility Functions
@lru_cache(maxsize=1)
def get_server_password():
    result = subprocess.run(
        ["gcloud", "secrets", "versions", "access", "latest", "--secret=server-password"],
        capture_output=True,
        text=True,
        check=True
    )
    return result.stdout.strip()

def mcrcon_cmd(cmd):
    password = get_server_password()
    result = subprocess.run(
        ["/usr/bin/mcrcon", "-H", "127.0.0.1", "-P", "25575", "-p", password, cmd],
        capture_output=True,
        text=True,
        timeout=5
    )
    return result.stdout.strip()

# Basic routes
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
        return {"status": f"Shutdown Failed: {e}"}, 500

# API endpoints (clearly separated)
@app.route("/api/players")
def api_players():
    try:
        raw_players = mcrcon_cmd("ListUsers")
        players = [
            line.split()[0] for line in raw_players.splitlines()
            if "@" in line and not line.startswith("No players")
        ]
        return {"players": players}
    except Exception as e:
        return {"error": f"Failed to fetch players: {type(e).__name__}: {e}"}, 500

@app.route("/api/time")
def api_time():
    try:
        server_time = mcrcon_cmd("GetTime").strip()
        return {"time": server_time}
    except Exception as e:
        return {"error": f"Failed to fetch server time: {type(e).__name__}: {e}"}, 500

@app.route("/api/shutdown")
def api_shutdown():
    try:
        raw_shutdown = mcrcon_cmd("GetShutdown")
        shutdown_info = {
            "scheduled": "in" in raw_shutdown.lower(),
            "in_minutes": None,
            "raw": raw_shutdown.strip()
        }
        match = re.search(r"in (\d+) minutes", raw_shutdown)
        if match:
            shutdown_info["in_minutes"] = int(match.group(1))
        return shutdown_info
    except Exception as e:
        return {"error": f"Failed to fetch shutdown info: {type(e).__name__}: {e}"}, 500

@app.route("/api/settings")
def api_settings():
    try:
        raw_settings = mcrcon_cmd("ServerSettings")
        settings = {}
        for line in raw_settings.splitlines():
            if "=" in line:
                key, val = line.split("=", 1)
                settings[key.strip()] = val.strip()
        return settings
    except Exception as e:
        return {"error": f"Failed to fetch settings: {type(e).__name__}: {e}"}, 500

# Status and logs
@app.route("/api/check-status")
def check_status():
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    try:
        output = subprocess.check_output(
            ["systemctl", "status", "vrising.service", "--no-pager"],
            stderr=subprocess.STDOUT,
            text=True
        ).strip()
        return f"⏱ Refreshed: {now}\n\n{output}", 200, {"Content-Type": "text/plain"}
    except Exception as e:
        error_message = f"⚠️ Failed to run systemctl.\n\n{type(e).__name__}: {e}"
        return f"⏱ Refreshed: {now}\n\n{error_message}", 200, {"Content-Type": "text/plain"}

@app.route("/api/logs/tail/<path:filename>")
def tail_log(filename):
    safe_name = filename.replace("/", "").replace("..", "")
    log_path = os.path.join(LOG_DIR, safe_name)
    if not os.path.isfile(log_path):
        return f"Log file not found: {safe_name}", 404
    try:
        with open(log_path, "r", encoding="utf-8", errors="ignore") as f:
            lines = f.readlines()
            tail = lines[-100:]
        return Response(
            "<pre>" + "".join(tail) + "</pre>",
            mimetype="text/html"
        )
    except Exception as e:
        return f"Error reading log: {e}", 500

@app.route("/directory")
def directory():
    pages = [
        ("/", "Admin Panel"),
        ("/directory", "Site Directory"),
        ("/api/check-status", "Live Server Status"),
        ("/api/trigger-shutdown", "Trigger Graceful Shutdown (POST)"),
        ("/api/logs/tail/VRisingServer.log", "Tail VRisingServer.log"),
        ("/api/logs/tail/startup.log", "Tail startup.log"),
        ("/api/logs/tail/shutdown.log", "Tail shutdown.log"),
        ("/api/ping", "Health Check"),
        ("/api/players", "List Players (API)"),
        ("/api/time", "Server Time (API)"),
        ("/api/shutdown", "Shutdown Status (API)"),
        ("/api/settings", "Server Settings (API)"),
    ]
    return render_template("directory.html", pages=pages)

@app.errorhandler(404)
def not_found(e):
    return render_template(
        "404.html",
        path=request.path,
        timestamp=datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    ), 404

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

# Pre-fetch cached secret
get_server_password()
