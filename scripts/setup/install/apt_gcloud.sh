#!/bin/bash
set -eux

# Install the Google Cloud SDK APT key
curl -fsSL "https://packages.cloud.google.com/apt/doc/apt-key.gpg" \
  | gpg --dearmor -o "/usr/share/keyrings/cloud.google.gpg"

# Add the repo for Bookworm or Bullseye
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  | tee "/etc/apt/sources.list.d/google-cloud-sdk.list"

apt-get install -yq google-cloud-cli

curl -sSO "https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh"
bash "add-google-cloud-ops-agent-repo.sh" --also-install


# Add the signed repo using the keyring file

