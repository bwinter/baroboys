#!/bin/bash
set -eux

# Refresh root
source "/root/baroboys/scripts/setup/util/refresh_repo.sh"

cp "/root/baroboys/scripts/setup/util/refresh_repo.sh" "/tmp/refresh_repo.sh"
chown bwinter_sc81:bwinter_sc81 "/tmp/refresh_repo.sh"
chmod 644  "/tmp/refresh_repo.sh"

# Now run it as the target user
sudo -u bwinter_sc81 -- "/tmp/refresh_repo.sh"

rm -f "/tmp/refresh_repo.sh"
