#!/bin/bash
set -eux

# Need Service Account: vm-runtime@europan-world.iam.gserviceaccount.com
# With Scopes: "Secret Manager Secret Accessor"
# Get Github Deploy Key
# Needs to be saved into secret manager by hand.

# SSH setup
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Inject deploy key directly from Secret Manager into proper file
gcloud secrets versions access latest --secret="github-deploy-key" --quiet > "$HOME/.ssh/id_ecdsa"
chmod 600 "$HOME/.ssh/id_ecdsa"

# Add GitHub host key
echo "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=" \
  | tee "$HOME/.ssh/known_hosts"

if [ -d "/$HOME/baroboys//.git" ]; then
  echo "🔄 Repo exists, pulling latest..."
  git -C "/$HOME/baroboys/" pull
else
  echo "📦 Repo missing, cloning fresh..."
  git clone "git@github.com:bwinter/baroboys.git" "/$HOME/baroboys/"
fi

[ -f "$HOME/.gitconfig" ] || cp "$HOME/baroboys/.gitconfig" "$HOME/.gitconfig"
