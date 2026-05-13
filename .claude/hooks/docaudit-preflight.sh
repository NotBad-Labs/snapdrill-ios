#!/bin/bash
# PreToolUse (Bash): 在 push / merge / amend 前跑 docaudit all --strict --baseline。
# 防止 error 级命中推到远端再被 CI 阻断（本地兜底）。
# 被 legacy_whitelist 豁免的历史违规不阻断；新增违规阻断。

set -eo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.claude/hooks/_hook_common.sh
source "$HOOK_DIR/_hook_common.sh"

require_command jq

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# 锚定命令匹配（对齐 prepush-lint.sh / premerge-checklist.sh 风格，避免 `echo "test git push"` 误触发）
if ! echo "$COMMAND" | grep -qE '^[[:space:]]*(git[[:space:]]+push|gh[[:space:]]+pr[[:space:]]+merge|git[[:space:]]+commit[[:space:]]+.*--amend)\b'; then
    exit 0
fi

require_command git

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [[ -z "$PROJECT_ROOT" ]]; then exit 0; fi
if [[ ! -f "$PROJECT_ROOT/Scripts/audit/docaudit.py" ]]; then
    echo "hook dependency missing: $PROJECT_ROOT/Scripts/audit/docaudit.py" >&2
    exit 1
fi

require_command python3

set +e
OUTPUT=$(cd "$PROJECT_ROOT" && python3 Scripts/audit/docaudit.py all --strict --baseline 2>&1)
RESULT=$?
set -e

if [[ $RESULT -eq 0 ]]; then
    exit 0
fi

echo "docaudit preflight 阻断命令：$COMMAND" >&2
echo "---" >&2
echo "$OUTPUT" >&2
echo "---" >&2
echo "修复 error 级命中，或在 Scripts/audit/policy.yaml legacy_whitelist 登记理由（含 expires_on）" >&2
exit 2
