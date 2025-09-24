#!/bin/zsh
set -euo pipefail

# Heuristic staleness checker: flags markdown files under docs/ not touched in the last N days.
# Usage: DAYS=60 zsh Scripts/check-doc-staleness.sh

DAYS=${DAYS:-60}
ROOT="docs"

if [[ ! -d "$ROOT" ]]; then
  echo "No docs directory present." >&2
  exit 0
fi

echo "🔎 Scanning $ROOT for files not modified in the last $DAYS days..."

# Find markdown files and print those older than threshold
STale=$(find "$ROOT" -type f -name "*.md" -mtime +$DAYS | sort || true)

if [[ -z "$STale" ]]; then
  echo "✅ No stale markdown files older than $DAYS days."
  exit 0
fi

echo "⚠️ Potentially stale files (>$DAYS days):"
echo "$STale"

# Exit with non-zero to surface in CI (optional: set NO_FAIL=1 to only warn)
if [[ "${NO_FAIL:-0}" == "1" ]]; then
  exit 0
else
  exit 2
fi
