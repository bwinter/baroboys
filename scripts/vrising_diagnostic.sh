#!/usr/bin/env bash
# VRising Dedicated Server Memory Diagnostic Script
# This script gathers system info and runs tests to diagnose a ~4GB memory cap issue under Wine.
# Run as root (or with sudo) for best results, and ensure the VRising server is not running (or be ready to stop it when prompted).

log() { echo -e "\033[1;34m🔍 $*\033[0m"; }

WINE_BIN="$(readlink -f "$(which wine)")"
WINE_LOADER="$(readlink -f /proc/$(pgrep -f VRisingServer.exe | head -n1)/exe)"
WINE_PREFIX="${WINEPREFIX:-$HOME/.wine}"

log "Wine binary in use: $WINE_BIN"
log "Wine preloader in use: $WINE_LOADER"
log "Wine prefix: $WINE_PREFIX"

if [[ "$WINE_LOADER" =~ wine-preloader$ ]]; then
  echo "⚠️  Wine is running with 32-bit preloader!"
else
  echo "✅ Wine is using 64-bit preloader"
fi

if [[ -d "$WINE_PREFIX/drive_c/windows/syswow64" ]]; then
  echo "⚠️  Wine prefix contains syswow64 → likely 32-bit or WOW64 mixed mode"
else
  echo "✅ Wine prefix lacks syswow64 → likely pure 64-bit"
fi

# Confirm Windows architecture inside Wine
wine64 reg query "HKLM\\System\\CurrentControlSet\\Control\\Session Manager\\Environment" | grep PROCESSOR_ARCHITECTURE || echo "⚠️  Could not read processor architecture"

log "Wine binary: $(readlink -f $(which wine))"
log "Wine preloader: $(readlink -f /proc/$(pgrep -f VRisingServer.exe | head -n1)/exe)"
log "Wine prefix: ${WINEPREFIX:-$HOME/.wine}"

if [[ "$(readlink -f /proc/$(pgrep -f VRisingServer.exe | head -n1)/exe)" =~ wine-preloader$ ]]; then
  echo "⚠️ Wine is running in 32-bit mode!"
else
  echo "✅ Wine is 64-bit"
fi

[[ -e "$WINEPREFIX/drive_c/windows/syswow64/kernel32.dll" ]] && echo "⚠️ syswow64 found — likely 32-bit or WOW64 mixed mode"

# 1. Ensure required tools are installed (smem, gdb, file, gcc, mingw-w64, etc.)
REQUIRED_TOOLS=("smem" "gdb" "file" "gcc")
MINGW_TOOL="x86_64-w64-mingw32-gcc"  # Check presence of MinGW-w64 cross-compiler

# Check for root or sudo access for installing packages
if [[ $EUID -ne 0 ]]; then
  if ! command -v sudo &>/dev/null; then
    echo "ERROR: This script needs to install packages. Run as root or install sudo."
    exit 1
  fi
  SUDO="sudo"
else
  SUDO=""
fi

# Prepare list of packages to install
packages_to_install=""
for tool in "${REQUIRED_TOOLS[@]}"; do
  if ! command -v "$tool" &>/dev/null; then
    packages_to_install+="$tool "
  fi
done
if ! command -v "$MINGW_TOOL" &>/dev/null; then
  packages_to_install+="mingw-w64 "
fi

# Install missing packages if any
if [[ -n "$packages_to_install" ]]; then
  echo "Installing required packages: $packages_to_install"
  $SUDO apt-get update -y && $SUDO apt-get install -y $packages_to_install
fi

# 2. Set up logging to file and stdout
LOGFILE="vrising_debug_$(date +%Y%m%d_%H%M%S).log"
echo "Logging output to $LOGFILE"
# Tee all output to LOGFILE (both stdout and stderr)
exec > >(tee -a "$LOGFILE") 2>&1

echo "=== VRising Wine Memory Diagnostic ==="
echo "Start time: $(date)"
echo

# 3. Log system environment info (CPU, kernel, RAM, ulimits, cgroups)
echo "## System Information"
echo "CPU Architecture: $(uname -m)"
echo "Kernel Version: $(uname -r)"
# Total RAM from /proc/meminfo (convert kB to GB)
MemKB=$(grep -m1 'MemTotal:' /proc/meminfo | awk '{print $2}')
if [[ -n "$MemKB" ]]; then
  MemGB=$(awk "BEGIN {printf \"%.2f\", $MemKB/1024/1024}")
  echo "Total RAM: $MemGB GB"
