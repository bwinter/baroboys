#!/bin/bash
set -eux

# Refresh repos, just in case.
source "/root/baroboys/scripts/setup/clone_repo.sh"
source "/root/baroboys/scripts/setup/root/setup_user.sh"

# Refresh services in case updates occurred.
source "/root/baroboys/scripts/setup/install/services.sh"

# Setup the game
source "/root/baroboys/scripts/setup/root/setup_game.sh"