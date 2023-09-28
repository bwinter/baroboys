Need to generate an ssh key. Need to save that key in both github deploy keys and google secrets manager.
Then use a service account with secret manager scopes assigned to the VM to get access to the key so you can clone on
the VM.

Also need to manually put holes in the VPC Firewall to allow the two ports through.

#### Helpful Tools:

- To see the output of the `metadata_startup_script` run the following when on the VM:

  ```shell
  sudo journalctl -u google-startup-scripts.service
  ```

- SSH onto the machine:

  ```shell
  gcloud compute ssh bwinter_sc81@europa --project=europan-world --zone=us-west1-b
  ```

- Setup local env to use your repo:

  Link Local Mods
  ```shell
  rm -fr '/Users/bwinter/Library/Application Support/Steam/steamapps/common/Barotrauma/Barotrauma.app/Contents/MacOS/LocalMods'
  ln -s '/Users/bwinter/personal-workspace/baroboys/Barotrauma/LocalMods/' '/Users/bwinter/Library/Application Support/Steam/steamapps/common/Barotrauma/Barotrauma.app/Contents/MacOS'
  ```
  Link Remote Mods
  ```shell
  ln -s '/Users/bwinter/personal-workspace/baroboys/Barotrauma/WorkshopMods/' '/Users/bwinter/Library/Application Support/Daedalic Entertainment GmbH/Barotrauma'
  ```
  Link Multiplayer Games
  ```shell
  ln -s '/Users/bwinter/personal-workspace/baroboys/Barotrauma/Multiplayer/' '/Users/bwinter/Library/Application Support/Daedalic Entertainment GmbH/Barotrauma'
  ```

- Important Locations
  - Local Content: /Users/bwinter/Library/Application Support/Steam/steamapps/common/Barotrauma/Barotrauma.app/Contents/MacOS
  - Remote Content: /Users/bwinter/Library/Application Support/Daedalic Entertainment GmbH/Barotrauma

- SSH keys are saved in GCP secret manager.
- Keys for terraform need to be generated using the terraform service account.

# VirtualBox

There is a screenshot as a reminder on how setting this up.
