#!/bin/bash
set -eux

cp "/root/baroboys/scripts/systemd/setup_game.service" "/etc/systemd/system/setup_game.service"
cp "/root/baroboys/scripts/systemd/teardown.service" "/etc/systemd/system/teardown.service"
chmod 644 "/etc/systemd/system/setup_game.service"
chmod 644 "/etc/systemd/system/teardown.service"
systemctl daemon-reexec
systemctl daemon-reload