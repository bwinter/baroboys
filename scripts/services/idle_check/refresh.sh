#!/usr/bin/env bash
set -euxo pipefail

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Boot marker. Print to stdout — systemd's StandardOutput=append: redirects
# this to /var/log/baroboys/idle_check.log via an FD opened (as root) at
# unit-start. The script can't reopen that file directly because it runs
# as bwinter_sc81 and the file was created root:root 0644. Writes through
# systemd's existing FD don't recheck perms; an explicit `touch` or `>>`
# from the script does.
printf "\n==== %s ====\n" "$(date +%Y/%m/%d-%H:%M:%S)"

sudo install -m 644 "$SCRIPT_DIR/idle-check-refresh.service" "/etc/systemd/system/"
sudo install -m 644 "$SCRIPT_DIR/idle-check.service" "/etc/systemd/system/"
sudo install -m 644 "$SCRIPT_DIR/idle-check.timer" "/etc/systemd/system/"

sudo systemctl daemon-reload
sudo systemctl enable idle-check-refresh.service
sudo systemctl enable idle-check.service
sudo systemctl enable idle-check.timer
