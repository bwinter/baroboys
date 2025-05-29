#!/usr/bin/env bash
set -e

echo "=== 🔍 Environment Diagnostic ==="

# Shell info
echo -e "\n🌀 Shell:"
echo "  Current shell: $SHELL"
echo "  Interactive shell: $0"
ps -p $$ | awk 'NR==2 {print "  Shell process:", $NF}'

# OS info
echo -e "\n🧠 OS:"
uname -a
if [[ -f /etc/os-release ]]; then
  cat /etc/os-release | grep PRETTY_NAME
fi
sw_vers 2>/dev/null || true

# CPU + arch
echo -e "\n🧮 Architecture:"
uname -m
sysctl -n machdep.cpu.brand_string 2>/dev/null || lscpu | grep 'Model name' || true

# Bash version
echo -e "\n🐚 Bash version:"
bash --version | head -n 1

# GNU vs BSD coreutils
echo -e "\n🧪 Coreutils check:"
if tail --version 2>/dev/null | grep -q 'GNU'; then
  echo "  ✅ GNU coreutils detected"
else
  echo "  ⚠️  Possibly BSD coreutils (macOS default?)"
fi

# mapfile support
echo -e "\n📋 mapfile support:"
if bash -c 'mapfile test <<< "hello"' 2>/dev/null; then
  echo "  ✅ mapfile supported"
else
  echo "  ❌ mapfile not supported (probably not bash or non-interactive shell)"
fi

# Common tools
echo -e "\n🛠️  Tool availability:"
for cmd in jq yq awk column tee sed grep gcloud packer terraform make; do
  if command -v "$cmd" >/dev/null; then
    printf "  ✅ %-10s => %s\n" "$cmd" "$(command -v $cmd)"
  else
    printf "  ❌ %-10s not found\n" "$cmd"
  fi
done

# Terminal details
echo -e "\n🖥️  Terminal dimensions:"
echo "  COLUMNS=${COLUMNS:-unset} LINES=${LINES:-unset}"
stty size 2>/dev/null || echo "  stty size unsupported"

echo -e "\n🎉 Done. Paste this output into ChatGPT!"

