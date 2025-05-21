#!/bin/bash
set -eux

cp "$HOME/baroboys/scripts/setup/clone_repo.sh" "/tmp/clone_repo.sh"
chown bwinter_sc81:bwinter_sc81 "/tmp/clone_repo.sh"
chmod 700 "/tmp/clone_repo.sh"

sudo -u bwinter_sc81 -- "/tmp/clone_repo.sh"
sudo -u bwinter_sc81 -- "/home/bwinter_sc81/baroboys/scripts/setup/user/patch_steam.sh"
