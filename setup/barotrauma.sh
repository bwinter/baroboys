#! /bin/bash

su - bwinter_sc81 <<EOF
  /usr/games/steamcmd +force_install_dir '/home/bwinter_sc81/baroboys/Barotrauma' +login anonymous +app_update 1026340 validate +quit
EOF

# shellcheck disable=SC2016 (I want the HOME of the sub-shell.)
su bwinter_sc81 -c 'mkdir -p "${HOME}/.local/share/Daedalic Entertainment GmbH/Barotrauma/"'

su bwinter_sc81 -c 'ln -s "${HOME}/baroboys/Barotrauma/Multiplayer" "${HOME}/.local/share/Daedalic Entertainment GmbH/Barotrauma/Multiplayer"'
su bwinter_sc81 -c 'ln -s "${HOME}/baroboys/Barotrauma/WorkshopMods" "${HOME}/.local/share/Daedalic Entertainment GmbH/Barotrauma/WorkshopMods"'

# echo screen -S baro-server -d -m "./barotrauma/DedicatedServer"

# apt-get install -yq screen silversearcher-ag

# apt-get install -yq build-essential \
#   wget apt-transport-https dirmngr \
#   apt-transport-https ca-certificates gnupg
