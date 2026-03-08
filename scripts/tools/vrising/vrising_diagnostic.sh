#!/usr/bin/env bash
# Run this remotely to get a diagnostic of VRising dependencies.
# Safe to run while VRising is live — read-only except for the alloc test compile.
set -uo pipefail

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

# Install mingw compiler if not already present
command -v x86_64-w64-mingw32-gcc &>/dev/null \
  || sudo apt install -y gcc-mingw-w64-x86-64

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
for file in memory.max memory.swap.max memory.high memory.current; do
  path=$(find /sys/fs/cgroup -type f -name "$file" 2>/dev/null | head -n1)
  if [[ -n "$path" && -f "$path" ]]; then
    echo "$file: $(cat "$path")"
  else
    echo "${COLOR_YELLOW}⚠️ $file not found in any known cgroup path${COLOR_RESET}"
  fi
done

# ========== Wine Binary Architecture ==========
echo -e "\n${COLOR_BLUE}🧩 Wine Binary Architecture Check${COLOR_RESET}"

# Show everything in the WineHQ install dir so version upgrades are visible
echo "ℹ️ /opt/wine-stable/bin/ contents:"
ls /opt/wine-stable/bin/ 2>/dev/null || echo "${COLOR_YELLOW}⚠️ /opt/wine-stable/bin/ not found${COLOR_RESET}"

# Check both the WineHQ explicit path and whatever 'wine' resolves to in PATH —
# they should match; if they don't, something is shadowing WineHQ's wine.
for bin in wine wineserver; do
  echo ""
  WINEHQ_BIN="/opt/wine-stable/bin/$bin"
  PATH_BIN=$(command -v "$bin" 2>/dev/null || true)
  PATH_REAL=$(realpath "$PATH_BIN" 2>/dev/null || echo "")

  echo "🔎 $bin:"
  echo "   WineHQ path : $WINEHQ_BIN"
  echo "   PATH resolves to: ${PATH_BIN:-not found} -> ${PATH_REAL:-}"

  if [[ -n "$PATH_REAL" && "$PATH_REAL" != "$WINEHQ_BIN" ]]; then
    echo "   ${COLOR_YELLOW}⚠️ PATH wine differs from WineHQ path — may be using wrong version${COLOR_RESET}"
  fi

  TARGET="${WINEHQ_BIN}"
  if [[ ! -x "$TARGET" ]]; then
    echo "   ${COLOR_RED}❗ $TARGET not executable or missing${COLOR_RESET}"
    continue
  fi

  TYPE_LINE=$(file "$TARGET" 2>/dev/null || echo "unreadable")
  TYPE=$(echo "$TYPE_LINE" | grep -Eo '64-bit|32-bit' || true)

  if [[ -z "$TYPE" ]]; then
    echo "   ${COLOR_YELLOW}⚠️ could not determine architecture — possibly a shell wrapper or script${COLOR_RESET}"
    echo "   file output: $TYPE_LINE"
  else
    echo "   file output: $TYPE_LINE"
    echo "   parsed type: $TYPE"
    if [[ "$TYPE" != "64-bit" ]]; then
      echo "   ${COLOR_RED}❗ $bin is not 64-bit — may prevent VRising from using full memory space${COLOR_RESET}"
    fi
  fi
done

# ========== Wine Version ==========
echo -e "\n${COLOR_BLUE}🍷 Wine Version${COLOR_RESET}"
wine --version || echo "${COLOR_YELLOW}⚠️ wine failed to report version${COLOR_RESET}"

# ========== Wine Prefix Info ==========
echo -e "\n${COLOR_BLUE}📁 Wine Prefix Info${COLOR_RESET}"
WINEPREFIX="${WINEPREFIX:-/home/bwinter_sc81/.wine64}"
echo "WINEPREFIX = $WINEPREFIX"

if [[ ! -d "$WINEPREFIX" ]]; then
  echo "${COLOR_YELLOW}⚠️ WINEPREFIX not found. It will be auto-created by Wine.${COLOR_RESET}"
