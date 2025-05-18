#! /bin/bash

# Prep for team by filling in TOS
echo steam steam/question select "I AGREE" | debconf-set-selections
echo steam steam/license note "" | debconf-set-selections

curl "https://repo.steampowered.com/steam-archive-keyring.gpg" | tee "/usr/share/keyrings/steampowered.gpg"
echo "deb [arch=i386,amd64 signed-by=/usr/share/keyrings/steampowered.gpg] http://repo.steampowered.com/steam/ stable steam" \
  | tee "/etc/apt/sources.list.d/steampowered-repo.list"

apt-get install -yq steamcmd libicu67

source "/root/baroboys/scripts/setup/root/patch_steam.sh"