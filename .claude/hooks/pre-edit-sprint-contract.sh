#!/bin/bash
# PreToolUse (Edit|Write|MultiEdit): F-018 Sprint Contract Gate（S-D7-003 共识落地）
#
# 默认硬阻断 exit 2，反对软警告（S-D7-003 共识：现有 0/9 应用率证明软方法已失败）。
# Override（紧急）：F018_SPRINT_CONTRACT_OVERRIDE=1 <command> 跳过本次并 stderr 留痕。
# 路径豁免：docs/* / *.md / STATUS.md 不触发；详见 .github/sprint-contract-policy.yml

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.claude/hooks/_hook_common.sh
source "$HOOK_DIR/_hook_common.sh"

require_command jq
require_command python3
require_command git

# Override 优先级最高
if [[ "${F018_SPRINT_CONTRACT_OVERRIDE:-0}" = "1" ]]; then
    # 由 gate.py 输出 stderr 留痕
    python3 "$HOOK_DIR/../../Scripts/audit/sprint_contract_gate.py" --derive-issue >/dev/null 2>&1 || true
    echo "⚠️  F018_SPRINT_CONTRACT_OVERRIDE=1 — Sprint Contract gate bypassed for this tool call." >&2
    echo "    A contract or exemption MUST be added before commit/PR." >&2
    exit 0
fi

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

case "$TOOL" in
    Edit|Write|MultiEdit|NotebookEdit) ;;
    *) exit 0 ;;
esac

FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[[ -z "$FILE" ]] && exit 0

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
[[ -z "$PROJECT_ROOT" ]] && exit 0
cd "$PROJECT_ROOT"

# 调用 gate.py 校验
if ! python3 Scripts/audit/sprint_contract_gate.py --file-path "$FILE" 2>&1; then
    exit 2
fi

exit 0