else
  [[ -f "$WINEPREFIX/system.reg" ]] || echo "${COLOR_YELLOW}⚠️ system.reg not found${COLOR_RESET}"
  grep -i 'winearch' "$WINEPREFIX/system.reg" \
    || echo "${COLOR_YELLOW}⚠️ 'winearch' not found in system.reg — not necessarily a problem${COLOR_RESET}" \
    || true
fi

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

  echo -e "\n📊 Memory Mapping Range Overview:"
  VRISING_TOP_ADDR=$(awk '{print $1}' "/proc/$VRISING_PID/maps" | cut -d'-' -f1 | sort | tail -n1)
  echo "🔍 Highest mapping base address: $VRISING_TOP_ADDR"

  if [[ "$VRISING_TOP_ADDR" =~ ^[0-9a-fA-F]+$ ]]; then
    ADDR_DEC=$(printf "%u\n" 0x$VRISING_TOP_ADDR 2>/dev/null || echo "0")
    echo -n "🧠 Address interpreted as decimal: $ADDR_DEC — "
    if [[ "$ADDR_DEC" -gt 4294967295 ]]; then
      echo "${COLOR_GREEN}✅ exceeds 0xFFFFFFFF — confirms 64-bit address space${COLOR_RESET}"
    else
      echo "${COLOR_RED}❌ under 0xFFFFFFFF — may indicate 32-bit environment${COLOR_RESET}"
    fi
  else
    echo "${COLOR_YELLOW}⚠️ could not parse top memory address — malformed value${COLOR_RESET}"
  fi

  echo -e "\n📐 Memory Map Range Analysis"
  MAX_ADDR=$(awk '{print $1}' "/proc/$VRISING_PID/maps" | cut -d'-' -f2 | sort | tail -n1)
  echo "📈 Highest mapped address: $MAX_ADDR"

  echo -e "\n📜 Memory Map Snapshot (looking for 32-bit libs)"
  FOUND_32=0
  while read -r bin; do
    echo "🔍 Scanning: $bin"
    if [[ -n "$bin" && -f "$bin" ]]; then
      if file "$bin" | grep -q "32-bit"; then
        echo "${COLOR_RED}❗ 32-bit binary loaded: $bin${COLOR_RESET}"
        (( FOUND_32++ )) || true
      fi
    fi
  done < <(grep -E 'wine|\.dll' "/proc/$VRISING_PID/maps" | awk '{print $6}' | sort -u)
  echo "🔬 Total 32-bit artifacts found: $FOUND_32"

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
  echo "${COLOR_YELLOW}⚠️ VRisingServer.exe not running — skipping process checks${COLOR_RESET}"
fi

# ========== In-Process Alloc Test ==========
echo -e "\n${COLOR_BLUE}🧪 In-Wine Allocation Test${COLOR_RESET}"
ALLOC_OUTPUT=$(
  cd "$(mktemp -d)"
  cp "$ALLOC_TEST_SOURCE" .
  x86_64-w64-mingw32-gcc alloc_test.c -o alloc_test.exe
  WINEDEBUG=-all WINEPREFIX="$WINEPREFIX" wine ./alloc_test.exe 2>&1 || true
)
echo "$ALLOC_OUTPUT"

ALLOC_OK=$(echo "$ALLOC_OUTPUT" | grep -c "VirtualAlloc of 6GB succeeded")

# ========== Final Verdict ==========
echo -e "\n${COLOR_BLUE}📊 FINAL VERDICT${COLOR_RESET}"
echo "VRising binary:          $VRISING_BITNESS"
echo "Top memory mapping:      $VRISING_TOP_ADDR"
echo "Wine (PATH):             $(realpath "$(command -v wine)" 2>/dev/null || echo "Unknown")"
echo "Wine (WineHQ):           /opt/wine-stable/bin/wine"
echo "Wineserver:              $(realpath "$(command -v wineserver)" 2>/dev/null || echo "Unknown")"

if [[ "$ALLOC_OK" -gt 0 ]]; then
  echo "${COLOR_GREEN}🧠 Allocation Test Passed — 64-bit heap available${COLOR_RESET}"
else
  echo "${COLOR_RED}❌ Allocation Test Failed — in-process 64-bit alloc may be blocked${COLOR_RESET}"
fi

echo -e "\n🗂️ Log saved to: $LOG_FILE"