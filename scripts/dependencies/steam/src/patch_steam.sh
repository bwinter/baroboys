#!/usr/bin/env bash
set -euxo pipefail

mkdir -p "$HOME/.steam/sdk64"
mkdir -p "$HOME/.steam/sdk32"
ln -sf "$HOME/.local/share/Steam/steamcmd/linux64/steamclient.so" "$HOME/.steam/sdk64/steamclient.so"
ln -sf "$HOME/.local/share/Steam/steamcmd/linux32/steamclient.so" "$HOME/.steam/sdk32/steamclient.so"
