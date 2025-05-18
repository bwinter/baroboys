#! /bin/bash

set -x

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

### wine
curl "https://dl.winehq.org/wine-builds/winehq.key" | tee "/usr/share/keyrings/winehq.gpg"
echo "deb [signed-by=/usr/share/keyrings/winehq.gpg] https://dl.winehq.org/wine-builds/debian/ bookworm main" \
  | tee "/etc/apt/sources.list.d/winehq.list"

### gcloud
curl "https://packages.cloud.google.com/apt/doc/apt-key.gpg" | tee "/usr/share/keyrings/cloud.google.gpg"
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  | tee "/etc/apt/sources.list.d/google-cloud-sdk.list"

# Refresh state.
dpkg --add-architecture i386
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F24AEA9FB05498B7
apt-get remove -y --purge man-db
apt-get -yq update
apt-get -yq upgrade
apt-get install -yq git curl screen silversearcher-ag build-essential wget dirmngr apt-transport-https ca-certificates gnupg \
                    google-cloud-cli \
                    winehq-stable winetricks xvfb
apt-get autoremove

curl -sSO "https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh"
bash "add-google-cloud-ops-agent-repo.sh" --also-install

source "/root/baroboys/scripts/setup/git.sh"
source "/root/baroboys/scripts/setup/steam.sh"

# TODO: make this configurable.
# source "/root/baroboys/scripts/setup/barotrauma.sh"
source "/root/baroboys/scripts/setup/vrising.sh"