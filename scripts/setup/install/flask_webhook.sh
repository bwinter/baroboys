#!/bin/bash
set -eux

apt update
apt install -y python3-pip
pip3 install flask

cp "./scripts/setup/webhook_server.py" "/opt/baroboys/webhook_server.py"
cp "./scripts/systemd/baroboys-webhook.service" "/etc/systemd/system/"
chmod 755 "/opt/baroboys/webhook_server.py"
chmod 644 "/etc/systemd/system/"

systemctl daemon-reload
systemctl enable baroboys-webhook.service
systemctl start baroboys-webhook.service
