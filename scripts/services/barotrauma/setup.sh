#!/bin/bash
set -eux

# Run all game setup as the unprivileged user
/usr/bin/sudo -u bwinter_sc81 -- "/home/bwinter_sc81/baroboys/scripts/services/barotrauma/install.sh"
