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
mkdir -p /opt/baroboys/static
for file in admin.html favicon.ico robots.txt; do
  cp "/root/baroboys/scripts/setup/install/flask_server/static/${file}" \
     "/opt/baroboys/static/${file}"
done
chmod 644 /opt/baroboys/static/*

# Jinja templates
mkdir -p /opt/baroboys/templates
for file in 404.html directory.html; do
  cp "/root/baroboys/scripts/setup/install/flask_server/templates/${file}" \
     "/opt/baroboys/templates/${file}"
done
chmod 644 /opt/baroboys/templates/*.html

# Activate Flask service
systemctl daemon-reload
systemctl enable baroboys-webhook.service
systemctl start baroboys-webhook.service
