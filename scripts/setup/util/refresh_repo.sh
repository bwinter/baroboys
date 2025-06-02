#!/bin/bash
set -euxo pipefail

REPO_PATH="$HOME/baroboys"
GIT_REMOTE="git@github.com:bwinter/baroboys.git"

# --- SSH Setup ---
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Deploy key
gcloud secrets versions access latest --secret="github-deploy-key" --quiet > "$HOME/.ssh/id_ecdsa"
chmod 600 "$HOME/.ssh/id_ecdsa"

# GitHub known_hosts
echo "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=" \
  > "$HOME/.ssh/known_hosts"

# --- Repo Setup ---
if [ -d "$REPO_PATH/.git" ]; then
  echo "🔄 Repo exists, pulling with stash..."
  cd "$REPO_PATH"

  # Stash any uncommitted work (autosaves, local testing, etc.)
  git stash push --include-untracked --quiet || echo "🟡 Nothing to stash"

  # Rebase for clean logs, fallback to merge if needed
  echo "🔄 Pulling latest from main branch..."
  if ! git pull --rebase 2>&1 | tee /dev/stderr; then
    echo "⚠️ Rebase failed, trying fallback merge..."
    git pull --no-rebase 2>&1 | tee /dev/stderr
  fi


  # Restore any stashed work
  git stash pop --quiet || echo "No stash to pop"
else
  echo "📦 Cloning repo fresh from $GIT_REMOTE into $REPO_PATH..."
  GIT_SSH_COMMAND="ssh -i $HOME/.ssh/id_ecdsa -o IdentitiesOnly=yes" \
    git clone --progress --verbose "$GIT_REMOTE" "$REPO_PATH" 2>&1 | tee /dev/stderr
fi

# --- Git Config ---
[ -f "$HOME/.gitconfig" ] || cp "$REPO_PATH/.gitconfig" "$HOME/.gitconfig"
