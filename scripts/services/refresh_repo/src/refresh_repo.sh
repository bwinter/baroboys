#!/usr/bin/env bash
set -euxo pipefail

# Single canonical clone lives at bwinter_sc81's home; this script always
# operates on that path regardless of which user invokes it. SSH key + .ssh
# go to bwinter's home for the same reason — the clone is always for bwinter.
REPO_PATH="/home/bwinter_sc81/baroboys"
SSH_HOME="/home/bwinter_sc81"
GIT_REMOTE="git@github.com:bwinter/baroboys.git"

# --- SSH Setup ---
mkdir -p "$SSH_HOME/.ssh"
chmod 700 "$SSH_HOME/.ssh"

# Deploy key
gcloud secrets versions access latest --secret="github-deploy-key" --quiet > "$SSH_HOME/.ssh/id_ecdsa"
chmod 600 "$SSH_HOME/.ssh/id_ecdsa"

# GitHub known_hosts
echo "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=" \
  > "$SSH_HOME/.ssh/known_hosts"

# --- Repo Setup ---
if [ -d "$REPO_PATH/.git" ]; then
  echo "🔄 Repo exists, pulling with stash..."
  cd "$REPO_PATH"

  # Stash any uncommitted work (autosaves, local testing, etc.)
  git stash push --include-untracked --quiet || echo "🟡 Nothing to stash"

  # Rebase for clean logs, fallback to merge if needed
  echo "🔄 Pulling latest from main branch..."
  if ! git pull --rebase; then
    echo "⚠️ Rebase failed, trying fallback merge..."
    git pull --no-rebase
  fi

  # Restore any stashed work
  git stash pop --quiet || echo "No stash to pop"
else
  echo "📦 Cloning repo fresh from $GIT_REMOTE into $REPO_PATH..."
  GIT_SSH_COMMAND="ssh -i $SSH_HOME/.ssh/id_ecdsa -o IdentitiesOnly=yes" \
    git clone --progress --verbose "$GIT_REMOTE" "$REPO_PATH"
fi

# --- Git Config ---
[ -f "$SSH_HOME/.gitconfig" ] || cp "$REPO_PATH/.gitconfig" "$SSH_HOME/.gitconfig"
