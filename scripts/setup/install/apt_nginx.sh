#!/bin/bash
set -eux

apt update
apt install -y nginx apache2-utils

# Fetch .htpasswd from gcloud secrets
gcloud secrets versions access latest --secret="nginx-htpasswd" --quiet > "/etc/nginx/.htpasswd"
chmod 644 "/etc/nginx/.htpasswd"
chown root:root "/etc/nginx/.htpasswd"

# Replace entire nginx.conf
cp "/root/baroboys/scripts/setup/install/assets/nginx.conf" "/etc/nginx/nginx.conf"
chown root:root "/etc/nginx/nginx.conf"
chmod 644 "/etc/nginx/nginx.conf"

# Ensure logging directories exist
mkdir -p /var/log/nginx /var/run
chown -R www-data:www-data /var/log/nginx /var/run
chmod 755 /var/log/nginx /var/run

# Reload Nginx
systemctl restart nginx
