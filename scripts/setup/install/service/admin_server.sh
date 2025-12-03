#!/bin/bash
set -eux

# Install system Python and Flask via apt (safe under Debian 12 policy)
apt update
apt install -y python3-flask

# Systemd unit installation
cp "/root/baroboys/scripts/systemd/admin-server.service" \
   "/etc/systemd/system/admin-server.service"
chmod 644 "/etc/systemd/system/admin-server.service"

# Flask app source
mkdir -p "/opt/baroboys"
cp "/root/baroboys/admin/admin_server.py" \
   "/opt/baroboys/admin_server.py"
chmod 755 "/opt/baroboys/admin_server.py"

# Static HTML and assets
mkdir -p "/opt/baroboys/static"
for file in admin.html favicon.ico robots.txt; do
  cp "/root/baroboys/admin/static/${file}" \
     "/opt/baroboys/static/${file}"
done
chmod 644 /opt/baroboys/static/*

# Jinja templates
mkdir -p "/opt/baroboys/templates"
for file in 404.html directory.html; do
  cp "/root/baroboys/admin/templates/${file}" \
     "/opt/baroboys/templates/${file}"
done
chmod 644 /opt/baroboys/templates/*.html

mkdir -p "/var/log/baroboys/"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/"
chmod 700  "/var/log/baroboys/"

touch "/var/log/baroboys/admin_server.log"
printf "\n==== %s ====\n" "$(date +%Y%m%d-%H%M)" >> "/var/log/baroboys/admin_server.log"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/admin_server.log"
chmod 644  "/var/log/baroboys/admin_server.log"

# Activate Admin Server
systemctl daemon-reload
systemctl enable admin-server.service
systemctl restart admin-server.service