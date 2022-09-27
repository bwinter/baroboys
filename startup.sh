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

" | sudo tee /etc/apt/sources.list
### gcloud
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
### steam
echo "deb [arch=i386,amd64] http://repo.steampowered.com/steam/ precise steam" | sudo tee /etc/apt/sources.list.d/steampowered-repo.list

### Ensure keys for sources.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F24AEA9FB05498B7
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo tee /usr/share/keyrings/cloud.google.gpg

sudo apt-get update
sudo apt-get install -yq build-essential \
  curl wget apt-transport-https dirmngr \
  apt-transport-https ca-certificates gnupg \
  google-cloud-cli \
  git

env
gcloud init
uname -a
# Get Github Deploy Key
gcloud secrets versions access latest --secret="github-deploy-key" >"/home/$(users)/.ssh/id_ecdsa"
echo "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=" >"/home/$(users)/.ssh/known_hosts"


echo screen -S baro-server -d -m ./Steam/steamapps/common/Barotrauma\ Dedicated\ Server/DedicatedServer
