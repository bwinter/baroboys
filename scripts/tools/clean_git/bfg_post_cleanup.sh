#!/usr/bin/env bash
set -euo pipefail

########################################
# BFG Post-Cleanup Script
# 1️⃣ Preview cleaned repo
# 2️⃣ Diff logs and working trees
# 3️⃣ Confirm push and local replacement
########################################

### CONFIG ###
WORKDIR="/tmp/bfg-cleanup"
MIRROR_REPO="$WORKDIR/baroboys-bfg-clean.git"
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
  printf "\n🔹 %s\n" "$1"
}

### 1️⃣ Checks ###
step "🗂️ Validating cleaned mirror"
if [[ ! -d "$MIRROR_REPO" ]]; then
  echo "❌ Bare mirror missing. Run bfg_pre_cleanup.sh and bfg_cleanup.sh first."
  exit 1
fi
echo "♻️  Using cleaned mirror: $MIRROR_REPO"

### 2️⃣ Clone preview ###
step "1️⃣ Clone cleaned bare repo → preview working copy"
if [[ -d "$PREVIEW_CLONE" ]]; then
  echo "♻️  Preview working tree already exists: $PREVIEW_CLONE"
else
  if confirm "   Clone preview working copy?"; then
    git clone "$MIRROR_REPO" "$PREVIEW_CLONE"
    echo "✅ Preview clone created: $PREVIEW_CLONE"
  else
    echo "⏭️  Skipping preview clone."
  fi
fi

### 3️⃣ Diff logs ###
step "2️⃣ Compare commit logs: original vs cleaned"
if confirm "   Generate and diff git logs?"; then
  ORIGINAL_LOG="/tmp/original.log"
  CLEANED_LOG="/tmp/cleaned.log"

  git -C "$ORIGINAL_REPO" log --graph --oneline --all > "$ORIGINAL_LOG"
  git -C "$PREVIEW_CLONE" log --graph --oneline --all > "$CLEANED_LOG"

  echo "📄 Original log: $ORIGINAL_LOG"
  echo "📄 Cleaned log:  $CLEANED_LOG"
  echo "🔍 Diff:"
  diff "$ORIGINAL_LOG" "$CLEANED_LOG" || true
else
  echo "⏭️  Skipping log diff."
fi

### 4️⃣ Diff working trees ###
step "3️⃣ Compare working directories"
if confirm "   Diff working directories?"; then
  echo "🔍 Running diff -r ..."
  diff -r "$ORIGINAL_REPO" "$PREVIEW_CLONE" || true
else
  echo "⏭️  Skipping working tree diff."
fi

### 5️⃣ Push cleaned mirror ###
step "4️⃣ Push cleaned repo to remote (⚠️ destructive!)"
if [[ -z "$REMOTE_URL" ]]; then
  echo "❌ REMOTE_URL is empty! Edit script and set your real remote URL."
  exit 1
fi

cd "$MIRROR_REPO"
git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE_URL"

if confirm "   Push cleaned history to remote? This will overwrite remote history!"; then
  git push --mirror origin
  echo "✅ Remote history rewritten!"
else
  echo "⏭️  Skipping push to remote."
fi

### 6️⃣ Replace local working copy ###
step "5️⃣ Replace local working repo"
if confirm "   Backup and re-clone working copy from cleaned remote?"; then
  if [[ -d "$BACKUP_REPO" ]]; then
    echo "♻️  Backup already exists: $BACKUP_REPO"
  else
    mv "$ORIGINAL_REPO" "$BACKUP_REPO"
    echo "✅ Backup created: $BACKUP_REPO"
  fi

  git clone "$REMOTE_URL" "$ORIGINAL_REPO"
  echo "✅ Fresh cleaned clone: $ORIGINAL_REPO"
else
  echo "⏭️  Skipping local working repo replace."
fi

echo -e "\n🎉 BFG post-cleanup workflow complete!"
echo "📦 Original backup: $BACKUP_REPO"
