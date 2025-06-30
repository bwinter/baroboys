#!/usr/bin/env bash
set -euo pipefail

### CONFIG ###
CLEANUP_DIR="/tmp/bfg-cleanup"
CLEANED_REPO="$CLEANUP_DIR/baroboys-bfg-clean.git"
PREVIEW_CLONE="$HOME/Desktop/Baroboys-preview"
ORIGINAL_REPO="$HOME/Desktop/Baroboys"
BACKUP_REPO="$HOME/Desktop/Baroboys-backup"
REMOTE_URL="git@github.com:bwinter/baroboys.git"

### Helpers ###
confirm() {
  read -rp "$1 [y/N]: " answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

step() {
  echo -e "\n🔹 $1"
}

### Checks ###
if [[ ! -d "$CLEANED_REPO" ]]; then
  echo "❌ Cleaned bare repo not found: $CLEANED_REPO"
  exit 1
fi

echo "🧼 Starting BFG post-cleanup workflow..."
echo "📁 Cleaned repo: $CLEANED_REPO"
echo "📁 Original repo: $ORIGINAL_REPO"

### 1️⃣ Clone preview working tree ###
step "1️⃣ Clone cleaned bare repo → preview working copy"
if [[ -d "$PREVIEW_CLONE" ]]; then
  echo "♻️  Preview working tree already exists at $PREVIEW_CLONE"
else
  if confirm "   Clone preview working copy?"; then
    git clone "$CLEANED_REPO" "$PREVIEW_CLONE"
    echo "✅ Preview clone created at: $PREVIEW_CLONE"
  else
    echo "⏭️  Skipping preview clone step."
  fi
fi

### 2️⃣ Show commit log diff ###
step "2️⃣ Compare logs: original vs cleaned"
if confirm "   Generate and diff git logs?"; then
  ORIGINAL_LOG="/tmp/original.log"
  CLEANED_LOG="/tmp/cleaned.log"

  cd "$ORIGINAL_REPO"
  git log --graph --oneline --all > "$ORIGINAL_LOG"

  cd "$PREVIEW_CLONE"
  git log --graph --oneline --all > "$CLEANED_LOG"

  echo "📄 Original log: $ORIGINAL_LOG"
  echo "📄 Cleaned log:  $CLEANED_LOG"

  echo "🔍 Diff:"
  diff "$ORIGINAL_LOG" "$CLEANED_LOG" || true
else
  echo "⏭️  Skipping log diff step."
fi

### 3️⃣ Optional working tree diff ###
step "3️⃣ Compare working trees (files) for sanity"
if confirm "   Diff working directory trees?"; then
  echo "🔍 Running diff -r ..."
  diff -r "$ORIGINAL_REPO" "$PREVIEW_CLONE" || true
else
  echo "⏭️  Skipping working tree diff step."
fi

### 4️⃣ Push cleaned history to remote ###
step "4️⃣ Push cleaned repo to REMOTE (⚠️ destructive!)"
if [[ -z "$REMOTE_URL" ]]; then
  echo "❌ REMOTE_URL is empty! Edit script and set your real remote URL."
  exit 1
fi

cd "$CLEANED_REPO"
git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE_URL"

if confirm "   Push cleaned history to remote? This will overwrite remote history!"; then
  git push --mirror origin
  echo "✅ Cleaned history pushed to remote!"
else
  echo "⏭️  Skipping push to remote."
fi

### 5️⃣ Replace local working repo ###
step "5️⃣ Replace local working repo with fresh clone"
if confirm "   Backup and re-clone working copy from cleaned remote?"; then
  if [[ -d "$BACKUP_REPO" ]]; then
    echo "♻️  Backup already exists at $BACKUP_REPO"
  else
    mv "$ORIGINAL_REPO" "$BACKUP_REPO"
    echo "✅ Backup made at: $BACKUP_REPO"
  fi

  git clone "$REMOTE_URL" "$ORIGINAL_REPO"
  echo "✅ Fresh cleaned clone at: $ORIGINAL_REPO"
else
  echo "⏭️  Skipping local working repo replace."
fi

echo -e "\n🎉 All done! BFG cleanup workflow complete. Original backup: $BACKUP_REPO"
