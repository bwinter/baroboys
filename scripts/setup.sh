#!/bin/bash
set -eux

source "/root/baroboys/scripts/setup/install/apt_core.sh"
source "/root/baroboys/scripts/setup/install/apt_gcloud.sh"
source "/root/baroboys/scripts/setup/install/apt_wine.sh"
source "/root/baroboys/scripts/setup/install/apt_xvfb.sh"
source "/root/baroboys/scripts/setup/install/apt_steam.sh"

source "/root/baroboys/scripts/setup/root/clone_repo.sh"

# TODO: make this configurable.
# source "/root/baroboys/scripts/setup/root/barotrauma.sh"
source "/root/baroboys/scripts/setup/root/vrising.sh"

apt-get autoremove