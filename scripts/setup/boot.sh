#!/bin/bash
set -eux

# Refresh repo, just in case.
source "/root/baroboys/scripts/setup/install/repositories.sh"

# Refresh services incase updates occurred.
source "/root/baroboys/scripts/setup/install/services.sh"

# Setup the game
source "/root/baroboys/scripts/setup/root/setup_game.sh"