fi
# Ulimits
echo -e "\n**Ulimit Settings:**"
ulimit -a
# Cgroup info
echo -e "\n**Cgroup Settings:**"
if grep -q '0::' /proc/self/cgroup; then
  # Cgroup v2 unified hierarchy
  CGPATH=$(awk -F: '/0::/ {print $3}' /proc/self/cgroup)
  [[ -z "$CGPATH" ]] && CGPATH="/"  # root cgroup
  echo "Cgroup path: $CGPATH"
  if [[ -f "/sys/fs/cgroup$CGPATH/memory.max" ]]; then
    echo "memory.max = $(cat /sys/fs/cgroup$CGPATH/memory.max)"
  fi
  if [[ -f "/sys/fs/cgroup$CGPATH/memory.current" ]]; then
    echo "memory.current = $(cat /sys/fs/cgroup$CGPATH/memory.current)"
  fi
else
  # Cgroup v1 (or hybrid)
  awk -F: '$2 == "memory" {print "cgroup (memory) path: "$3}' /proc/self/cgroup
  MEM_CG=$(awk -F: '$2 == "memory" {print $3}' /proc/self/cgroup)
  if [[ -n "$MEM_CG" ]]; then
    if [[ -f "/sys/fs/cgroup/memory/$MEM_CG/memory.limit_in_bytes" ]]; then
      limit=$(cat "/sys/fs/cgroup/memory/$MEM_CG/memory.limit_in_bytes")
      # If the limit is a very large number or "max", output accordingly
      if [[ "$limit" =~ ^[0-9]+$ ]]; then
        if [[ "$limit" -ge 1099511627776 ]]; then  # >= 1 TB, likely no real limit (uses max or very high)
          echo "memory.limit_in_bytes = $limit (no practical limit or maximum set)"
        else
          human_limit=$(awk "BEGIN {printf \"%.2f GB\", $limit/1024/1024/1024}")
          echo "memory.limit_in_bytes = $limit (~$human_limit)"
        fi
      else
        echo "memory.limit_in_bytes = $limit"
      fi
    fi
    if [[ -f "/sys/fs/cgroup/memory/$MEM_CG/memory.usage_in_bytes" ]]; then
      usage=$(cat "/sys/fs/cgroup/memory/$MEM_CG/memory.usage_in_bytes")
      human_usage=$(awk "BEGIN {printf \"%.2f GB\", $usage/1024/1024/1024}")
      echo "memory.usage_in_bytes = $usage (~$human_usage used)"
    fi
  fi
fi
echo

# Show WINE version and paths
if command -v wine &>/dev/null; then
  WINE_PATH=$(readlink -f "$(command -v wine)")
  echo "**Wine version:** $(wine --version) (binary: $WINE_PATH)"
  # Determine wine64 binary and preloader paths if possible
  if command -v wine64 &>/dev/null; then
    echo "Wine64 binary: $(readlink -f "$(command -v wine64)")"
  fi
  # wine64-preloader might not be in PATH, try to locate via wine binary directory
  wine_bin_dir=$(dirname "$WINE_PATH")
  if [[ -f "$wine_bin_dir/wine64-preloader" ]]; then
    echo "Wine64-preloader: $wine_bin_dir/wine64-preloader"
  else
    # Try common location
    if [[ -f "/usr/lib/x86_64-linux-gnu/wine/wine64-preloader" ]]; then
      echo "Wine64-preloader: /usr/lib/x86_64-linux-gnu/wine/wine64-preloader"
    fi
  fi
else
  echo "ERROR: Wine is not installed or not in PATH."
fi

# Note about WINEPREFIX usage
if [[ -n "$WINEPREFIX" ]]; then
  echo "Using WINEPREFIX: $WINEPREFIX"
else
  echo "Using default WINEPREFIX (~/.wine). If VRising runs in a custom prefix, set WINEPREFIX before running this script."
fi

