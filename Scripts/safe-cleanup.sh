#!/bin/zsh

set -euo pipefail

echo "🧹 NotBad Safe Cleanup"
echo "====================="

BACKUP_DIR="cleanup-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Cleaning .DS_Store files..."
find . -name ".DS_Store" -type f -print -exec mv {} "$BACKUP_DIR/" \; 2>/dev/null || true

echo "Cleaning temporary files (*.tmp, *.bak)..."
find . -type f \( -name "*.tmp" -o -name "*.bak" \) -print -exec mv {} "$BACKUP_DIR/" \; 2>/dev/null || true

echo "Cleaning DerivedData..."
find . -path "*/DerivedData/*" -print -exec rm -rf {} \; 2>/dev/null || true

echo ""
echo "📊 Cleanup Report:"
if [ -d "$BACKUP_DIR" ] && [ -n "$(ls -A "$BACKUP_DIR" 2>/dev/null || true)" ]; then
  echo "- Backed up to: $BACKUP_DIR"
  echo "- Files moved: $(ls -1 "$BACKUP_DIR" | wc -l | tr -d ' ')"
else
  rmdir "$BACKUP_DIR" 2>/dev/null || true
  echo "- No files to clean!"
fi
