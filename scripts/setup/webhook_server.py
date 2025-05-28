from flask import Flask, request
import subprocess
from datetime import datetime

app = Flask(__name__)

@app.route("/")
def home():
    return """
    <html>
    <head><title>Baroboys Admin</title></head>
    <body>
        <h1>Admin Panel</h1>
        <form action="/trigger-save" method="post">
          <button type="submit">💾 Trigger Save</button>
        </form>
        <form action="/trigger-shutdown" method="post" onsubmit="return confirm('Really shut down the server?');">
          <button type="submit">🛑 Shutdown Server</button>
        </form>
    </body>
    </html>
    """

@app.route("/trigger-save", methods=["POST"])
def trigger_save():
    subprocess.Popen(["/root/baroboys/scripts/teardown/user/save_game.sh"])
    now = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
    return f"<h2>\u2705 Save triggered at {now}</h2>"

@app.route("/trigger-shutdown", methods=["POST"])
def trigger_shutdown():
    subprocess.Popen(["systemctl", "start", "shutdown.service"])
    now = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
    return f"<h2>\ud83d\udea9 Shutdown triggered at {now}</h2>"
