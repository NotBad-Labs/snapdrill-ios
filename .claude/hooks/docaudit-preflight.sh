#!/bin/bash
# PreToolUse (Bash): git push / gh pr merge / git commit --amend 前跑 docaudit all --strict --baseline。
# 防止 error 级命中推到远端再被 CI 阻断（本地兜底）。
# 被 legacy_whitelist 豁免的历史违规不阻断；新增违规阻断。

set -eo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# 仅处理会推送 / 合并 / 改写历史的命令
case "$COMMAND" in
    *"git push"*|*"gh pr merge"*|*"git commit --amend"*|*"git rebase"*) ;;
    *) exit 0 ;;
esac

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [[ -z "$PROJECT_ROOT" ]]; then exit 0; fi
if [[ ! -f "$PROJECT_ROOT/Scripts/audit/docaudit.py" ]]; then exit 0; fi

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
