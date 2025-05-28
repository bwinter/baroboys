#!/bin/bash
set -eux

cp "/root/baroboys/scripts/systemd/startup.service" "/etc/systemd/system/startup.service"
cp "/root/baroboys/scripts/systemd/shutdown.service" "/etc/systemd/system/shutdown.service"
chmod 644 "/etc/systemd/system/startup.service"
chmod 644 "/etc/systemd/system/shutdown.service"
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable startup.service