#!/bin/bash
set -eux

curl "https://dl.winehq.org/wine-builds/winehq.key" | tee "/usr/share/keyrings/winehq.gpg"
echo "deb [signed-by=/usr/share/keyrings/winehq.gpg] https://dl.winehq.org/wine-builds/debian/ bookworm main" \
  | tee "/etc/apt/sources.list.d/winehq.list"

apt-get -yq update
apt-get install -yq winehq-stable winetricks xvfb

winetricks allfonts