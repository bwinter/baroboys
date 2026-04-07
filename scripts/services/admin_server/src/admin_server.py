import os
import subprocess
from datetime import datetime, timezone

from flask import Flask, render_template, send_from_directory, Response

# Environment-aware paths
ENV = os.getenv("FLASK_ENV", "prod")
THIS_DIR = os.path.dirname(os.path.abspath(__file__))
STATIC_DIR = os.path.join(THIS_DIR, "static") if ENV == "dev" else "/opt/baroboys/static"
TEMPLATE_DIR = os.path.join(THIS_DIR, "templates") if ENV == "dev" else "/opt/baroboys/templates"
LOG_DIR = os.path.join(THIS_DIR, "dev/logs") if ENV == "dev" else "/var/log/baroboys"
STATUS_DIR = os.path.join(THIS_DIR, "dev/status") if ENV == "dev" else "/dev/null"

if ENV == "dev":
    print("🧪 Flask running in dev mode – using stubbed logs.")

app = Flask(__name__, template_folder=TEMPLATE_DIR)


@app.route("/")
def serve_admin():
    return send_from_directory(STATIC_DIR, "admin.html")


@app.route("/ping")
def ping():
    return "pong", 200


@app.route("/trigger-shutdown", methods=["POST"])
def trigger_shutdown():
    try:
        now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

        if ENV == "dev":
            print("🔧 [Dev Mode] Mock shutdown triggered.")
            return {
                "status": "[Dev Mode] Shutdown triggered",
                "time": now,
                "note": "This is mock data. No actual shutdown occurred."
            }, 200

        subprocess.Popen(["sudo", "systemctl", "restart", "game-shutdown.service"])
        return {
            "status": "Shutdown triggered",
            "time": now
        }, 200

    except Exception as e:
        return {
            "status": f"Shutdown Failed: {type(e).__name__}: {e}"
        }, 500


@app.route("/logs/<name>")
def tail_log(name):
    log_map = {
        # Game lifecycle (refresh + startup + shutdown + engine output all write here)
        "game.log": os.path.join(LOG_DIR, "game.log"),
        # Infrastructure
        "admin_server.log": os.path.join(LOG_DIR, "admin_server.log"),
        "refresh_repo.log": os.path.join(LOG_DIR, "refresh_repo.log"),
        "idle_check.log": os.path.join(LOG_DIR, "idle_check.log"),
        "xvfb.log": os.path.join(LOG_DIR, "xvfb.log"),
        # Nginx (subprocess, not file read)
        "nginx_access": ["tail", "-n", "500", "/var/log/nginx/access.log"],
        "nginx_error": ["tail", "-n", "500", "/var/log/nginx/error.log"],
    }

    if ENV == "dev":
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
                return Response("".join(f.readlines()[-500:]), mimetype="text/html")
        else:
            out = subprocess.check_output(cmd, stderr=subprocess.STDOUT, text=True)
            return Response(out, mimetype="text/html")
    except Exception as e:
        return f"Error loading log: {type(e).__name__}: {e}", 500


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
                ("/status.json", "Structured Server Status", "GET"),
                ("/api/trigger-shutdown", "Trigger Graceful Shutdown", "POST"),
            ]
        },
        {
            "icon": "📄",
            "title": "Game Logs",
            "links": [
                ("/api/logs/game.log", "Game Log", "GET"),
                ("/api/logs/idle_check.log", "Idle Check", "GET"),
            ]
        },
        {
            "icon": "🌀",
            "title": "System Logs",
            "links": [
                ("/api/logs/admin_server.log", "Admin Server", "GET"),
                ("/api/logs/refresh_repo.log", "Refresh Repo", "GET"),
                ("/api/logs/xvfb.log", "Xvfb", "GET"),
            ]
        },
        {
            "icon": "🌐",
            "title": "Nginx Logs",
            "links": [
                ("/api/logs/nginx_access", "Nginx Access Log", "GET"),
                ("/api/logs/nginx_error", "Nginx Error Log", "GET"),
            ]
        },
    ]
    return render_template("directory.html", sections=sections)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
