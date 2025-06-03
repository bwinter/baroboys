import os
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
    return 'TODO: Implement mcrcon commands.'
    # if isinstance(cmd, str):
    #     cmd_parts = cmd.strip().split()
    # else:
    #     cmd_parts = list(cmd)  # Allow already-split list input
    #
    # try:
    #     result = subprocess.run(
    #         [
    #             "mcrcon",
    #             "-H", "127.0.0.1",
    #             "-P", "25575",
    #             "-p", get_server_password(),
    #             "-r",
    #         ] + cmd_parts,
    #         capture_output=True,
    #         text=True,
    #         timeout=5,
    #         check=True
    #     )
    #     print(f"🛰️ RCON command: {' '.join(cmd_parts)}")
    #     print(f"🛰️ RCON pwd: {get_server_password()}")
    #     if result.stdout.strip():
    #         print(f"📥 stdout: {result.stdout.strip()}")
    #     if result.stderr.strip():
    #         print(f"⚠️ stderr: {result.stderr.strip()}")
    #     print(f"📄 Raw RCON output:\n{result.stdout}")
    #     return result.stdout.strip()
    # except subprocess.CalledProcessError as e:
    #     print(f"❌ RCON command failed (exit {e.returncode}): {e.stderr.strip()}")
    #     return None
    # except subprocess.TimeoutExpired:
    #     print("⏳ RCON command timed out")
    #     return None
    # except Exception as e:
    #     print(f"💥 RCON unexpected error: {type(e).__name__}: {e}")
    #     return None


@app.route("/")
def serve_admin():
    return send_from_directory(STATIC_DIR, "admin.html")


@app.route("/api/ping")
def ping():
    return "pong", 200


@app.route("/api/trigger-shutdown", methods=["POST"])
def trigger_shutdown():
    try:
        subprocess.Popen(["systemctl", "start", "vm-shutdown.service"])
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
            return Response(f"⏱ Refreshed: {now}\n\n{content}", mimetype="text/plain")
        except Exception as e:
            return Response(
                f"⏱ Refreshed: {now}\n\n⚠️ Dev status file error: {type(e).__name__}: {e}",
                mimetype="text/plain"
            )

    try:
        result = subprocess.run(
            ["systemctl", "is-active", "vrising.service"],
            capture_output=True, text=True
        )
        status = result.stdout.strip()

        readable_status = {
            "active": "🟢 V Rising is running",
            "inactive": "🔴 V Rising is stopped",
            "failed": "❌ V Rising failed",
            "activating": "⏳ V Rising is starting up",
            "deactivating": "⚠️ V Rising is shutting down",
            "unknown": "❓ V Rising status unknown",
        }.get(status, f"❓ Unexpected status: {status}")

        return Response(f"⏱ Refreshed: {now}\n\n{readable_status}", mimetype="text/plain")

    except Exception as e:
        return Response(
            f"⏱ Refreshed: {now}\n\n⚠️ {type(e).__name__}: {e}",
            mimetype="text/plain"
        )


@app.route("/api/logs/<name>")
def tail_log(name):
    log_map = {
        "VRisingServer.log": os.path.join(LOG_DIR, "VRisingServer.log"),
        "startup.log": os.path.join(LOG_DIR, "startup.log"),
        "shutdown.log": os.path.join(LOG_DIR, "shutdown.log"),
        "vrising.log": os.path.join(LOG_DIR, "vrising.log"),
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


@app.route("/api/settings")
def api_settings():
    import os
    import json

    base_path = "/home/bwinter_sc81/baroboys/VRising/VRisingServer_Data/StreamingAssets/Settings"

    game_settings_path = os.path.join(base_path, "ServerGameSettings.json")
    host_settings_path = os.path.join(base_path, "ServerHostSettings.json")

    try:
        with open(game_settings_path) as f:
            game_settings = json.load(f)
        with open(host_settings_path) as f:
            host_settings = json.load(f)

        return {
            "game_settings": game_settings,
            "host_settings": host_settings
        }
    except Exception as e:
        return {"error": f"Settings fetch failed: {type(e).__name__}: {e}"}, 500


@app.route("/api/status")
def api_status():
    try:
        return send_file("/tmp/status.json", mimetype="application/json")
    except Exception as e:
        return {"error": f"Status unavailable: {type(e).__name__}: {e}"}, 500


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
                ("/api/logs/vrising.log", "V Rising Service Logs", "GET"),
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
