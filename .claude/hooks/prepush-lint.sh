#!/bin/bash
# PreToolUse (Bash): git push 前跑 swiftlint。
# 违规 → exit 2。

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if ! echo "$COMMAND" | grep -qE '^[[:space:]]*git push\b'; then
    exit 0
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [[ -z "$PROJECT_ROOT" ]]; then
    exit 0
fi

if ! command -v swiftlint >/dev/null 2>&1; then
    exit 0
fi

cd "$PROJECT_ROOT"
OUTPUT=$(swiftlint lint --strict --quiet 2>&1 || true)

if [[ -z "$OUTPUT" ]]; then
    exit 0
fi

echo "git push 前 swiftlint 发现违规：" >&2
echo "$OUTPUT" >&2
echo "请修复后再推。" >&2
exit 2
