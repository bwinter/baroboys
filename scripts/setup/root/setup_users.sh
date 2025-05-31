#!/bin/bash
set -eux

# Refresh root
source "/root/baroboys/scripts/setup/util/refresh_repo.sh"
sudo -u bwinter_sc81 -- "/usr/bin/sudo /root/baroboys/scripts/setup/util/refresh_repo.sh"
