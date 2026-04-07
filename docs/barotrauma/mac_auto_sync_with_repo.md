# Sync Local Barotrauma Files with Repo (macOS)

> **Status: Broken on modern macOS.** Apple's app sandboxing prevents symlinks into
> application bundles. The approach below worked on older macOS versions. A workaround
> for current macOS has not been tested.

## Goal

Link local mod and save directories to the repo so changes show up as git diffs.
Useful when iterating on submarines or mods — edit locally, commit from the repo.

## Paths

| What | Local path | Repo path |
|------|-----------|-----------|
| Local Mods | `~/Library/Application Support/Steam/steamapps/common/Barotrauma/Barotrauma.app/Contents/MacOS/LocalMods` | `Barotrauma/LocalMods/` |
| Workshop Mods | `~/Library/Application Support/Daedalic Entertainment GmbH/Barotrauma/WorkshopMods/` | `Barotrauma/WorkshopMods/` |
| Multiplayer Saves | `~/Library/Application Support/Daedalic Entertainment GmbH/Barotrauma/Multiplayer/` | `Barotrauma/Multiplayer/` |

## Original Approach (broken)

Replace the local directories with symlinks to the repo:

```bash
# Local Mods (requires access inside .app bundle — blocked by macOS sandboxing)
rm '~/Library/Application Support/Steam/steamapps/common/Barotrauma/Barotrauma.app/Contents/MacOS/LocalMods'
ln -s '/path/to/repo/Barotrauma/LocalMods/' '~/Library/Application Support/Steam/steamapps/common/Barotrauma/Barotrauma.app/Contents/MacOS/'

# Workshop Mods
rm '~/Library/Application Support/Daedalic Entertainment GmbH/Barotrauma/WorkshopMods/'
ln -s '/path/to/repo/Barotrauma/WorkshopMods/' '~/Library/Application Support/Daedalic Entertainment GmbH/Barotrauma'

# Multiplayer Saves
rm '~/Library/Application Support/Daedalic Entertainment GmbH/Barotrauma/Multiplayer/'
ln -s '/path/to/repo/Barotrauma/Multiplayer/' '~/Library/Application Support/Daedalic Entertainment GmbH/Barotrauma'
```

The Workshop Mods and Multiplayer symlinks may still work (outside the .app bundle).
The Local Mods symlink fails because macOS prevents modifications inside `.app` bundles.

## Possible Workarounds (untested)

- **Reverse the symlink** — keep the real files in the repo, symlink *from* the game directory. May work for Workshop/Multiplayer but not LocalMods inside the bundle.
- **rsync on save** — copy files from the game directory to the repo periodically or on game exit. Loses the real-time symlink benefit but works with sandboxing.
- **Windows/Linux** — symlinks work without sandboxing restrictions on these platforms.
