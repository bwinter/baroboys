#!/bin/bash
set -eux

/usr/games/steamcmd +force_install_dir "$HOME/baroboys/Barotrauma" \
  +login anonymous +app_update 1026340 validate +quit

cd "$HOME/baroboys"
git checkout -- './Barotrauma/Data/clientpermissions.xml'
git checkout -- './Barotrauma/serversettings.xml'

mkdir -p "$HOME/.local/share/Daedalic Entertainment GmbH/Barotrauma/"
ln -sf "$HOME/baroboys/Barotrauma/Multiplayer" "$HOME/.local/share/Daedalic Entertainment GmbH/Barotrauma/Multiplayer"
ln -sf "$HOME/baroboys/Barotrauma/WorkshopMods" "$HOME/.local/share/Daedalic Entertainment GmbH/Barotrauma/WorkshopMods"

# Ensure EDITOR is set for future shell sessions
grep -qxF 'export EDITOR=vim' "$HOME/.profile" || echo 'export EDITOR=vim' >> "$HOME/.profile"