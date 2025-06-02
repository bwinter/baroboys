#!/bin/bash
set -euo pipefail

# Usage: ./bfg_cleanup.sh [path/to/repo]
REPO_PATH="${1:-$HOME/Desktop/Baroboys}"
WORKDIR="/tmp/bfg-cleanup"
ORIG_LIST="/tmp/deletable-blobs.txt"
BFG_VERSION="1.14.0"
BFG_URL="https://repo1.maven.org/maven2/com/madgag/bfg/$BFG_VERSION/bfg-$BFG_VERSION.jar"
BFG_JAR="$WORKDIR/bfg-$BFG_VERSION.jar"
REPORT_FILE="bfg-report.log"

echo "🧹 Starting BFG history cleanup..."

# 1) Verify the deletable‐blobs list exists and is non‐empty
if [[ ! -f "$ORIG_LIST" ]] || [[ ! -s "$ORIG_LIST" ]]; then
  echo "❌ Error: $ORIG_LIST missing or empty."
  echo "🧠 Run ./scripts/print_git_info.sh $REPO_PATH first."
  exit 1
fi

# 2) Prepare workspace
echo "♻️  Cleaning any previous workspace at $WORKDIR ..."
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

# 3) Clone a bare mirror
echo "📥 Cloning bare mirror of '$REPO_PATH' → $WORKDIR/baroboys-bfg-clean.git"
git clone --mirror "$REPO_PATH" "$WORKDIR/baroboys-bfg-clean.git" &> /dev/null

# 4) Download BFG if not already present
if [[ ! -f "$BFG_JAR" ]]; then
  echo "⬇️ Downloading BFG v$BFG_VERSION..."
  curl -sSL "$BFG_URL" -o "$BFG_JAR"
fi

# 5) Strip each path down to its filename and build a comma list
echo "🔎 Reducing $ORIG_LIST → filenames only…"
FILENAMES=$(cat "$ORIG_LIST" \
  | xargs -n1 basename \
  | sort -u \
  | paste -sd, -)

COUNT=$(echo "$FILENAMES" | tr ',' '\n' | wc -l | tr -d ' ')
echo "🚀 Running BFG cleanup on $COUNT unique filenames…"
echo "   Preview of first 10 filenames:"
echo "$FILENAMES" | tr ',' '\n' | head -n 10 | awk '{ print "     •", $0 }'
if [[ "$COUNT" -gt 10 ]]; then echo "     ... and $((COUNT-10)) more"; fi

# 6) Execute BFG inside the bare clone
(
  cd "$WORKDIR/baroboys-bfg-clean.git"
  java -jar "$BFG_JAR" --delete-files "$FILENAMES"
)

# 7) Check for BFG’s report
if [[ -f "$WORKDIR/baroboys-bfg-clean.git/$REPORT_FILE" ]]; then
  MATCHED=$(grep -c '^file ' "$WORKDIR/baroboys-bfg-clean.git/$REPORT_FILE" || true)
  echo
  echo "📝 BFG deleted $MATCHED blob entries."
  echo "🗒️ Top 10 deleted paths (in history):"
  grep -E '^file ' "$WORKDIR/baroboys-bfg-clean.git/$REPORT_FILE" \
    | sort -k3 -n -r \
    | head -n 10 \
    | awk '{ print "   •", $3 }'
else
  echo
  echo "⚠️  No BFG report found—cleanup may have failed."
  exit 1
fi

# 8) Expire reflogs & run aggressive GC on the bare repo
echo
echo "🧼 Expiring reflogs and performing aggressive GC in the mirror…"
cd "$WORKDIR/baroboys-bfg-clean.git"
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# 9) Success message
echo
echo "✅ History rewrite complete!"
echo "📁 Cleaned bare repo: $WORKDIR/baroboys-bfg-clean.git"
echo
echo "🔍 To inspect the cleaned repo, you can run:"
echo "    ./scripts/print_git_info.sh $WORKDIR/baroboys-bfg-clean.git"
echo
echo "🚩 To overwrite your origin, run:"
echo "    cd $WORKDIR/baroboys-bfg-clean.git"
echo "    git remote set-url origin <your-remote-url>"
echo "    git push --force"
