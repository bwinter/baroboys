#!/bin/bash
set -eux

# Git is a dependency that needs immediate install.
echo "
#------------------------------------------------------------------------------#
#                   OFFICIAL DEBIAN REPOS
#------------------------------------------------------------------------------#

###### Debian Main Repos
deb http://deb.debian.org/debian/ bullseye main contrib non-free
deb-src http://deb.debian.org/debian/ bullseye main contrib non-free

deb http://deb.debian.org/debian/ bullseye-updates main contrib non-free
deb-src http://deb.debian.org/debian/ bullseye-updates main contrib non-free

deb http://deb.debian.org/debian-security bullseye-security main
deb-src http://deb.debian.org/debian-security bullseye-security main

deb http://deb.debian.org/debian bullseye-backports main
deb-src http://deb.debian.org/debian bullseye-backports main
" | tee "/etc/apt/sources.list"

# Refresh state.
dpkg --add-architecture i386
apt-get -yq update
apt-get install -yq debian-archive-keyring
apt-get remove -y --purge man-db
apt-get -yq update
apt-get -yq upgrade
apt-get install -yq git

# Root SSH setup
mkdir -p "/root/.ssh"
chmod 700 "/root/.ssh"

# Need Service Account: vm-runtime@europan-world.iam.gserviceaccount.com
# With Scopes: "Secret Manager Secret Accessor"
# Get Github Deploy Key
# Needs to be saved into secret manager by hand.

# Pull deploy key from GCP secret manager
gcloud secrets versions access latest --secret="github-deploy-key" --quiet > "/root/.ssh/id_ecdsa"
chmod 600 '/root/.ssh/id_ecdsa'

# Add GitHub host key
echo "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=" | tee "/root/.ssh/known_hosts"

[ -d "/root/baroboys/.git" ] || git clone "git@github.com:bwinter/baroboys.git" "/root/baroboys"

sudo -u bwinter_sc81 -- "/home/bwinter_sc81/baroboys/scripts/setup/root/clone_repo.sh"

# Core install
source "/root/baroboys/scripts/setup/install/apt_core.sh"
source "/root/baroboys/scripts/setup/install/apt_gcloud.sh"
source "/root/baroboys/scripts/setup/install/apt_wine.sh"
source "/root/baroboys/scripts/setup/install/apt_xvfb.sh"
source "/root/baroboys/scripts/setup/install/apt_steam.sh"

# Run game-specific setup
echo "🎮 Setting up game mode: ${ACTIVE_GAME:-undefined}"
source "/root/baroboys/scripts/setup/root/setup_game.sh"

apt-get autoremove