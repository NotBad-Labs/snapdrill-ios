#!/bin/zsh

set -euo pipefail

echo "📊 Code Quality Report"
echo "===================="

echo "Files > 300 lines:"
find . -name "*.swift" -not -path "*/.build/*" -not -path "*/.git/*" -exec wc -l {} \; | awk '$1 > 300 {print $2 ": " $1 " lines"}' || true

echo ""
echo "Complex functions (cyclomatic complexity > 10):"
if command -v swiftlint >/dev/null 2>&1; then
  swiftlint analyze || true
else
  echo "SwiftLint not installed; skipping detailed complexity analysis."
fi

echo ""
echo "Potential duplicates:"
if command -v fdupes >/dev/null 2>&1; then
  fdupes -r . | head -50 || true
else
  echo "fdupes not installed; provide manual hints in future."
fi
