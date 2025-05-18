#!/bin/bash
set -eux

/usr/games/steamcmd +force_install_dir "$HOME/baroboys/VRising" \
  +login anonymous +app_update 1829350 validate +quit

# TODO: Restore save game
# git checkout ...

# Ensure EDITOR is set for future shell sessions
grep -qxF 'export EDITOR=vim' "$HOME/.profile" || echo 'export EDITOR=vim' >> "$HOME/.profile"
