#!/bin/bash
set -eux

# Start xvfb
install -m 644 "/root/baroboys/scripts/systemd/xvfb.service" "/etc/systemd/system/"

systemctl daemon-reexec
systemctl daemon-reload

systemctl enable xvfb.service
systemctl start xvfb.service
systemctl status xvfb.service
