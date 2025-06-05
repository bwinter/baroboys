#!/bin/bash
set -euo pipefail

LOG_FILE="/tmp/vrising_env_diagnostics.log"
exec > >(tee "$LOG_FILE") 2>&1

echo "🔍 Starting V Rising Wine Environment Diagnostics"
echo "📅 Timestamp: $(date)"
echo "📂 Working Directory: $(pwd)"

# ========== SYSTEM INFO ==========

echo -e "\n🔧 System Info"
uname -a
lsb_release -a || true
df -h /
free -h
ulimit -a

echo -e "\n🔧 CPU Info"
lscpu | grep -E 'Model name|Architecture|CPU\(s\):|Thread'

# ========== CGROUPS AND MEMORY LIMITS ==========

echo -e "\n🧠 CGroup Memory Limits"
for file in memory.max memory.swap.max memory.high memory.current; do
  path="/sys/fs/cgroup/$file"
  [[ -f "$path" ]] && echo "$file: $(cat $path)"
done

# ========== WINE CONFIG ==========

echo -e "\n🍷 Wine Binary Info"
command -v wine64 || echo "⚠️ wine64 not found"
file "$(which wine64)" || true
readelf -h "$(which wine64)" | grep 'Class\|Machine' || true

echo -e "\n🍷 Wine Version"
wine64 --version || echo "⚠️ wine64 failed to report version"

echo -e "\n🍷 Wine Prefix Info"
WINEPREFIX="${WINEPREFIX:-$HOME/.wine64}"
echo "WINEPREFIX = $WINEPREFIX"
[[ -d "$WINEPREFIX" ]] || echo "⚠️ WINEPREFIX not found"

if [[ -f "$WINEPREFIX/system.reg" ]]; then
  grep -i 'winearch' "$WINEPREFIX/system.reg" || echo "⚠️ 'winearch' not found in system.reg"
else
  echo "⚠️ system.reg not found in $WINEPREFIX"
fi

# ========== VRISING PROCESS (IF RUNNING) ==========

echo -e "\n🚀 Checking VRising Process Info"
VRISING_PID=$(pgrep -f VRisingServer.exe | head -n1 || true)

if [[ -n "$VRISING_PID" ]]; then
  echo "✅ VRisingServer.exe is running with PID $VRISING_PID"

  echo "🧵 Process: $(readlink -f /proc/$VRISING_PID/exe)"
  pmap -x "$VRISING_PID" | grep -E '(Address|total)' || echo "⚠️ pmap failed"

  echo -e "\n📜 Memory Map Snapshot:"
  head -n 20 "/proc/$VRISING_PID/maps"
else
  echo "⚠️ VRisingServer.exe is not currently running"
fi

# ========== MEMORY ALLOCATION TEST ==========

echo -e "\n🧪 Running Wine VirtualAlloc test (up to 6GB)..."
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

cat > alloc_test.c <<EOF
#include <windows.h>
#include <stdio.h>
int main() {
    SIZE_T size = 6ULL * 1024 * 1024 * 1024;
    void* mem = VirtualAlloc(NULL, size, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
    if (mem == NULL) {
        printf("❌ VirtualAlloc failed\\n");
        return 1;
    } else {
        printf("✅ VirtualAlloc succeeded\\n");
        return 0;
    }
}
EOF

x86_64-w64-mingw32-gcc alloc_test.c -o alloc_test.exe
WINEPREFIX="$WINEPREFIX" wine64 ./alloc_test.exe || echo "⚠️ Wine allocation test failed"
cd -
rm -rf "$TEST_DIR"

echo -e "\n✅ Done. Output saved to: $LOG_FILE"
