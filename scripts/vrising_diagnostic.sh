#!/bin/bash
set -euo pipefail

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
for file in memory.max memory.swap.max memory.high memory.current; do
  path="/sys/fs/cgroup/$file"
  [[ -f "$path" ]] && echo "$file: $(cat $path)"
done

# ========== Wine Binary Architecture ==========
echo -e "\n${COLOR_BLUE}🧩 Wine Binary Architecture Check${COLOR_RESET}"
check_binary_arch() {
  local bin="$1"
  if command -v "$bin" &>/dev/null; then
    echo -n "🔎 $bin: "
    file "$(command -v "$bin")" | grep -Eo '64-bit|32-bit' || echo "Unknown"
  else
    echo "${COLOR_YELLOW}⚠️ $bin not found${COLOR_RESET}"
  fi
}
check_binary_arch wine
check_binary_arch wine64
check_binary_arch wineserver

# ========== Wine Version ==========
echo -e "\n${COLOR_BLUE}🍷 Wine Version${COLOR_RESET}"
wine --version || echo "${COLOR_YELLOW}⚠️ wine failed to report version${COLOR_RESET}"

# ========== Wine Prefix ==========
echo -e "\n${COLOR_BLUE}📁 Wine Prefix Info${COLOR_RESET}"
WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
echo "WINEPREFIX = $WINEPREFIX"
[[ -d "$WINEPREFIX" ]] || echo "${COLOR_YELLOW}⚠️ WINEPREFIX not found${COLOR_RESET}"

if [[ -f "$WINEPREFIX/system.reg" ]]; then
  grep -i 'winearch' "$WINEPREFIX/system.reg" || echo "${COLOR_YELLOW}⚠️ 'winearch' not found in system.reg${COLOR_RESET}"
else
  echo "${COLOR_YELLOW}⚠️ system.reg not found in $WINEPREFIX${COLOR_RESET}"
fi

# ========== VRising Process ==========
echo -e "\n${COLOR_BLUE}🚀 Checking VRising Process Info${COLOR_RESET}"
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
    echo "${COLOR_GREEN}✅ (high memory region, likely 64-bit)${COLOR_RESET}"
  else
    echo "${COLOR_RED}❌ (low memory region, suspicious)${COLOR_RESET}"
  fi

  echo -e "\n📐 Full VRising Memory Map Range Analysis"
  MAX_ADDR=$(awk '{print $1}' "/proc/$VRISING_PID/maps" | cut -d'-' -f2 | sort -n | tail -n1)
  echo "📈 Highest mapped address: $MAX_ADDR"

  echo -e "\n📜 Memory Map Snapshot (looking for 32-bit lib contamination):"

  total_lines=0
  skipped_missing=0
  skipped_unreadable=0
  scanned_files=0
  found_32bit=0

  grep -E 'wine|\.dll' "/proc/$VRISING_PID/maps" | while read -r line; do
    ((total_lines++))
    bin=$(echo "$line" | awk '{print $6}')

    if [[ -z "$bin" ]]; then
      ((skipped_missing++))
      continue
    fi

    if [[ ! -r "$bin" ]]; then
      ((skipped_unreadable++))
      continue
    fi

    ((scanned_files++))
    if file "$bin" 2>/dev/null | grep -q "32-bit"; then
      ((found_32bit++))
      echo "${COLOR_RED}❗ 32-bit binary loaded: $bin${COLOR_RESET}"
    fi
  done

  # Final summary
  echo -e "\n🧾 ${COLOR_BOLD}Contamination Scan Summary:${COLOR_RESET}"
  echo "🔢 Total matching lines:       $total_lines"
  echo "🚫 Skipped (missing path):     $skipped_missing"
  echo "🚫 Skipped (unreadable path):  $skipped_unreadable"
  echo "🔍 Scanned with 'file':        $scanned_files"
  echo -n "❗ Found 32-bit binaries:      "
  if [[ "$found_32bit" -gt 0 ]]; then
    echo "${COLOR_RED}$found_32bit${COLOR_RESET}"
  else
    echo "${COLOR_GREEN}0${COLOR_RESET}"
  fi

  echo -e "\n📊 Total Resident Set Size (from smaps):"
  awk '/^Rss:/ { total += $2 } END { printf "Total: %.2f MB\n", total / 1024 }' "/proc/$VRISING_PID/smaps"

  # === Summary verdict on actual memory usage ===
  echo -e "\n${COLOR_BLUE}📈 Memory Usage Summary${COLOR_RESET}"
  VRISING_RSS_KB=$(awk '/^Rss:/ { total += $2 } END { print total }' "/proc/$VRISING_PID/smaps")
  VRISING_RSS_MB=$(awk "BEGIN { printf \"%.2f\", $VRISING_RSS_KB / 1024 }")

  echo "📦 Resident Set Size: ${VRISING_RSS_MB} MB"

  if (( VRISING_RSS_KB > 4 * 1024 * 1024 )); then
    echo "${COLOR_GREEN}✅ Exceeds 4GB — 64-bit memory fully engaged${COLOR_RESET}"
  elif (( VRISING_RSS_KB > 2 * 1024 * 1024 )); then
    echo "${COLOR_YELLOW}⚠️ Moderate usage — game not memory-capped, but hasn't crossed 4GB yet${COLOR_RESET}"
  else
    echo "${COLOR_RED}❗ Low usage — no sign of large memory mapping yet${COLOR_RESET}"
  fi
