#!/usr/bin/env bash
set -euxo pipefail

echo "Ensuring Barotrauma is setup"
/usr/bin/sudo -u bwinter_sc81 -H -- "/home/bwinter_sc81/baroboys/scripts/services/barotrauma/src/refresh.sh"

# Give Admin Server access to logs.
mkdir -p "/var/log/baroboys/"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/"
chmod 700  "/var/log/baroboys/"

touch "/var/log/baroboys/barotrauma_startup.log"
printf "\n==== %s ====\n" "$(date +%Y/%m/%d-%H:%M:%S)" >> "/var/log/baroboys/barotrauma_startup.log"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/barotrauma_startup.log"
chmod 644  "/var/log/baroboys/barotrauma_startup.log"

touch "/var/log/baroboys/barotrauma_shutdown.log"
printf "\n==== %s ====\n" "$(date +%Y/%m/%d-%H:%M:%S)" >> "/var/log/baroboys/barotrauma_shutdown.log"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/barotrauma_shutdown.log"
chmod 644  "/var/log/baroboys/barotrauma_shutdown.log"

# Unit installation
install -m 644 "/root/baroboys/scripts/services/barotrauma/game-setup.service" \
  "/etc/systemd/system/"
install -m 644 "/root/baroboys/scripts/services/barotrauma/game-startup.service" \
  "/etc/systemd/system/"
install -m 644 "/root/baroboys/scripts/services/barotrauma/game-shutdown.service" \
  "/etc/systemd/system/"

# Unit installation
systemctl daemon-reload
systemctl enable game-setup.service
systemctl enable game-startup.service
systemctl enable game-shutdown.service