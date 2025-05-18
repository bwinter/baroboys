#!/bin/bash
set -eux

curl "https://packages.cloud.google.com/apt/doc/apt-key.gpg" | tee "/usr/share/keyrings/cloud.google.gpg"
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  | tee "/etc/apt/sources.list.d/google-cloud-sdk.list"

apt-get install -yq google-cloud-cli

curl -sSO "https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh"
bash "add-google-cloud-ops-agent-repo.sh" --also-install