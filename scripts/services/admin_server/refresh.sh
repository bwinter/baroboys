#!/usr/bin/env bash
set -euxo pipefail

# shellcheck source=scripts/services/shared/env-vars.sh
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../shared/env-vars.sh"

echo "Ensure Nginx service is refreshed."
# shellcheck source=scripts/dependencies/nginx/refresh.sh
# shellcheck disable=SC1091
source "$BAROBOYS/scripts/dependencies/nginx/refresh.sh" || exit

# Install system Python and Flask via apt (safe under Debian 12 policy)
apt update
apt install -y python3-flask

# Flask app source
mkdir -p "/opt/baroboys"
cp "$BAROBOYS/scripts/services/admin_server/src/admin_server.py" \
   "/opt/baroboys/admin_server.py"
chmod 644 "/opt/baroboys/admin_server.py"

# Static HTML and assets
mkdir -p "/opt/baroboys/static"
for file in 404.html admin.html favicon.ico robots.txt; do
  cp "$BAROBOYS/scripts/services/admin_server/src/static/${file}" \
     "/opt/baroboys/static/${file}"
done
chmod 644 /opt/baroboys/static/*

# Jinja templates
mkdir -p "/opt/baroboys/templates"
for file in "$BAROBOYS"/scripts/services/admin_server/src/templates/*.html; do
  cp "$file" "/opt/baroboys/templates/"
done
chmod 644 /opt/baroboys/templates/*.html

# Sudoers is installed at Packer build time (admin layer), not here.
# Add bwinter_sc81 to adm group so Flask can read nginx logs
usermod -aG adm bwinter_sc81

# Ensure log file exists (log directory created by infrastructure-refresh)
touch "/var/log/baroboys/admin_server.log"
printf "\n==== %s ====\n" "$(date +%Y/%m/%d-%H:%M:%S)" >> "/var/log/baroboys/admin_server.log"

# Unit installation
install -m 644 "$BAROBOYS/scripts/services/admin_server/admin-server-refresh.service" \
  "/etc/systemd/system/"
install -m 644 "$BAROBOYS/scripts/services/admin_server/admin-server-startup.service" \
  "/etc/systemd/system/"

systemctl daemon-reload
systemctl enable admin-server-refresh.service
systemctl enable admin-server-startup.service