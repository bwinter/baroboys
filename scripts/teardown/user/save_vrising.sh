#!/bin/bash
set -eux

cd "$HOME/baroboys"

SHUTDOWN_DELAY_MINUTES=1
SAVE_DIR="VRising/Data/Saves/v4/TestWorld-1"

SERVER_PASS="$(gcloud secrets versions access latest --secret="server-password")"

touch "/tmp/vrising_intentional_shutdown"

# Tell players and trigger autosave
if ! mcrcon -H 127.0.0.1 -P 25575 -p "$SERVER_PASS" \
  "shutdown ${SHUTDOWN_DELAY_MINUTES} \"Server will shut down in ~{t}m! Get to a safe place.\""; then
  echo "⚠️ mcrcon failed to send shutdown command"
fi

echo "⏳ Waiting ${SHUTDOWN_DELAY_MINUTES} minutes for V Rising to shut down and save..."
sleep "$((SHUTDOWN_DELAY_MINUTES * 60 + 30))"

echo "🔃 Waiting for VRisingServer.exe to shut down..."

if ! timeout 300 bash -c 'while ps -C VRisingServer.exe >/dev/null; do sleep 1; done'; then
  echo "⚠️ VRisingServer.exe did not exit in time. Logging debug info..."
else
  echo "✅ VRisingServer.exe exited cleanly"
fi


# === Compress latest autosave ===
latest_file=$(find "$SAVE_DIR" -type f -name 'AutoSave_*.save' |
  sed -E 's/.*AutoSave_([0-9]+)\.save/\1 \0/' |
  sort -n | tail -n1 | cut -d' ' -f2)

if [[ -z "$latest_file" ]]; then
  echo "❌ No uncompressed .save file found"
  exit 1
fi

echo "🗜 Compressing latest autosave: $latest_file"
gzip -kf "$latest_file"
gzipped_file="${latest_file}.gz"

# === Clean up Git tracking for older autosaves ===
for tracked in $(git ls-files "$SAVE_DIR/AutoSave_*.save.gz"); do
  [[ "$tracked" != "$gzipped_file" ]] && git rm --cached "$tracked"
done

# === Commit latest autosave ===
git add "$gzipped_file"
git commit -m "Auto-save before shutdown $(date -u +'%Y-%m-%d %H:%M:%S UTC')" || echo "Nothing to commit"



# Stash local state, pull, and push
git stash push --include-untracked --quiet || echo "Nothing to stash"
git pull --rebase
git push origin main
git stash pop --quiet || echo "No stash to pop"
