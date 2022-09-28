#### Helpful Tools:

To see the output of the `metadata_startup_script` run the following when on the VM:
```shell
sudo journalctl -u google-startup-scripts.service
```

SSH onto the machine:
```shell
gcloud compute ssh bwinter_sc81@terraform-test-vm --project=europan-world --zone=us-west1-b
```