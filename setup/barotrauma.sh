#! /bin/bash

su - bwinter_sc81 <<EOF
  /usr/games/steamcmd +force_install_dir '/home/bwinter_sc81/baroboys/Barotrauma' +login anonymous +app_update 1026340 validate +quit

  cd /home/bwinter_sc81/baroboys
  git checkout -- './Barotrauma/Data/clientpermissions.xml'
  git checkout -- './Barotrauma/serversettings.xml'

  mkdir -p "/home/bwinter_sc81/.local/share/Daedalic Entertainment GmbH/Barotrauma/"

  ln -sf "/home/bwinter_sc81/baroboys/Barotrauma/Multiplayer" "/home/bwinter_sc81/.local/share/Daedalic Entertainment GmbH/Barotrauma/Multiplayer"
  ln -sf "/home/bwinter_sc81/baroboys/Barotrauma/WorkshopMods" "/home/bwinter_sc81/.local/share/Daedalic Entertainment GmbH/Barotrauma/WorkshopMods"

  screen -S baro-server -d -m "./barotrauma/DedicatedServer"
EOF
