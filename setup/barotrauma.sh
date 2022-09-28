#! /bin/bash

su - bwinter_sc81 <<EOF
  /usr/games/steamcmd +force_install_dir '/home/bwinter_sc81/baroboys/Barotrauma' +login anonymous +app_update 1026340 validate +quit
EOF

git checkout -- 'Barotrauma/Data/clientpermissions.xml'

su bwinter_sc81 -c 'mkdir -p "home/bwinter_sc81/.local/share/Daedalic Entertainment GmbH/Barotrauma/"'

su bwinter_sc81 -c 'ln -s "home/bwinter_sc81/baroboys/Barotrauma/Multiplayer" "home/bwinter_sc81/.local/share/Daedalic Entertainment GmbH/Barotrauma/Multiplayer"'
su bwinter_sc81 -c 'ln -s "home/bwinter_sc81/baroboys/Barotrauma/WorkshopMods" "home/bwinter_sc81/.local/share/Daedalic Entertainment GmbH/Barotrauma/WorkshopMods"'

# echo screen -S baro-server -d -m "./barotrauma/DedicatedServer"

# apt-get install -yq

# apt-get install -yq build-essential \
#   wget apt-transport-https dirmngr \
#   apt-transport-https ca-certificates gnupg
