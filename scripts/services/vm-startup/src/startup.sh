#!/bin/bash
set -eux

echo "Pulling repo for both users."
source "/root/baroboys/scripts/utils/setup_users.sh" || exit 11

echo "Ensure Ningx service is setup."
source "/root/baroboys/scripts/services/nginx/setup.sh" || exit 12

echo "Ensure Admin Server is setup."
source "/root/baroboys/scripts/services/admin_server/setup.sh" || exit 13

echo "Ensure shutdown service is setup."
source "/root/baroboys/scripts/services/vm-shutdown/setup.sh" || exit 14

echo "Ensures startup service (self) is setup."
source "/root/baroboys/scripts/services/vm-startup/setup.sh" || exit 15

echo "Ensures game is setup."
source "/root/baroboys/scripts/services/vm-startup/src/setup_game.sh" || exit 16
