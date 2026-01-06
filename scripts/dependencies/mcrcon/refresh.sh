#!/usr/bin/env bash
set -euxo pipefail

# Target binary
MCRCON_BIN="/usr/local/bin/mcrcon"

# Only install if missing or outdated
if ! command -v mcrcon >/dev/null || ! "$MCRCON_BIN" -v 2>&1 | grep -qi 'mcrcon'; then
  echo "🔧 Installing mcrcon..."

  # Clean any prior partial install
  rm -rf "/tmp/mcrcon"

  # Clone and build
  git clone "https://github.com/Tiiffi/mcrcon.git" "/tmp/mcrcon"
  cd "/tmp/mcrcon"
  make

  # Install if not already identical
  if ! cmp -s ./mcrcon "$MCRCON_BIN"; then
    /usr/bin/sudo mv ./mcrcon "$MCRCON_BIN"
    /usr/bin/sudo chmod +x "$MCRCON_BIN"
  fi

  echo "✅ mcrcon installed to $MCRCON_BIN"
else
  echo "✅ mcrcon already installed"
fi
