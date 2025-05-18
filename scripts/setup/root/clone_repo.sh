#! /bin/bash
set -eux

# Pull deploy key from GCP secret manager
gcloud secrets versions access latest --secret="github-deploy-key" | tee "/tmp/id_ecdsa"
chown bwinter_sc81:bwinter_sc81 "/tmp/id_ecdsa"
chmod 600 "/tmp/id_ecdsa"

# Need Service Account: git-service-account@europan-world.iam.gserviceaccount.com
# With Scopes: "Secret Manager Secret Accessor"
# Get Github Deploy Key
# Needs to be saved into secret manager by hand.

# Root SSH setup
mkdir -p "/root/.ssh"
chmod 700 "/root/.ssh"

cat "/tmp/id_ecdsa" > "/root/.ssh/id_ecdsa"
chmod 600 '/root/.ssh/id_ecdsa'

# Add GitHub host key
echo "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=" | tee "/root/.ssh/known_hosts"

[ -d "/root/baroboys/.git" ] || git clone "git@github.com:bwinter/baroboys.git" "/root/baroboys"

sudo -u bwinter_sc81 -- "/home/bwinter_sc81/baroboys/scripts/setup/root/clone_repo.sh"