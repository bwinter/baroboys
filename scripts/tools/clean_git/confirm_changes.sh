#!/usr/bin/env bash
set -euxo pipefail

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
CLEAN="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ORIG="${CLEAN}-backup"

echo "🔍 Comparing only differing files..."
find "$ORIG" -type f | sed "s|$ORIG/||" | sort > /tmp/orig_files.txt
find "$CLEAN" -type f | sed "s|$CLEAN/||" | sort > /tmp/clean_files.txt

echo "-----------------------------------------------"
comm -3 /tmp/orig_files.txt /tmp/clean_files.txt
echo "-----------------------------------------------"
echo "✅ Shown above: files only in backup (left) or only in cleaned (right)."
