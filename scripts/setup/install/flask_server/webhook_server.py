from flask import Flask, render_template
import subprocess
from datetime import datetime

app = Flask(__name__)

@app.route("/trigger-shutdown", methods=["POST"])
def trigger_shutdown():
    subprocess.Popen(["systemctl", "start", "shutdown.service"])
    now = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
    return f"<h2>🟠 Shutdown triggered at {now}</h2>"

@app.route("/check-status", methods=["GET"])
def check_status():
    try:
        uptime = subprocess.check_output(["uptime", "-p"], text=True).strip()
        vrising_status = subprocess.check_output(
            ["systemctl", "status", "vrising.service"],
            text=True,
            stderr=subprocess.STDOUT
        )
        return render_template("status.html", uptime=uptime, service_output=vrising_status)

    except subprocess.CalledProcessError as e:
        return f"<h2 style='color:red;'>Error fetching status:</h2><pre>{e.output}</pre>", 500
