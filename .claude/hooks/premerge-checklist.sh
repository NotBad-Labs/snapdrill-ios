#!/bin/bash
# PreToolUse (Bash): 拦截 gh pr merge，提示 STATUS.md 是否最近更新 + Review 留痕。
# 近 24h 无 STATUS.md 修改 → exit 2 提示。

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if ! echo "$COMMAND" | grep -qE '^[[:space:]]*gh pr merge\b'; then
    exit 0
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [[ -z "$PROJECT_ROOT" ]]; then
    exit 0
fi

cd "$PROJECT_ROOT"

LAST_STATUS_COMMIT=$(git log -1 --since="24 hours ago" --format=%H -- STATUS.md 2>/dev/null || echo "")

if [[ -z "$LAST_STATUS_COMMIT" ]]; then
    echo "PR 合并前提示（F-007 / workflow.md DoD）：" >&2
    echo "  近 24 小时未更新 STATUS.md。" >&2
    echo "  workflow.md DoD 要求合并后立即更新 STATUS.md + 确认 Review 结论已留痕。" >&2
    echo "  若已在 PR 描述里完成留痕，可让用户显式授权后重试。" >&2
    exit 2
fi

exit 0
