#!/bin/zsh
set -euo pipefail

# Simple link checker wrapper using lychee if available.
# Usage: zsh Scripts/check-doc-links.sh

if ! command -v lychee >/dev/null 2>&1; then
  echo "lychee not found. Install via: cargo install lychee" >&2
  exit 127
fi

if [[ -f .lychee.toml ]]; then
  lychee --config .lychee.toml README.md docs/**/*.md
else
  lychee README.md docs/**/*.md
fi
