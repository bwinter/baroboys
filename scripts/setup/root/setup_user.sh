#!/bin/bash
set -eux

cp "$HOME/baroboys/scripts/setup/clone_repo.sh" "/tmp/clone_repo.sh"
chown bwinter_sc81:bwinter_sc81 "/tmp/clone_repo.sh"
chmod 700 "/tmp/clone_repo.sh"

sudo -u bwinter_sc81 -- "/tmp/clone_repo.sh"

echo "✅ Repo clone complete. Verifying script presence..."

ls -alh /home/bwinter_sc81/baroboys/scripts/setup/user

if [[ -f /home/bwinter_sc81/baroboys/scripts/setup/user/patch_steam.sh ]]; then
  echo "✅ Found patch_steam.sh. Running as bwinter_sc81..."
  sudo -u bwinter_sc81 -- /home/bwinter_sc81/baroboys/scripts/setup/user/patch_steam.sh
else
  echo "❌ ERROR: patch_steam.sh not found!"
  exit 1
fi

sudo -u bwinter_sc81 -- "/home/bwinter_sc81/baroboys/scripts/setup/user/patch_steam.sh"
