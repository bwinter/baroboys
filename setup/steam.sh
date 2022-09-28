#! /bin/bash

# Prep for team by filling in TOS
echo steam steam/question select "I AGREE" | debconf-set-selections
echo steam steam/license note "" | debconf-set-selections

apt-get install -yq steamcmd libicu67

su bwinter_sc81 -c 'mkdir -p "/home/bwinter_sc81/.steam/sdk64"'
su bwinter_sc81 -c 'mkdir -p "/home/bwinter_sc81/.steam/sdk32"'
su bwinter_sc81 -c 'ln -s "/home/bwinter_sc81/.local/share/Steam/steamcmd/linux64/steamclient.so" "/home/bwinter_sc81/.steam/sdk64/steamclient.so"'
su bwinter_sc81 -c 'ln -s "/home/bwinter_sc81/.local/share/Steam/steamcmd/linux32/steamclient.so" "/home/bwinter_sc81/.steam/sdk32/steamclient.so"'
