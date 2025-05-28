#!/bin/bash
set -eux

mkdir -p "/home/bwinter_sc81/baroboys/VRising/logs/"
touch "/home/bwinter_sc81/baroboys/VRising/logs/shutdown.log"
chown bwinter_sc81:bwinter_sc81  "/home/bwinter_sc81/baroboys/VRising/logs/shutdown.log"
chmod 644  "/home/bwinter_sc81/baroboys/VRising/logs/shutdown.log"

cp "/root/baroboys/scripts/systemd/shutdown.service" "/etc/systemd/system/shutdown.service"
chmod 644 "/etc/systemd/system/shutdown.service"
systemctl daemon-reexec
systemctl daemon-reload
