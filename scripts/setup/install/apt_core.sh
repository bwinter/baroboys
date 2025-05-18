#!/bin/bash
set -eux

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

# Refresh state.
dpkg --add-architecture i386
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F24AEA9FB05498B7
apt-get remove -y --purge man-db
apt-get -yq update
apt-get -yq upgrade
apt-get install -yq git curl screen silversearcher-ag build-essential wget dirmngr apt-transport-https ca-certificates gnupg