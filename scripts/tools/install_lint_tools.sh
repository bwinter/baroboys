#!/usr/bin/env bash
set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required to install the repository lint tools." >&2
  exit 1
fi

packages=(ruff markdownlint-cli2 checkmake hadolint)
commands=(ruff markdownlint-cli2 checkmake hadolint)
missing=()
repair=()

for index in "${!packages[@]}"; do
  package="${packages[$index]}"
  command_name="${commands[$index]}"

  if brew list --formula "$package" >/dev/null 2>&1; then
    if ! command -v "$command_name" >/dev/null 2>&1; then
      repair+=("$package")
    fi
  else
    missing+=("$package")
  fi
done

if ((${#missing[@]})); then
  echo "Installing missing lint tools: ${missing[*]}"
  brew install "${missing[@]}"
fi

if ((${#repair[@]})); then
  echo "Repairing incomplete lint tool installs: ${repair[*]}"
  brew reinstall "${repair[@]}"
fi

for command_name in "${commands[@]}"; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Lint tool is still unavailable after installation: $command_name" >&2
    exit 1
  fi
done

echo "Lint tools are available: ${commands[*]}"
