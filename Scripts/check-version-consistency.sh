#!/bin/zsh
set -euo pipefail

# Ensures VERSION and CHANGELOG.md top unreleased/release section are consistent with an optional TAG env.
# Usage:
#   zsh Scripts/check-version-consistency.sh
#   TAG=v6.0.1 zsh Scripts/check-version-consistency.sh

TAG=${TAG:-}
VERSION_FILE="VERSION"
CHANGELOG="CHANGELOG.md"

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "❌ VERSION file missing"
  exit 1
fi

VER=$(cat "$VERSION_FILE" | tr -d '\n' | tr -d '\r')
if [[ -z "$VER" ]]; then
  echo "❌ VERSION file empty"
  exit 1
fi

echo "📦 VERSION file: $VER"

if [[ ! -f "$CHANGELOG" ]]; then
  echo "❌ CHANGELOG.md missing"
  exit 1
fi

# Look for a section like: ## [x.y.z]
if ! grep -E "^## \[$VER\]" "$CHANGELOG" >/dev/null; then
  echo "⚠️ CHANGELOG.md does not contain section for [$VER]"
  exit 2
else
  echo "✅ CHANGELOG contains section for [$VER]"
fi

if [[ -n "$TAG" ]]; then
  if [[ "$TAG" != v$VER ]]; then
    echo "⚠️ TAG ($TAG) does not match VERSION (v$VER)"
    exit 3
  else
    echo "✅ TAG matches VERSION"
  fi
fi
