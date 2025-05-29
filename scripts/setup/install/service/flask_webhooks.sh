#!/bin/bash
set -eux

# Install system Python and Flask via apt (safe under Debian 12 policy)
apt update
apt install -y python3-flask

# Systemd unit installation
cp "/root/baroboys/scripts/systemd/baroboys-webhook.service" \
   "/etc/systemd/system/baroboys-webhook.service"
chmod 644 "/etc/systemd/system/baroboys-webhook.service"

# Flask app source
mkdir -p "/opt/baroboys"
cp "/root/baroboys/scripts/setup/install/flask_server/webhook_server.py" \
   "/opt/baroboys/webhook_server.py"
chmod 755 "/opt/baroboys/webhook_server.py"

# Static HTML and assets
mkdir -p "/opt/baroboys/static"
cp "/root/baroboys/scripts/setup/install/flask_server/admin.html" \
   "/opt/baroboys/static/admin.html"
cp "/root/baroboys/scripts/setup/install/flask_server/favicon.ico" \
   "/opt/baroboys/static/favicon.ico"
echo -e "User-agent: *\nDisallow: /" > "/opt/baroboys/static/robots.txt"
chmod 644 /opt/baroboys/static/*

# Jinja templates
mkdir -p "/opt/baroboys/templates"
cp "/root/baroboys/scripts/setup/install/flask_server/templates/status.html" \
   "/opt/baroboys/templates/status.html"
cp "/root/baroboys/scripts/setup/install/flask_server/templates/404.html" \
   "/opt/baroboys/templates/404.html"
chmod 644 /opt/baroboys/templates/*.html

# Activate Flask service
systemctl daemon-reload
systemctl enable baroboys-webhook.service
systemctl start baroboys-webhook.service
