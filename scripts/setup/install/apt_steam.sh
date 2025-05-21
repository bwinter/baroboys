#! /bin/bash
set -eux

# Add key
curl -fsSL "https://repo.steampowered.com/steam-archive-keyring.gpg" \
  | gpg --dearmor | tee "/usr/share/keyrings/steam.gpg" > /dev/null

# Add repo using the keyring
echo "deb [signed-by=/usr/share/keyrings/steam.gpg] https://repo.steampowered.com/steam/ stable steam" \
  | tee "/etc/apt/sources.list.d/steam.list"

# Prep for team by filling in TOS
echo steam steam/question select "I AGREE" | debconf-set-selections
echo steam steam/license note "" | debconf-set-selections

apt-get install -yq steamcmd libicu67