#!/bin/bash
set -eux

apt update
apt install -y python3-pip
pip3 install flask

cp "/root/baroboys/scripts/setup/install/scripts/systemd/baroboys-webhook.service" "/etc/systemd/system/"
chmod 644 "/etc/systemd/system/baroboys-webhook.service"

cp "/root/baroboys/scripts/setup/install/flask_server/webhook_server.py" "/opt/baroboys/webhook_server.py"
chmod 755 "/opt/baroboys/webhook_server.py"

mkdir -p "/opt/baroboys/static"
cp "/root/baroboys/scripts/setup/install/flask_server/admin.html" "/opt/baroboys/static/admin.html"
chmod 644 "/opt/baroboys/static/admin.html"

mkdir -p "/opt/baroboys/templates"
cp "/root/baroboys/scripts/setup/install/flask_server/templates/status.html" "/opt/baroboys/templates/status.html"
chmod 644 "/opt/baroboys/templates/status.html"

systemctl daemon-reload
systemctl enable baroboys-webhook.service
systemctl start baroboys-webhook.service
