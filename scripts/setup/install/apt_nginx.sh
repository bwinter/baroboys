#!/bin/bash
set -eux

apt update
apt install -y nginx apache2-utils

gcloud secrets versions access latest --secret=nginx-htpasswd \
  > "/etc/nginx/.htpasswd"
chown root:root "/etc/nginx/.htpasswd"
chmod 640 "/etc/nginx/.htpasswd"

chmod o+rx "/home/bwinter_sc81"
chmod o+rx "/home/bwinter_sc81/baroboys"
chmod o+rx "/home/bwinter_sc81/baroboys/VRising"
chmod o+rx "/home/bwinter_sc81/baroboys/VRising/logs"

touch "/home/bwinter_sc81/baroboys/VRising/logs/VRisingServer.log"
touch "/home/bwinter_sc81/baroboys/VRising/logs/startup.log"
touch "/home/bwinter_sc81/baroboys/VRising/logs/shutdown.log"

chmod o+r "/home/bwinter_sc81/baroboys/VRising/logs/*.log"

cp "./assets/nginx.config" "/etc/nginx/sites-available/vrising-logs"
ln -s "/etc/nginx/sites-available/vrising-logs" "/etc/nginx/sites-enabled/vrising-logs"

systemctl reload nginx
