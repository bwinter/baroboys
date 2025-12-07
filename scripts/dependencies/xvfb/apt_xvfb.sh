#!/bin/bash
set -eux

sudo dpkg --add-architecture amd64
sudo apt-get -yq update

sudo apt -yq install \
  xvfb