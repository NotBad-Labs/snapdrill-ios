#!/bin/bash
# PreToolUse (Bash): git push 前跑 swiftlint。
# 违规 → exit 2。

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.claude/hooks/_hook_common.sh
source "$HOOK_DIR/_hook_common.sh"

require_command jq

INPUT=$(cat)
# 快速路径：输入完全没有 'push' 子串 → 绝不是 git push，免跑 jq（每条 Bash 都触发，省开销）
[[ "$INPUT" == *push* ]] || exit 0
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# 命令边界匹配：兼容 env 前缀 / 链式（'FOO=1 git push' / 'cd x && git push'），
# 但排除字符串/消息里的 'git push'（如 git commit -m "fix git push"、echo "git push"）
if ! echo "$COMMAND" | grep -qE '(^|[;&|])[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]+[[:space:]]+)*git[[:space:]]+push([[:space:]]|$)'; then
    exit 0
fi

require_command git
require_command swiftlint

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [[ -z "$PROJECT_ROOT" ]]; then
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
