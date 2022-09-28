#! /bin/bash

# Need Service Account: git-service-account@europan-world.iam.gserviceaccount.com
# With Scopes: Secret Manager Secret Accessor
# Get Github Deploy Key
# Needs to be saved into secret manager by hand.
gcloud secrets versions access latest --secret="github-deploy-key" | tee "/home/bwinter_sc81/.ssh/id_ecdsa"
chmod 700 "/home/bwinter_sc81/.ssh/id_ecdsa"

# This key is also necessary for github deploy keys.
echo "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=" | tee "/home/bwinter_sc81/.ssh/known_hosts"

git clone git@github.com:bwinter/baroboys.git "/home/bwinter_sc81/.local/share/Daedalic\ Entertainment\ GmbH"
