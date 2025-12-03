#!/bin/bash
set -eux

install -m 644 "/root/baroboys/scripts/systemd/idle-check.service" "/etc/systemd/system/"
install -m 644 "/root/baroboys/scripts/systemd/idle-check.timer" "/etc/systemd/system/"

touch "/var/log/baroboys/idle_check.log"
printf "\n==== %s ====\n" "$(date +%Y%m%d-%H%M)" >> "/var/log/baroboys/idle_check.log"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/idle_check.log"
chmod 644  "/var/log/baroboys/idle_check.log"

systemctl enable idle-check.timer
systemctl start idle-check.timer
