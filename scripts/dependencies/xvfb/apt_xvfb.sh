#!/usr/bin/env bash
set -euxo pipefail

dpkg --add-architecture amd64
apt-get -yq update

apt -yq install \
  xvfb