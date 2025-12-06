#!/bin/bash
set -eux

echo "Ensure Ningx service is setup."
source "/root/baroboys/scripts/dependencies/nginx/refresh.sh" || exit

# Install system Python and Flask via apt (safe under Debian 12 policy)
apt update
apt install -y python3-flask

# Flask app source
mkdir -p "/opt/baroboys"
cp "/root/baroboys/scripts/services/admin_server/src/admin_server.py" \
   "/opt/baroboys/admin_server.py"
chmod 755 "/opt/baroboys/admin_server.py"

# Static HTML and assets
mkdir -p "/opt/baroboys/static"
for file in admin.html favicon.ico robots.txt; do
  cp "/root/baroboys/scripts/services/admin_server/src/static/${file}" \
     "/opt/baroboys/static/${file}"
done
chmod 644 /opt/baroboys/static/*

# Jinja templates
mkdir -p "/opt/baroboys/templates"
for file in 404.html directory.html; do
  cp "/root/baroboys/scripts/services/admin_server/src/templates/${file}" \
     "/opt/baroboys/templates/${file}"
done
chmod 644 /opt/baroboys/templates/*.html

# Give Admin Server access to logs.
mkdir -p "/var/log/baroboys/"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/"
chmod 700  "/var/log/baroboys/"

touch "/var/log/baroboys/admin_server_startup.log"
printf "\n==== %s ====\n" "$(date +%Y%m%d-%H%M)" >> "/var/log/baroboys/admin_server_startup.log"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/admin_server_startup.log"
chmod 644  "/var/log/baroboys/admin_server_startup.log"

# Unit installation
install -m 644 "/root/baroboys/scripts/services/admin_server/admin-server-setup.service" \
  "/etc/systemd/system/"
install -m 644 "/root/baroboys/scripts/services/admin_server/admin-server-startup.service" \
  "/etc/systemd/system/"

systemctl daemon-reload
systemctl enable admin-server-setup.service
systemctl enable admin-server-startup.service