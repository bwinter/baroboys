#!/bin/bash
set -eux

cp "/root/baroboys/scripts/systemd/boot.service" "/etc/systemd/system/boot.service"
cp "/root/baroboys/scripts/systemd/shutdown.service" "/etc/systemd/system/shutdown.service"
chmod 644 "/etc/systemd/system/boot.service"
chmod 644 "/etc/systemd/system/shutdown.service"
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable boot.service
systemctl enable shutdown.service