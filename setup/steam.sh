#! /bin/bash

# /usr/games/steamcmd +force_install_dir '/home/bwinter_sc81/.local/share/Daedalic Entertainment GmbH/Barotrauma' +login anonymous +app_update ${STEAMAPPID} validate +quit

# Prep for team by filling in TOS
echo steam steam/question select "I AGREE" | debconf-set-selections
echo steam steam/license note "" | debconf-set-selections

apt-get install -yq steamcmd libicu67

su bwinter_sc81 -c 'mkdir -p "/home/bwinter_sc81/.steam/sdk64"'
su bwinter_sc81 -c 'mkdir -p "/home/bwinter_sc81/.steam/sdk32"'
su bwinter_sc81 -c 'ln -s "/home/bwinter_sc81/.local/share/Steam/steamcmd/linux64/steamclient.so" "/home/bwinter_sc81/.steam/sdk64/steamclient.so"'
su bwinter_sc81 -c 'ln -s "/home/bwinter_sc81/.local/share/Steam/steamcmd/linux32/steamclient.so" "/home/bwinter_sc81/.steam/sdk32/steamclient.so"'

su bwinter_sc81 -c '/usr/games/steamcmd +runscript "/home/bwinter_sc81/.local/share/Daedalic\ Entertainment\ GmbH/setup/steamcmd_script.txt"'

# su bwinter_sc81 -c "mkdir -p '/home/bwinter_sc81/.local/share/Daedalic Entertainment GmbH/Barotrauma'"

# echo screen -S baro-server -d -m "./barotrauma/DedicatedServer"

# apt-get install -yq screen silversearcher-ag

# apt-get install -yq build-essential \
#   wget apt-transport-https dirmngr \
#   apt-transport-https ca-certificates gnupg



