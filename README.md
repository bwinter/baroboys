Need to generate an ssh key. Need to save that key in both github deploy keys and google secrets manager. 
Then use a service account with secret manager scopes assigned to the VM to get access to the key so you can clone on the VM.

Also need to manually put holes in the VPC Firewall to allow the two ports through.

#### Helpful Tools:

To see the output of the `metadata_startup_script` run the following when on the VM:
```shell
sudo journalctl -u google-startup-scripts.service
```

SSH onto the machine:
```shell
gcloud compute ssh bwinter_sc81@terraform-test-vm --project=europan-world --zone=us-west1-b
```