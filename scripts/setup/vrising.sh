#! /bin/bash

su - bwinter_sc81 <<EOF
  /usr/games/steamcmd +force_install_dir '/home/bwinter_sc81/baroboys/VRising' +login anonymous +app_update 1829350 validate +quit

  echo "" >> '/home/bwinter_sc81/.profile'
  echo "export EDITOR=vim" >> '/home/bwinter_sc81/.profile'
EOF
