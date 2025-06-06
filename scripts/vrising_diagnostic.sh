#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALLOC_TEST_SOURCE="${SCRIPT_DIR}/alloc_test.c"
LOG_FILE="/tmp/vrising_env_diagnostics.log"
exec > >(tee "$LOG_FILE") 2>&1

echo "🔍 Starting V Rising Wine Environment Diagnostics"
echo "📅 Timestamp: $(date)"
echo "📂 Script Directory: $SCRIPT_DIR"

# ========== SYSTEM INFO ==========
echo -e "\n🔧 System Info"
uname -a
lsb_release -a || true
df -h /
free -h
ulimit -a

echo -e "\n🔧 CPU Info"
lscpu | grep -E 'Model name|Architecture|CPU\\(s\\):|Thread'

# ========== CGROUPS AND MEMORY LIMITS ==========
echo -e "\n🧠 CGroup Memory Limits"
for file in memory.max memory.swap.max memory.high memory.current; do
  path="/sys/fs/cgroup/$file"
  [[ -f "$path" ]] && echo "$file: $(cat $path)"
done

# ========== WINE BINARY ARCH ==========
echo -e "\n🧩 Wine Binary Architecture Check"

check_binary_arch() {
  local bin="$1"
  if command -v "$bin" &>/dev/null; then
    echo -n "🔎 $bin: "
    file "$(command -v "$bin")" | grep -Eo '64-bit|32-bit' || echo "Unknown"
  else
    echo "⚠️ $bin not found"
  fi
}

check_binary_arch wine
check_binary_arch wine64
check_binary_arch wineserver

# ========== WINE VERSION ==========
echo -e "\n🍷 Wine Version"
wine --version || echo "⚠️ wine failed to report version"

# ========== WINE PREFIX ==========
echo -e "\n📁 Wine Prefix Info"
WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
echo "WINEPREFIX = $WINEPREFIX"
[[ -d "$WINEPREFIX" ]] || echo "⚠️ WINEPREFIX not found"

if [[ -f "$WINEPREFIX/system.reg" ]]; then
  grep -i 'winearch' "$WINEPREFIX/system.reg" || echo "⚠️ 'winearch' not found in system.reg"
else
  echo "⚠️ system.reg not found in $WINEPREFIX"
fi

# ========== VRISING PROCESS ==========
echo -e "\n🚀 Checking VRising Process Info"
VRISING_PID=$(pgrep -f VRisingServer.exe | head -n1 || true)
VRISING_BITNESS="unknown"
VRISING_TOP_ADDR="unknown"

if [[ -n "$VRISING_PID" ]]; then
  echo "✅ VRisingServer.exe is running with PID $VRISING_PID"

  VRISING_EXE_PATH=$(readlink -f "/proc/$VRISING_PID/exe")
  echo "🧵 Executable Path: $VRISING_EXE_PATH"

  echo -n "🧬 Binary Architecture: "
  file "$VRISING_EXE_PATH" | grep -Eo '64-bit|32-bit' || echo "Unknown"
  VRISING_BITNESS=$(file "$VRISING_EXE_PATH" | grep -Eo '64-bit|32-bit' || echo "unknown")

  echo -e "\n📊 Top 20 Memory Mappings (check address space):"
  TOP_LINE=$(head -n 1 "/proc/$VRISING_PID/maps")
  TOP_ADDR=$(echo "$TOP_LINE" | cut -d'-' -f1)
  VRISING_TOP_ADDR="$TOP_ADDR"
  echo "$TOP_LINE"

  printf "🧠 Top memory address: %s " "$TOP_ADDR"
  if [[ "$TOP_ADDR" =~ ^[0-7][0-9a-f]{7,}$ ]]; then
    echo "✅ (high memory region, likely 64-bit)"
  else
    echo "❌ (low memory region, suspicious)"
  fi

  echo -e "\n📜 Memory Map Snapshot (looking for 32-bit lib contamination):"
  grep -E 'wine|\.dll' "/proc/$VRISING_PID/maps" | while read -r line; do
    bin=$(echo "$line" | awk '{print $6}')
    [[ -f "$bin" ]] && file "$bin" | grep -q "32-bit" && echo "❗ 32-bit binary loaded: $bin"
  done
else
  echo "⚠️ VRisingServer.exe is not currently running"
fi

# ========== IN-PROCESS ALLOC & ARCH TEST ==========
echo -e "\n🧪 In-Wine Architecture & Memory Sanity Test"

TEST_DIR=$(mktemp -d)
cp "$ALLOC_TEST_SOURCE" "$TEST_DIR/"
cd "$TEST_DIR"

echo "📦 Compiling alloc_test.exe"
x86_64-w64-mingw32-gcc alloc_test.c -o alloc_test.exe

echo "🚀 Running alloc_test.exe under Wine"
ALLOC_RESULT=$(WINEPREFIX="$WINEPREFIX" wine ./alloc_test.exe 2>&1 || true)
echo "$ALLOC_RESULT"

cd /
rm -rf "$TEST_DIR"

# ========== SUMMARY ==========
echo -e "\n📊 FINAL VERDICT"

printf "%-30s %s\n" "VRising binary:" "$VRISING_BITNESS"
printf "%-30s %s\n" "Top memory mapping:" "$VRISING_TOP_ADDR"
printf "%-30s " "Wine binary:"
file "$(command -v wine)" | grep -q "64-bit" && echo "✅ 64-bit" || echo "❌ Not 64-bit"

printf "%-30s " "Wineserver:"
command -v wineserver &>/dev/null && file "$(command -v wineserver)" | grep -q "64-bit" && echo "✅ 64-bit" || echo "❌ Not 64-bit"

if echo "$ALLOC_RESULT" | grep -q "✅ VirtualAlloc succeeded"; then
  echo "🧠 Memory allocation test: ✅ Passed"
else
  echo "🧠 Memory allocation test: ❌ Failed"
fi

echo -e "\n🗂️ Diagnostics log saved to: $LOG_FILE"
