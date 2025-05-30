#!/bin/bash
set -eux

apt update
apt install -y nginx apache2-utils

gcloud secrets versions access latest --secret="nginx-htpasswd" --quiet > "/etc/nginx/.htpasswd"
chmod 644 "/etc/nginx/.htpasswd"


cp "/root/baroboys/scripts/setup/install/assets/nginx.config" "/etc/nginx/sites-available/vrising-admin"
ln -sf "/etc/nginx/sites-available/vrising-admin" "/etc/nginx/sites-enabled/vrising-admin"

systemctl reload nginx