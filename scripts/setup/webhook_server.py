from flask import Flask
import subprocess
from datetime import datetime

app = Flask(__name__)

@app.route("/trigger-shutdown", methods=["POST"])
def trigger_shutdown():
    subprocess.Popen(["systemctl", "start", "shutdown.service"])
    now = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
    return f"<h2>🟠 Shutdown triggered at {now}</h2>"
