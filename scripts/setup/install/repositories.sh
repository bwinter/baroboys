#!/bin/bash
set -eux

# Refresh repo, just in case.
source "/root/baroboys/scripts/setup/clone_repo.sh"

# Run user-specific setup
source "/root/baroboys/scripts/setup/root/setup_user.sh"
