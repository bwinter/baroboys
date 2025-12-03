# NOTE THIS NO LONGER WORKS DUE TO MAC OS FENCING!

Works on Windows but requires different commands.

# Developers (Mac OS)

### Getting submarine out of the save file

Use VirtualBox to get Windows

Setting up file paths:

![VirtualBox Disk Setup](VirtualBox%20Shared%20Folders.png)

See `scripts/save-decompressor`

### Setup local env to use repo:

This is helpful when iterating as you can have your sub updates show up in your repo for an easy git commit.

Link Local Mods

  ```shell
  rm '/Users/bwinter/Library/Application Support/Steam/steamapps/common/Barotrauma/Barotrauma.app/Contents/MacOS/LocalMods'
  ln -s '/Users/bwinter/Desktop/Baroboys/Barotrauma/LocalMods/' '/Users/bwinter/Library/Application Support/Steam/steamapps/common/Barotrauma/Barotrauma.app/Contents/MacOS/'
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
    - Local Install:
      `/Users/bwinter/Library/Application Support/Steam/steamapps/common/Barotrauma/Barotrauma.app/Contents/MacOS`
    - Multiplayer & Community Mods: `/Users/bwinter/Library/Application Support/Daedalic Entertainment GmbH/Barotrauma`
