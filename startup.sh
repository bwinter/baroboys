#! /bin/bash

set -x

echo "
#------------------------------------------------------------------------------#
#                   OFFICIAL DEBIAN REPOS
#------------------------------------------------------------------------------#

###### Debian Main Repos
deb http://deb.debian.org/debian/ bullseye main contrib non-free
deb-src http://deb.debian.org/debian/ bullseye main contrib non-free

deb http://deb.debian.org/debian/ bullseye-updates main contrib non-free
deb-src http://deb.debian.org/debian/ bullseye-updates main contrib non-free

deb http://deb.debian.org/debian-security bullseye-security main
deb-src http://deb.debian.org/debian-security bullseye-security main

deb http://deb.debian.org/debian bullseye-backports main
deb-src http://deb.debian.org/debian bullseye-backports main
" | tee "/etc/apt/sources.list"

### gcloud
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee "/etc/apt/sources.list.d/google-cloud-sdk.list"
### steam
echo "deb [arch=i386,amd64] http://repo.steampowered.com/steam/ precise steam" | tee "/etc/apt/sources.list.d/steampowered-repo.list"

dpkg --add-architecture i386
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F24AEA9FB05498B7
apt-get remove -y --purge man-db
apt-get -yq update
apt-get install -yq google-cloud-cli git curl screen silversearcher-ag

curl "https://packages.cloud.google.com/apt/doc/apt-key.gpg" | tee "/usr/share/keyrings/cloud.google.gpg"

# Need Service Account: git-service-account@europan-world.iam.gserviceaccount.com
# With Scopes: Secret Manager Secret Accessor
# Get Github Deploy Key
# Needs to be saved into secret manager by hand.
mkdir -p "/root/.ssh"
gcloud secrets versions access latest --secret="github-deploy-key" | tee "/root/.ssh/id_ecdsa"
chmod 700 "/root/.ssh/id_ecdsa"

# This key is also necessary for github deploy keys.
echo "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=" | tee "/root/.ssh/known_hosts"

git clone "git@github.com:bwinter/baroboys.git" "/root/baroboys"

source "/root/baroboys/setup/git.sh"
source "/root/baroboys/setup/steam.sh"
source "/root/baroboys/setup/barotrauma.sh"