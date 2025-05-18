#!/bin/bash
set -eux

# Start xvfb
source "/root/baroboys/scripts/setup/root/start_xvfb.sh"

# Run all game setup as the unprivileged user
sudo -u bwinter_sc81 -- "/home/bwinter_sc81/baroboys/scripts/setup/user/install_vrising.sh"

# Register and start the systemd service
install -m 644 "/root/baroboys/scripts/services/vrising.service" "/etc/systemd/system/"
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable vrising.service
systemctl start vrising.service
systemctl status vrising.service
