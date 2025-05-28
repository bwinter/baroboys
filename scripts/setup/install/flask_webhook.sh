#!/bin/bash
set -eux

apt update
apt install -y python3-pip
pip3 install flask

cp "/root/baroboys/scripts/setup/install/scripts/setup/webhook_server.py" "/opt/baroboys/webhook_server.py"
cp "/root/baroboys/scripts/setup/install/scripts/systemd/baroboys-webhook.service" "/etc/systemd/system/"
chmod 755 "/opt/baroboys/webhook_server.py"
chmod 644 "/etc/systemd/system/baroboys-webhook.service"

mkdir -p "/opt/baroboys/static"
cp "/root/baroboys/scripts/setup/install/assets/admin.html" "/opt/baroboys/static/admin.html"
chmod 644 "/opt/baroboys/static/admin.html"

systemctl daemon-reload
systemctl enable baroboys-webhook.service
systemctl start baroboys-webhook.service
