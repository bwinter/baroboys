#!/bin/bash
set -eux

apt update
apt install -y nginx apache2-utils

gcloud secrets versions access latest --secret=nginx-htpasswd \
  > "/etc/nginx/.htpasswd"
chmod 640 "/etc/nginx/.htpasswd"

chmod o+rx "/home/bwinter_sc81"
chmod o+rx "/home/bwinter_sc81/baroboys"
chmod o+rx "/home/bwinter_sc81/baroboys/VRising"
chmod o+rx "/home/bwinter_sc81/baroboys/VRising/logs"

cp "/root/baroboys/scripts/setup/install/assets/nginx.config" "/etc/nginx/sites-available/vrising-logs"
ln -s "/etc/nginx/sites-available/vrising-logs" "/etc/nginx/sites-enabled/vrising-logs"

systemctl reload nginx
