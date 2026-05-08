import json
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
MANIFEST_PATH = os.path.join(THIS_DIR, "dev/manifest.json") if ENV == "dev" else "/etc/baroboys/manifest.json"

if ENV == "dev":
    print("🧪 Flask running in dev mode – using stubbed logs.")

app = Flask(__name__, template_folder=TEMPLATE_DIR)


def load_manifest():
    """Game manifest written by shared/refresh.sh on every game-refresh.

    Cross-language source of truth lives in terraform/game/<Game>.tfvars.json:
    Terraform reads it natively; refresh.sh projects it into this manifest for
    Python and JS consumers (game name, log set, accent, ports, RAM floor).

    Falls back to a minimal default if the file is missing or malformed —
    happens in dev mode without a stub, or briefly at first boot before
    game-refresh has run.
    """
    try:
        with open(MANIFEST_PATH, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError):
        return {
            "game_name": "Unknown",
            "process_name": "",
            "uses_wine": False,
            "log_files": ["game.log", "admin_server.log"],
        }


# nginx logs are subprocess-fetched (root-owned, sudo'd via tail). Not in the
# game manifest because they're infrastructure-shared across games.
def _nginx_log_sources():
    if ENV == "dev":
        return {
            "nginx_access": os.path.join(LOG_DIR, "nginx_access.log"),
            "nginx_error": os.path.join(LOG_DIR, "nginx_error.log"),
        }
    return {
        "nginx_access": ["tail", "-n", "500", "/var/log/nginx/access.log"],
        "nginx_error": ["tail", "-n", "500", "/var/log/nginx/error.log"],
    }


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


@app.route("/restart-game", methods=["POST"])
def restart_game():
    """Restart the game process without poweroff. Useful when the game
    crashes or hangs but the VM itself is fine — saves the cost of a
    full provision cycle."""
    try:
        now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

        if ENV == "dev":
            print("🔧 [Dev Mode] Mock game-restart triggered.")
            return {
                "status": "[Dev Mode] Game restart triggered",
                "time": now,
                "note": "This is mock data."
            }, 200

        subprocess.Popen(["sudo", "systemctl", "restart", "game-startup.service"])
        return {
            "status": "Game restart triggered",
            "time": now
        }, 200

    except Exception as e:
        return {
            "status": f"Game restart failed: {type(e).__name__}: {e}"
        }, 500


@app.route("/manifest")
def get_manifest():
    """Expose the game manifest so the admin panel JS can render
    game-aware UI (log dropdown, game name, etc.) without hardcoding."""
    return load_manifest(), 200


@app.route("/logs/<name>")
def tail_log(name):
    manifest = load_manifest()
    nginx_sources = _nginx_log_sources()

    if name in manifest["log_files"]:
        cmd = os.path.join(LOG_DIR, name)
    elif name in nginx_sources:
        cmd = nginx_sources[name]
    else:
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
    manifest = load_manifest()

    # Categorize manifest log_files. Anything that wasn't in the original
    # hardcoded "game" set ends up in "system" — works for current set
    # (game.log, idle_check.log are game; the rest are infra) and for
    # any new logs added to the manifest from a future game.
    game_log_names = {"game.log", "idle_check.log"}
    game_logs = []
    system_logs = []
    for f in manifest["log_files"]:
        display = f.replace(".log", "").replace("_", " ").title()
        link = (f"/api/logs/{f}", display, "GET")
        if f in game_log_names:
            game_logs.append(link)
        else:
            system_logs.append(link)

    sections = [
        {
            "icon": "🛠",
            "title": "Admin",
            "links": [
                ("/", "Admin Panel", "GET"),
                ("/directory", "Site Directory", "GET"),
                ("/api/ping", "Health Check", "GET"),
                ("/api/manifest", "Game Manifest (JSON)", "GET"),
            ]
        },
        {
            "icon": "🎮",
            "title": f"Game Control — {manifest['game_name']}",
            "links": [
                ("/status.json", "Structured Server Status", "GET"),
                ("/api/trigger-shutdown", "Trigger Graceful Shutdown", "POST"),
            ]
        },
        {
            "icon": "📄",
            "title": "Game Logs",
            "links": game_logs,
        },
        {
            "icon": "🌀",
            "title": "System Logs",
            "links": system_logs,
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
