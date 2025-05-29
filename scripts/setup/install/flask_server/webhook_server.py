# webhook_server.py
import os
import subprocess
from datetime import datetime, timezone

from flask import Flask, render_template, send_from_directory, Response, request

STATIC_DIR = "/opt/baroboys/static"
TEMPLATE_DIR = "/opt/baroboys/templates"
LOG_DIR = "/home/bwinter_sc81/baroboys/VRising/logs"

app = Flask(__name__, template_folder=TEMPLATE_DIR)


@app.route("/")
def serve_admin():
    return send_from_directory(STATIC_DIR, "admin.html")


@app.route("/ping")
def ping():
    return "pong", 200


@app.errorhandler(404)
def not_found(e):
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    return render_template("404.html", path=request.path, timestamp=timestamp), 404


@app.route("/trigger-shutdown", methods=["POST"])
def trigger_shutdown():
    subprocess.Popen(["systemctl", "start", "shutdown.service"])
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    return f"<h2>🟠 Shutdown triggered at {now}</h2>"


@app.route("/check-status")
def check_status():
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

    try:
        output = subprocess.check_output(
            ["systemctl", "status", "vrising.service", "--no-pager"],
            stderr=subprocess.STDOUT,
            text=True
        )
    except subprocess.CalledProcessError as e:
        output = e.output or "⚠️ Failed to retrieve status."

    return render_template("status.html", timestamp=now, status=output)


@app.route("/logs/tail/<path:filename>")
def tail_log(filename):
    safe_name = filename.replace("/", "").replace("..", "")
    log_path = os.path.join(LOG_DIR, safe_name)

    if not os.path.isfile(log_path):
        return f"Log file not found: {safe_name}", 404

    try:
        with open(log_path, "r", encoding="utf-8", errors="ignore") as f:
            lines = f.readlines()
            tail = lines[-100:]
    except Exception as e:
        return f"Error reading log: {e}", 500

    return Response(
        "<pre style='color:#ccc; background:#111; padding:1em;'>"
        + "".join(tail) +
        "</pre>",
        mimetype="text/html"
    )


@app.route("/directory")
def directory():
    pages = [
        ("/", "Admin Panel"),
        ("/directory", "Site Directory"),
        ("/check-status", "Live Server Status"),
        ("/trigger-shutdown", "Trigger Graceful Shutdown (POST)"),
        ("/logs/tail/VRisingServer.log", "Tail VRisingServer.log"),
        ("/logs/tail/startup.log", "Tail startup.log"),
        ("/logs/tail/shutdown.log", "Tail shutdown.log"),
        ("/ping", "Health Check"),
    ]
    return render_template("directory.html", pages=pages)


@app.errorhandler(404)
def not_found(e):
    return render_template("404.html", path=request.path,
                           timestamp=datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")), 404


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
