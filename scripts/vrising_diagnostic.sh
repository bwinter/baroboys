#!/bin/bash
set -euxo pipefail

# ========== Color Handling ==========
COLOR_RESET=$(tput sgr0 || echo "")
COLOR_GREEN=$(tput setaf 2 || echo "")
COLOR_RED=$(tput setaf 1 || echo "")
COLOR_YELLOW=$(tput setaf 3 || echo "")
COLOR_BLUE=$(tput setaf 4 || echo "")
COLOR_BOLD=$(tput bold || echo "")

# ========== Setup ==========
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALLOC_TEST_SOURCE="${SCRIPT_DIR}/alloc_test.c"
LOG_FILE="/tmp/vrising_env_diagnostics.log"
exec > >(tee "$LOG_FILE") 2>&1

echo "${COLOR_BOLD}🔍 Starting V Rising Wine Environment Diagnostics${COLOR_RESET}"
echo "📅 Timestamp: $(date)"
echo "📂 Script Directory: $SCRIPT_DIR"

# ========== System Info ==========
echo -e "\n${COLOR_BLUE}🔧 System Info${COLOR_RESET}"
uname -a
lsb_release -a || true
df -h /
free -h
ulimit -a

echo -e "\n${COLOR_BLUE}🔧 CPU Info${COLOR_RESET}"
lscpu | grep -E 'Model name|Architecture|CPU\(s\):|Thread'

# ========== CGroup Limits ==========
echo -e "\n${COLOR_BLUE}🧠 CGroup Memory Limits${COLOR_RESET}"
for f in memory.max memory.swap.max memory.high memory.current; do
  [[ -f "/sys/fs/cgroup/$f" ]] && echo "$f: $(cat /sys/fs/cgroup/$f)"
done

# ========== Wine Binary Architecture ==========
echo -e "\n${COLOR_BLUE}🧩 Wine Binary Architecture Check${COLOR_RESET}"
for bin in wine wine64 wineserver; do
  if command -v "$bin" &>/dev/null; then
    echo -n "🔎 $bin: "
    file "$(command -v "$bin")" | grep -Eo '64-bit|32-bit' || echo "Unknown"
  else
    echo "${COLOR_YELLOW}⚠️ $bin not found${COLOR_RESET}"
  fi
done

# ========== Wine Version ==========
echo -e "\n${COLOR_BLUE}🍷 Wine Version${COLOR_RESET}"
wine --version || echo "${COLOR_YELLOW}⚠️ wine failed to report version${COLOR_RESET}"

# ========== Wine Prefix Info ==========
echo -e "\n${COLOR_BLUE}📁 Wine Prefix Info${COLOR_RESET}"
WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
echo "WINEPREFIX = $WINEPREFIX"
[[ -d "$WINEPREFIX" ]] || echo "${COLOR_YELLOW}⚠️ WINEPREFIX not found${COLOR_RESET}"
[[ -f "$WINEPREFIX/system.reg" ]] || echo "${COLOR_YELLOW}⚠️ system.reg not found${COLOR_RESET}"
grep -i 'winearch' "$WINEPREFIX/system.reg" || echo "${COLOR_YELLOW}⚠️ 'winearch' not found in system.reg${COLOR_RESET}"

# ========== VRising Process ==========
echo -e "\n${COLOR_BLUE}🚀 Checking VRising Process Info${COLOR_RESET}"
VRISING_PID=$(pgrep -f VRisingServer.exe | head -n1 || true)
VRISING_BITNESS="unknown"
VRISING_TOP_ADDR="unknown"

