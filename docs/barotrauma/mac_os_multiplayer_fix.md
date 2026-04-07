# Barotrauma macOS Multiplayer Fix

> **Status: Untested on current versions.** This patch was required at the time of writing
> (circa 2023) to play multiplayer on macOS. It may no longer be needed — check the
> mod page for current compatibility before applying.

## The Problem

macOS clients couldn't connect to multiplayer servers without the LuaCs mod installed.
This was a known Barotrauma issue on non-Windows platforms.

## The Fix

Install [LuaCsForBarotrauma](https://steamcommunity.com/sharedfiles/filedetails/?id=2559634234)
(Steam Workshop mod by evilfactory).

Manual install (if Workshop doesn't work):

```bash
wget https://github.com/Jlobblet/Barotrauma-Save-Decompressor/releases/download/v1.5.0.0/luacsforbarotrauma_build_linux.tar.gz \
  -O /tmp/luacsforbarotrauma.tar.gz
```

Extract into the Barotrauma install directory (see [mac_os_install_paths.md](mac_os_install_paths.md)).

## Notes

- Check [the GitHub releases page](https://github.com/evilfactory/LuaCsForBarotrauma/releases) for the latest version
- This may not be needed on newer Barotrauma versions — test without it first
