#!/bin/bash
set -eux

# Start xvfb
install -m 644 "/root/baroboys/scripts/systemd/xvfb.service" "/etc/systemd/system/"
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable xvfb.service
systemctl start xvfb.service
systemctl status xvfb.service

# mcrcon -H 127.0.0.1 -P 25575 -p adminpassword
# shutdown 1
apt-get install mcrcon

# Run all game setup as the unprivileged user
sudo -u bwinter_sc81 -- "/home/bwinter_sc81/baroboys/scripts/setup/user/install_vrising.sh"

# Register and start the systemd service
install -m 644 "/root/baroboys/scripts/systemd/vrising.service" "/etc/systemd/system/"
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable vrising.service
systemctl start vrising.service
systemctl status vrising.service
