#! /bin/bash
set -eux

# Add Steam key
curl "https://repo.steampowered.com/steam-archive-keyring.gpg" \
  | gpg --dearmor -o "/usr/share/keyrings/steampowered.gpg"

# Add the repo for Bookworm or Bullseye
echo "deb [arch=i386,amd64 signed-by=/usr/share/keyrings/steampowered.gpg] http://repo.steampowered.com/steam/ stable steam" \
  | tee "/etc/apt/sources.list.d/steampowered-repo.list"

# Prep for team by filling in TOS
echo steam steam/question select "I AGREE" | debconf-set-selections
echo steam steam/license note "" | debconf-set-selections

apt-get install -yq steamcmd libicu67