#!/usr/bin/env bash
set -euxo pipefail

# Add WineHQ key
curl -fsSL "https://dl.winehq.org/wine-builds/winehq.key" \
  | gpg --dearmor -o "/usr/share/keyrings/winehq.gpg"

# Add the repo for Bookworm
echo "deb [signed-by=/usr/share/keyrings/winehq.gpg] https://dl.winehq.org/wine-builds/debian bookworm main" \
  > "/etc/apt/sources.list.d/winehq.list"

dpkg --add-architecture amd64
apt-get -yq update

apt -yq install wine-stable

# Install winetricks directly from source to avoid pulling in Debian's wine packages.
# Debian's winetricks package depends on wine (Debian 8.x), which would shadow WineHQ's
# wine at /opt/wine-stable/bin/ whenever 'wine' is invoked without a full path.
curl -fsSL "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" \
  -o /usr/local/bin/winetricks
chmod +x /usr/local/bin/winetricks

# Add WineHQ bin to front of PATH system-wide so 'wine' always resolves to WineHQ, not Debian's.
echo 'export PATH="/opt/wine-stable/bin:$PATH"' > /etc/profile.d/winehq.sh
chmod 644 /etc/profile.d/winehq.sh
export PATH="/opt/wine-stable/bin:$PATH"

# Diagnostics: show what WineHQ installed (useful when wine binary path changes between versions)
echo "ℹ️ /opt/wine-stable/bin/ contents:"
ls /opt/wine-stable/bin/ || echo "⚠️ /opt/wine-stable/bin/ not found"

# Show version (Wine 11+ unified wine64 into a single 'wine' binary)
echo "ℹ️ wine version info:"
wine --version || {
  echo "⚠️ wine not working" >&2
  exit 1
}

# Need to happen before wine installer can finish.
echo "🪟 Starting xvfb..."
systemctl start xvfb-startup.service

# Initialize Wine prefix (once!)
sudo -u bwinter_sc81 -H -- "/home/bwinter_sc81/baroboys/scripts/dependencies/wine/src/setup.sh"

echo "✅ Fonts install attempt complete."
