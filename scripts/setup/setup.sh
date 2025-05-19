#!/bin/bash
set -eux

# Core install
source "/root/baroboys/scripts/setup/install/apt_core.sh"
source "/root/baroboys/scripts/setup/install/apt_gcloud.sh"
source "/root/baroboys/scripts/setup/install/apt_wine.sh"
source "/root/baroboys/scripts/setup/install/apt_xvfb.sh"
source "/root/baroboys/scripts/setup/install/apt_steam.sh"

# Clone repo for both users
source "/root/baroboys/scripts/setup/root/clone_repo.sh"

# Run game-specific setup
source "/root/baroboys/scripts/setup/root/setup_game.sh"

apt-get autoremove