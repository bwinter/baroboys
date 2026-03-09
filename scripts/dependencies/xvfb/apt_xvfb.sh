#!/usr/bin/env bash
set -euxo pipefail

apt-get -yq update

apt -yq install \
  xvfb