#!/usr/bin/env bash
set -euxo pipefail

# Wait up to 5 minutes for the apt lock — Packer can race with
# unattended-upgrades on a freshly-booted VM. Without this, runs intermittently
# fail with "Could not get lock /var/lib/apt/lists/lock".
APT_OPTS=(-o DPkg::Lock::Timeout=300)

apt-get "${APT_OPTS[@]}" -yq update

apt-get "${APT_OPTS[@]}" -yq install \
  xvfb