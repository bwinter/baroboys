#!/bin/bash
set -eux

echo "🎮 Setting up game mode: ${ACTIVE_GAME:-undefined}"

# Load active game mode from repo-local env file
if [ -f "/root/baroboys/.envrc" ]; then
  source "/root/baroboys/.envrc"
fi

case "${ACTIVE_GAME:-}" in
  vrising)
    source "/root/baroboys/scripts/setup/root/setup_vrising.sh"
    ;;
  barotrauma)
    source "/root/baroboys/scripts/setup/root/setup_barotrauma.sh"
    ;;
  *)
    echo "ACTIVE_GAME not set or unrecognized: ${ACTIVE_GAME:-unset}" >&2
    exit 1
    ;;
esac

install -m 644 "/root/baroboys/scripts/systemd/idle-check.service" "/etc/systemd/system/"
install -m 644 "/root/baroboys/scripts/systemd/idle-check.timer" "/etc/systemd/system/"

touch "/var/log/baroboys/idle_check.log"
printf "\n==== %s ====\n" "$(date +%Y%m%d-%H%M)" >> "/var/log/baroboys/idle_check.log"
chown bwinter_sc81:bwinter_sc81  "/var/log/baroboys/idle_check.log"
chmod 644  "/var/log/baroboys/idle_check.log"

systemctl enable idle-check.timer
systemctl start idle-check.timer
