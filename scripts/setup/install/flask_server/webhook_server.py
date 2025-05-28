import subprocess
from datetime import datetime, timezone, UTC

from flask import Flask, render_template

app = Flask(__name__, template_folder="/opt/baroboys/templates")


@app.route("/")
def serve_admin():
    return send_from_directory(STATIC_DIR, "admin.html")


@app.route("/ping")
def ping():
    return "pong", 200


@app.route("/trigger-shutdown", methods=["POST"])
def trigger_shutdown():
    subprocess.Popen(["systemctl", "start", "shutdown.service"])
    now = datetime.now(UTC).strftime("%Y-%m-%d %H:%M:%S UTC")
    return f"<h2>🟠 Shutdown triggered at {now}</h2>"


@app.route("/check-status")
def check_status():
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

    try:
        status_output = subprocess.check_output(
            ["systemctl", "status", "vrising.service", "--no-pager"],
            stderr=subprocess.STDOUT,
            text=True,
        )
    except subprocess.CalledProcessError as e:
        status_output = e.output or "Failed to retrieve status."

    return render_template("status.html", timestamp=now, status=status_output)


@app.route("/logs/tail/<path:filename>")
def tail_log(filename):
    safe_path = filename.replace("/", "").replace("..", "")
    log_path = f"/home/bwinter_sc81/baroboys/VRising/logs/{safe_path}"

    if not os.path.isfile(log_path):
        return f"Log file not found: {safe_path}", 404

    try:
        with open(log_path, "r", encoding="utf-8", errors="ignore") as f:
            lines = f.readlines()
            last_lines = lines[-100:]  # Adjust N here
    except Exception as e:
        return f"Error reading log: {e}", 500

    return Response("<pre style='color:#ccc; background:#111; padding:1em;'>" +
                    "".join(last_lines) +
                    "</pre>", mimetype="text/html")
