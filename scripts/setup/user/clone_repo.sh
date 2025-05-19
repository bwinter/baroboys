#!/bin/bash
set -eux

# Need Service Account: git-service-account@europan-world.iam.gserviceaccount.com
# With Scopes: "Secret Manager Secret Accessor"
# Get Github Deploy Key
# Needs to be saved into secret manager by hand.

# SSH setup
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Inject deploy key
mv "/tmp/id_ecdsa" "$HOME/.ssh/"
install -m 600 -o bwinter_sc81 -g bwinter_sc81 "/tmp/id_ecdsa" "$HOME/.ssh/id_ecdsa"

# Add known_hosts
echo "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=" \
  > "$HOME/.ssh/known_hosts"
chown bwinter_sc81:bwinter_sc81 "$HOME/.ssh/known_hosts"

[ -d "/$HOME/baroboys/.git" ] || git clone "git@github.com:bwinter/baroboys.git" "$HOME/baroboys"

[ -f "$HOME/.gitconfig" ] || cp "$HOME/baroboys/.gitconfig" "$HOME/.gitconfig"
