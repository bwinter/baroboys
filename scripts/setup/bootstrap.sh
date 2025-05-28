#!/bin/bash
set -eux

# Core install
source "/root/baroboys/scripts/setup/install/apt_core.sh"
source "/root/baroboys/scripts/setup/install/apt_gcloud.sh"
source "/root/baroboys/scripts/setup/install/apt_steam.sh"
source "/root/baroboys/scripts/setup/install/apt_wine.sh"
source "/root/baroboys/scripts/setup/install/apt_nginx.sh"

# Refresh repo, just in case.
source "/root/baroboys/scripts/setup/install/repositories.sh"

source "/root/baroboys/scripts/setup/install/services.sh"

apt-get -yq autoremove