if [[ -d "${WINEPREFIX:-$HOME/.wine}/drive_c" ]]; then
  echo -n "Wine prefix architecture: "
  if [[ -f "${WINEPREFIX:-$HOME/.wine}/system.reg" ]]; then
    if grep -q 'winearch"="win64' "${WINEPREFIX:-$HOME/.wine}/system.reg"; then
      echo "64-bit (win64)"
    else
      echo "32-bit (likely)"
    fi
  fi
fi

echo -e "\n## Process Checks"
# 4. Check if VRising server is running
VRisingPIDs=$(pgrep -f -i "VRisingServer.exe")
if [[ -n "$VRisingPIDs" ]]; then
  echo "VRising server appears to be RUNNING (PID(s): $VRisingPIDs). Gathering info..."

  declare -A VRisingCmdlines
  for pid in $VRisingPIDs; do
    if [[ -r "/proc/$pid/cmdline" ]]; then
      VRisingCmdlines["$pid"]="$(tr '\0' ' ' < "/proc/$pid/cmdline")"
    fi
  done

  # Loop through each VRising-related PID found
  for pid in $VRisingPIDs; do
    # Basic process info
    proc_name=$(ps -p $pid -o comm=)
    echo -e "\nProcess $pid -> $proc_name"
    ps -p $pid -o pid,ppid,cmd --width 200
    # Dump /proc/<pid>/status
    echo "--- /proc/$pid/status ---"
    cat /proc/$pid/status
    # Memory usage summary with pmap
    if command -v pmap &>/dev/null; then
      pmap_out=$(pmap -x $pid | tail -1)
      if [[ $pmap_out == total* ]]; then
        # pmap summary line format: "total kB   RSS   Dirty"
        # shellcheck disable=SC2086  # (we want word splitting for $pmap_out)
        set -- $pmap_out
        # $1 = "total", $2 = totalKB, $3 = totalRSS, $4 = totalDirty (all in KB)
        shift
        totalKB=$1; totalRSS=$2
        totalMB=$((totalKB/1024))
        rssMB=$((totalRSS/1024))
        echo "Memory usage (pmap): VM ~$totalMB MB, RSS ~$rssMB MB"
      fi
    fi
  done

  # Also capture wineserver process info if present
  WineServerPID=$(pgrep -x wineserver)
  if [[ -n "$WineServerPID" ]]; then
    echo -e "\nProcess $WineServerPID -> wineserver (Wine background service)"
    ps -p $WineServerPID -o pid,ppid,cmd
    echo "--- /proc/$WineServerPID/status ---"
    cat /proc/$WineServerPID/status
  fi

  # Suggest shutting down VRising before proceeding
  echo -e "\n*** Please shut down the VRising server before continuing with Wine tests. ***"
  read -rp "Press Enter after VRising is stopped (or Ctrl+C to abort)..." _
  # Wait until process is gone
  while pgrep -f -i "VRisingServer.exe" &>/dev/null; do
    echo "VRising still running... please terminate it to continue."
    sleep 5
  done
  echo "VRising server is now stopped. Proceeding with tests..."
else
  echo "VRising server is NOT running (no process found). Proceeding with environment tests..."
fi

# 5. Verify VRisingServer.exe is 64-bit using 'file' (if path is known)
VR_EXE_PATH=""
if [[ -n "$VRisingPIDs" ]]; then
  for pid in $VRisingPIDs; do
    # Safely read cmdline
    if [[ -r "/proc/$pid/cmdline" ]]; then
      cmdline=$(tr '\0' ' ' < "/proc/$pid/cmdline")
      if [[ "$cmdline" == *VRisingServer.exe* ]]; then
        VR_EXE_PATH=$(grep -aoE '/.*VRisingServer.exe' <<< "$cmdline" | head -1)
        if [[ -n "$VR_EXE_PATH" && -f "$VR_EXE_PATH" ]]; then
          break
        fi
      fi
    fi

    # Fallback: check working directory
    if [[ -z "$VR_EXE_PATH" && -L "/proc/$pid/cwd" ]]; then
      cwd=$(readlink -f "/proc/$pid/cwd")
      if [[ -f "$cwd/VRisingServer.exe" ]]; then
        VR_EXE_PATH="$cwd/VRisingServer.exe"
        break
      fi
    fi
  done
fi

