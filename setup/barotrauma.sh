#! /bin/bash

su - bwinter_sc81 <<EOF
  /usr/games/steamcmd +force_install_dir '/home/bwinter_sc81/baroboys/Barotrauma' +login anonymous +app_update 1026340 validate +quit

  # https://steamcommunity.com/sharedfiles/filedetails/?id=2559634234
  # wget https://github.com/evilfactory/LuaCsForBarotrauma/releases/download/latest/luacsforbarotrauma_build_linux.tar.gz -o /temp/luacsforbarotrauma_build_linux.tar.gz

  cd /home/bwinter_sc81/baroboys
  git checkout -- './Barotrauma/Data/clientpermissions.xml'
  git checkout -- './Barotrauma/serversettings.xml'

  mkdir -p "/home/bwinter_sc81/.local/share/Daedalic Entertainment GmbH/Barotrauma/"

  ln -sf "/home/bwinter_sc81/baroboys/Barotrauma/Multiplayer" "/home/bwinter_sc81/.local/share/Daedalic Entertainment GmbH/Barotrauma/Multiplayer"
  ln -sf "/home/bwinter_sc81/baroboys/Barotrauma/WorkshopMods" "/home/bwinter_sc81/.local/share/Daedalic Entertainment GmbH/Barotrauma/WorkshopMods"

  echo "" >> '/home/bwinter_sc81/.profile'
  echo "export EDITOR=vim" >> '/home/bwinter_sc81/.profile'
EOF
