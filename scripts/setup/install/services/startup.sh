#!/bin/bash
set -eux

cp "/root/baroboys/scripts/systemd/startup.service" "/etc/systemd/system/startup.service"
chmod 644 "/etc/systemd/system/startup.service"
systemctl daemon-reexec
systemctl daemon-reload