if [[ -n "$VRISING_PID" ]]; then
  echo "✅ VRisingServer.exe is running with PID $VRISING_PID"
  EXE_PATH=$(readlink -f "/proc/$VRISING_PID/exe")
  echo "🧵 Executable Path: $EXE_PATH"
  VRISING_BITNESS=$(file "$EXE_PATH" | grep -Eo '64-bit|32-bit' || echo "unknown")
  echo "🧬 Binary Architecture: $VRISING_BITNESS"

  echo -e "\n📊 Top 20 Memory Mappings:"
  FIRST_LINE=$(head -n 1 "/proc/$VRISING_PID/maps")
  VRISING_TOP_ADDR=$(echo "$FIRST_LINE" | cut -d'-' -f1)
  echo "$FIRST_LINE"

  echo -n "🧠 Top memory address: $VRISING_TOP_ADDR "
  if [[ "$VRISING_TOP_ADDR" =~ ^[0-7][0-9a-f]{7,}$ ]]; then
    echo "${COLOR_GREEN}✅ likely 64-bit${COLOR_RESET}"
  else
    echo "${COLOR_RED}❌ low memory region${COLOR_RESET}"
  fi

  echo -e "\n📐 Memory Map Range Analysis"
  MAX_ADDR=$(awk '{print $1}' "/proc/$VRISING_PID/maps" | cut -d'-' -f2 | sort | tail -n1)
  echo "📈 Highest mapped address: $MAX_ADDR"

  echo -e "\n📜 Memory Map Snapshot (looking for 32-bit libs)"
  BIN_COUNT=0
  MATCH_COUNT=0

  grep -E 'wine|\.dll' "/proc/$VRISING_PID/maps" | while read -r line; do
    bin=$(echo "$line" | awk '{print $6}')
    echo "🔍 Scanning: $bin"
    [[ -z "$bin" || ! -f "$bin" ]] && continue
    BIN_COUNT=$((BIN_COUNT + 1))
    if file "$bin" | grep -q "32-bit"; then
      echo -e "${COLOR_RED}❗ 32-bit binary loaded: $bin${COLOR_RESET}"
      MATCH_COUNT=$((MATCH_COUNT + 1))
    fi
  done

  echo -e "\n🧮 Summary:"
  echo "   Total binaries scanned: $BIN_COUNT"
  echo "   32-bit matches found:   $MATCH_COUNT"

  echo -e "\n📊 Total RSS (from smaps)"
  RSS_KB=$(awk '/^Rss:/ { sum += $2 } END { print sum }' "/proc/$VRISING_PID/smaps")
  RSS_MB=$(awk "BEGIN { printf \"%.2f\", $RSS_KB / 1024 }")
  echo "📦 Resident Set Size: ${RSS_MB} MB"

  if (( RSS_KB > 4 * 1024 * 1024 )); then
    echo "${COLOR_GREEN}✅ Over 4GB — 64-bit memory usage confirmed${COLOR_RESET}"
  elif (( RSS_KB > 2 * 1024 * 1024 )); then
    echo "${COLOR_YELLOW}⚠️ Moderate memory use, not yet at ceiling${COLOR_RESET}"
  else
    echo "${COLOR_RED}❗ Low memory use, may not be allocating freely${COLOR_RESET}"
  fi
else
  echo "${COLOR_YELLOW}⚠️ VRisingServer.exe not running${COLOR_RESET}"
fi

# ========== In-Process Alloc Test ==========
echo -e "\n${COLOR_BLUE}🧪 In-Wine Allocation Test${COLOR_RESET}"
TEST_DIR=$(mktemp -d)
cp "$ALLOC_TEST_SOURCE" "$TEST_DIR/"
cd "$TEST_DIR"
x86_64-w64-mingw32-gcc alloc_test.c -o alloc_test.exe
ALLOC_OUTPUT=$(WINEPREFIX="$WINEPREFIX" wine ./alloc_test.exe 2>&1 || true)
echo "$ALLOC_OUTPUT"
cd /
rm -rf "$TEST_DIR"

# ========== Final Verdict ==========
echo -e "\n${COLOR_BLUE}📊 FINAL VERDICT${COLOR_RESET}"
echo "VRising binary:          $VRISING_BITNESS"
echo "Top memory mapping:      $VRISING_TOP_ADDR"
echo "Wine:                    $(file "$(command -v wine)" | grep -Eo '64-bit|32-bit' || echo "Unknown")"
echo "Wineserver:              $(file "$(command -v wineserver)" | grep -Eo '64-bit|32-bit' || echo "Unknown")"

if echo "$ALLOC_OUTPUT" | grep -q "✅ VirtualAlloc succeeded"; then
  echo "${COLOR_GREEN}🧠 Allocation Test Passed${COLOR_RESET}"
else
  echo "${COLOR_RED}❌ Allocation Test Failed${COLOR_RESET}"
fi

echo -e "\n🗂️ Log saved to: $LOG_FILE"
