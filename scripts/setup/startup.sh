#!/bin/bash
set -eux

echo "Starting setup_users.sh"
source "/root/baroboys/scripts/setup/root/setup_users.sh" || exit 11

echo "Starting apt_nginx.sh"
source "/root/baroboys/scripts/setup/install/apt_nginx.sh" || exit 12

echo "Starting admin_server.sh"
source "/root/baroboys/scripts/setup/install/service/admin_server.sh" || exit 13

echo "Starting shutdown.sh"
source "/root/baroboys/scripts/setup/install/service/shutdown.sh" || exit 14

echo "Starting startup.sh (self)"
source "/root/baroboys/scripts/setup/install/service/startup.sh" || exit 15

echo "Starting setup_game.sh"
source "/root/baroboys/scripts/setup/root/setup_game.sh" || exit 16