# If not found, prompt the user for the path
if [[ -z "$VR_EXE_PATH" ]]; then
  read -rp "Enter the path to VRisingServer.exe (if known, for 64-bit verification, or press Enter to skip): " VR_EXE_PATH
fi

if [[ -n "$VR_EXE_PATH" && -f "$VR_EXE_PATH" ]]; then
  echo -e "\nFile information for VRisingServer.exe:"
  file "$VR_EXE_PATH"
else
  echo -e "\n(SKIPPING 'file' check for VRisingServer.exe – path not provided or file not found.)"
fi

# Check Wine loader architecture (wine64-preloader vs wine-preloader)
if command -v wine64 &>/dev/null; then
  # The presence of wine64 implies 64-bit Wine. Check if 32-bit Wine is also present.
  if command -v wine32 &>/dev/null || [[ -f "$(dirname "$(command -v wine)")/wine-preloader" ]]; then
    echo "Wine multiarch: Both 64-bit and 32-bit Wine components are installed."
  else
    echo "Wine is 64-bit only (no 32-bit preloader found)."
  fi
else
  echo "WARNING: 'wine64' command not found. This may indicate a 32-bit Wine installation!"
fi

# 6. Compile and run a test program to allocate ~6GB in Wine
echo -e "\n## Memory Allocation Test (VirtualAlloc ~6GB)"
MINGW_TOOL="x86_64-w64-mingw32-gcc"
TEST_C="/tmp/alloc_test.c"
TEST_EXE="/tmp/alloc_test.exe"

# Write C test file
cat > "$TEST_C" <<'EOF'
#include <windows.h>
#include <stdio.h>
int main() {
    SIZE_T size = 6LL * 1024 * 1024 * 1024; // 6GB
    void *p = VirtualAlloc(NULL, size, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
    if (p) {
        printf("✅ Successfully allocated %lld bytes (~6GB)\n", (long long)size);
        VirtualFree(p, 0, MEM_RELEASE);
        return 0;
    } else {
        printf("❌ Allocation failed\n");
        return 1;
    }
}
EOF

# Compile and run
if ! command -v "$MINGW_TOOL" &>/dev/null; then
  echo "MinGW-w64 compiler ($MINGW_TOOL) not found, skipping compilation of test program."
else
  echo "Compiling 64-bit Windows test program (using MinGW-w64)..."
  "$MINGW_TOOL" -O2 -static -o "$TEST_EXE" "$TEST_C" 2>&1
  if [[ -f "$TEST_EXE" ]]; then
    echo "Running memory allocation test under Wine..."
    env XDG_RUNTIME_DIR=/tmp WINEDLLOVERRIDES="mscoree,mshtml=" WINEDEBUG=-all wine "$TEST_EXE"
    test_exit=$?
    if [[ $test_exit -ne 0 ]]; then
      echo "Test program exited with code $test_exit (a non-zero code likely indicates the allocation failed or an error occurred)."
    fi
  else
    echo "Compilation failed: $TEST_EXE was not created. (Please check mingw-w64 installation.)"
  fi
fi

# Clean up test files (optional)
rm -f "$TEST_C" "$TEST_EXE"

# 7. TODO: Suggest further investigations
echo -e "\n## TODO / Next Steps"
echo "If the issue remains unresolved, consider the following next steps:"
echo "- **Try Proton:** Run the server using Proton (Steam's Wine variant) to see if the memory cap persists, as Proton may handle memory differently."
echo "- **Wine Debug Logs:** Enable detailed Wine logs for memory (e.g., set WINEDEBUG=+heap,+virtual) and then run the server to trace memory allocation calls and potential errors."
echo "- **Memory Tracing:** Use GDB or Wine's built-in debugger to set breakpoints on memory allocation functions (VirtualAlloc, mmap) to trace and understand where the limitation occurs."
echo "- **Different Wine versions:** Test with the latest Wine development release or a patched Wine build. There might be fixes upstream for large memory allocation issues."
echo "- **System Monitoring:** Use tools like 'smem' or 'pmap' during runtime to watch how memory grows and where it plateaus. Consider /proc/\$PID/maps for a detailed memory map of the Wine process."
echo
echo "End of diagnostic script. All information logged to $LOGFILE."
