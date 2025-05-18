#!/bin/bash
set -eux

# Run all game setup as the unprivileged user
sudo -u bwinter_sc81 -- "/home/bwinter_sc81/baroboys/scripts/setup/user/install_barotrauma.sh"
