#!/bin/bash
set -eux

echo "Starting setup_users.sh"
source "/root/baroboys/scripts/utils/setup_users.sh" || exit 11

echo "Initialize Ningx"
source "/root/baroboys/scripts/services/nginx/setup.sh" || exit 12

echo "Initialize Admin Server Service"
source "/root/baroboys/scripts/services/admin_server/setup.sh" || exit 13

echo "Starting shutdown.sh"
source "/root/baroboys/scripts/services/vm-shutdown/setup.sh" || exit 14

echo "Starting startup.sh (self)"
source "/root/baroboys/scripts/services/vm-startup/setup.sh" || exit 15

echo "Starting setup_game.sh"
source "/root/baroboys/scripts/services/vm-startup/setup_game.sh" || exit 16
