#!/bin/bash
set -eux

dpkg --add-architecture amd64
apt-get -yq update

apt -yq install \
  xvfb