else
  echo "${COLOR_YELLOW}⚠️ VRisingServer.exe is not currently running${COLOR_RESET}"
fi

# ========== In-Process Alloc Test ==========
echo -e "\n${COLOR_BLUE}🧪 In-Wine Architecture & Memory Sanity Test${COLOR_RESET}"
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

# ========== Summary ==========
echo -e "\n${COLOR_BLUE}📊 FINAL VERDICT${COLOR_RESET}"
STATUS_SUMMARY=()

printf "%-30s %s\n" "VRising binary:" "$VRISING_BITNESS"
[[ "$VRISING_BITNESS" == "64-bit" ]] || STATUS_SUMMARY+=("VRising not 64-bit")

printf "%-30s %s\n" "Top memory mapping:" "$VRISING_TOP_ADDR"
if [[ "$VRISING_TOP_ADDR" =~ ^[0-7][0-9a-f]{7,}$ ]]; then :; else
  STATUS_SUMMARY+=("Top memory address too low")
fi

printf "%-30s " "Wine binary:"
file "$(command -v wine)" | grep -q "64-bit" && echo "${COLOR_GREEN}✅ 64-bit${COLOR_RESET}" || { echo "${COLOR_RED}❌ Not 64-bit${COLOR_RESET}"; STATUS_SUMMARY+=("wine not 64-bit"); }

printf "%-30s " "Wineserver:"
command -v wineserver &>/dev/null && file "$(command -v wineserver)" | grep -q "64-bit" && echo "${COLOR_GREEN}✅ 64-bit${COLOR_RESET}" || { echo "${COLOR_RED}❌ Not 64-bit${COLOR_RESET}"; STATUS_SUMMARY+=("wineserver not 64-bit"); }

if echo "$ALLOC_RESULT" | grep -q "✅ VirtualAlloc succeeded"; then
  echo "🧠 Memory allocation test: ${COLOR_GREEN}✅ Passed${COLOR_RESET}"
else
  echo "🧠 Memory allocation test: ${COLOR_RED}❌ Failed${COLOR_RESET}"
  STATUS_SUMMARY+=("alloc test failed")
fi

echo -e "\n🗂️ Diagnostics log saved to: $LOG_FILE"

# ========== One-Liner ==========
echo -e "\n${COLOR_BOLD}🎯 One-Liner Summary:${COLOR_RESET}"
if [[ "${#STATUS_SUMMARY[@]}" -eq 0 ]]; then
  echo "${COLOR_GREEN}ALL CHECKS PASSED ✅${COLOR_RESET}"
else
  echo "${COLOR_RED}ISSUES DETECTED ⚠️ — ${STATUS_SUMMARY[*]}${COLOR_RESET}"
fi
