#!/bin/bash
set -e

cd "/home/bwinter_sc81/baroboys/VRising"

# Touch a file to detect intentional shutdown
INTENTIONAL_FLAG="/tmp/vrising_intentional_shutdown"

# Launch server
/usr/bin/wine VRisingServer.exe \
  -persistentDataPath ./Data \
  -serverName "Mc's Playground" \
  -saveName "TestWorld-1" \
  -logFile ./logs/VRisingServer.log

code=$?

# If we were intentionally shut down, don't treat it as failure
if [[ -f "$INTENTIONAL_FLAG" ]]; then
  echo "✅ VRising shutdown was intentional. Suppressing restart."
  rm -f "$INTENTIONAL_FLAG"
  exit 0
fi

# Otherwise return the actual game exit code
echo "❌ VRising exited with code $code"
exit "$code"
