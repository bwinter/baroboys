#!/bin/bash
set -eux

gcloud compute ssh bwinter_sc81@europa \
  --project=europan-world \
  --zone=us-west1-b \
  --command="/home/bwinter_sc81/baroboys/scripts/teardown/user/save_vrising.sh"
