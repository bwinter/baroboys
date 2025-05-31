#!/bin/bash
set -eux

mkdir -p "/home/bwinter_sc81/baroboys/VRising/logs/"
chown bwinter_sc81:bwinter_sc81  "/home/bwinter_sc81/baroboys/VRising/logs/"
chmod 700  "/home/bwinter_sc81/baroboys/VRising/logs/"

touch "/home/bwinter_sc81/baroboys/VRising/logs/shutdown.log"
printf "\n==== %s ====\n" "$(date +%Y%m%d-%H%M)" >> "/home/bwinter_sc81/baroboys/VRising/logs/shutdown.log"
chown bwinter_sc81:bwinter_sc81  "/home/bwinter_sc81/baroboys/VRising/logs/shutdown.log"
chmod 644  "/home/bwinter_sc81/baroboys/VRising/logs/shutdown.log"

cp "/root/baroboys/scripts/systemd/vm-shutdown.service" "/etc/systemd/system/vm-shutdown.service"
chmod 644 "/etc/systemd/system/vm-shutdown.service"

systemctl daemon-reexec
systemctl daemon-reload
