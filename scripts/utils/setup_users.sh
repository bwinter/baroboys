#!/bin/bash
set -eux

SCRIPT_DIR="/root/baroboys/scripts"

# Refresh root
source "$SCRIPT_DIR/utils/refresh_repo.sh"

cp "$SCRIPT_DIR/utils/refresh_repo.sh" "/tmp/refresh_repo.sh"
chown bwinter_sc81:bwinter_sc81 "/tmp/refresh_repo.sh"
chmod 755  "/tmp/refresh_repo.sh"

# Now run it as the target user
sudo -u bwinter_sc81 -- "/tmp/refresh_repo.sh"

rm -f "/tmp/refresh_repo.sh"
