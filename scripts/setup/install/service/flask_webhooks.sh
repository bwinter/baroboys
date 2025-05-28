#!/bin/bash
set -eux

apt update
apt install -y python3-pip

# Only install Flask if missing
if ! python3 -c "import flask" &>/dev/null; then
  pip3 install flask
fi

# Install systemd unit
cp "/root/baroboys/scripts/setup/install/scripts/systemd/baroboys-webhook.service" "/etc/systemd/system/"
chmod 644 "/etc/systemd/system/baroboys-webhook.service"

# Install Flask app
cp "/root/baroboys/scripts/setup/install/flask_server/webhook_server.py" "/opt/baroboys/webhook_server.py"
chmod 755 "/opt/baroboys/webhook_server.py"

# Install static files
mkdir -p "/opt/baroboys/static"
cp "/root/baroboys/scripts/setup/install/flask_server/admin.html" "/opt/baroboys/static/admin.html"
chmod 644 "/opt/baroboys/static/admin.html"

# Install templates
mkdir -p "/opt/baroboys/templates"
cp "/root/baroboys/scripts/setup/install/flask_server/templates/status.html" "/opt/baroboys/templates/status.html"
chmod 644 "/opt/baroboys/templates/status.html"

# Reload and start the service
systemctl daemon-reload
systemctl enable baroboys-webhook.service
systemctl start baroboys-webhook.service
