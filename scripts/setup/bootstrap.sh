#!/bin/bash
set -eux

# Core install
source "/root/baroboys/scripts/setup/install/apt_core.sh"
source "/root/baroboys/scripts/setup/install/apt_gcloud.sh"
source "/root/baroboys/scripts/setup/install/apt_steam.sh"
source "/root/baroboys/scripts/setup/install/apt_wine.sh"

# Refresh repo, just in case.
source "/root/baroboys/scripts/setup/clone_repo.sh"

# Run user-specific setup
source "/root/baroboys/scripts/setup/root/setup_user.sh"

apt-get autoremove