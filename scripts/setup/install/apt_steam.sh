#! /bin/bash
set -eux

echo "🔎 Fetching Steam GPG key..."
TMP_KEY_FILE="/tmp/steam-archive-keyring.gpg"

# Download with visibility and fail detection
curl -fsSL -o "$TMP_KEY_FILE" https://repo.steampowered.com/steam-archive-keyring.gpg

# Show file metadata to confirm it looks like a key
echo "📄 Downloaded key info:"
file "$TMP_KEY_FILE"
stat "$TMP_KEY_FILE"
head -n 5 "$TMP_KEY_FILE" || true

# If file is too small, likely an error page
KEY_SIZE=$(stat --format="%s" "$TMP_KEY_FILE")
if [ "$KEY_SIZE" -lt 1000 ]; then
  echo "❌ Key file looks too small. Aborting."
  cat "$TMP_KEY_FILE"
  exit 1
fi

# Convert and store
echo "🔐 Converting key with gpg..."
gpg --dearmor < "$TMP_KEY_FILE" > "/usr/share/keyrings/steam.gpg"

# Add repo using the keyring
echo "deb [signed-by=/usr/share/keyrings/steam.gpg] https://repo.steampowered.com/steam/ stable steam" \
  | tee "/etc/apt/sources.list.d/steam.list"

# Prep for team by filling in TOS
echo steam steam/question select "I AGREE" | debconf-set-selections
echo steam steam/license note "" | debconf-set-selections

apt-get install -yq steamcmd libicu67