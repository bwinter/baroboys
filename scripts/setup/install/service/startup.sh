#!/bin/bash
set -eux

mkdir -p "/home/bwinter_sc81/baroboys/VRising/logs/"
chown bwinter_sc81:bwinter_sc81  "/home/bwinter_sc81/baroboys/VRising/logs/"
chmod 700  "/home/bwinter_sc81/baroboys/VRising/logs/"

touch  "/home/bwinter_sc81/baroboys/VRising/logs/startup.log"
printf "\n==== %s ====\n" "$(date +%Y%m%d-%H%M)" >> "/home/bwinter_sc81/baroboys/VRising/logs/startup.log"
chown bwinter_sc81:bwinter_sc81  "/home/bwinter_sc81/baroboys/VRising/logs/startup.log"
chmod 644  "/home/bwinter_sc81/baroboys/VRising/logs/startup.log"

cp "/root/baroboys/scripts/systemd/vm-startup.service" "/etc/systemd/system/vm-startup.service"
chmod 644 "/etc/systemd/system/vm-startup.service"

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable vm-startup.service
