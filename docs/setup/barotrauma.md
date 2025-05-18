# Local (Mac OS)

### Getting sub out of the save file

Use VirtualBox to get Windows

Setting up file paths:

![VirtualBox Disk Setup](assets/VirtualBox%20Disk%20Setup.png)

See `scripts/save-decompressor`

### Setup local env to use repo:

This is helpful when iterating as you can have your sub updates show up in your repo for saving.

  Link Local Mods
  ```shell
  rm -fr '/Users/bwinter/Library/Application Support/Steam/steamapps/common/Barotrauma/Barotrauma.app/Contents/MacOS/LocalMods'
  ln -s '/Users/bwinter/Desktop/Baroboys/Barotrauma/LocalMods/' '/Users/bwinter/Library/Application Support/Steam/steamapps/common/Barotrauma/Barotrauma.app/Contents/MacOS'
  ```
  Link Remote Mods
  ```shell
  rm '/Users/bwinter/Library/Application Support/Daedalic Entertainment GmbH/Barotrauma/WorkshopMods/'
  ln -s '/Users/bwinter/Desktop/Baroboys/Barotrauma/WorkshopMods/' '/Users/bwinter/Library/Application Support/Daedalic Entertainment GmbH/Barotrauma'
  ```
  Link Multiplayer Games
  ```shell
  rm '/Users/bwinter/Library/Application Support/Daedalic Entertainment GmbH/Barotrauma/Multiplayer/'
  ln -s '/Users/bwinter/Desktop/Baroboys/Barotrauma/Multiplayer/' '/Users/bwinter/Library/Application Support/Daedalic Entertainment GmbH/Barotrauma'
  ```

- Important Locations
    - Local Content: `/Users/bwinter/Library/Application Support/Steam/steamapps/common/Barotrauma/Barotrauma.app/Contents/MacOS`
    - Remote Content: `/Users/bwinter/Library/Application Support/Daedalic Entertainment GmbH/Barotrauma`
