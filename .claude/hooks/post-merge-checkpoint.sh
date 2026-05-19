#!/bin/bash
# PostToolUse (Bash gh pr merge): PR 合并后提示创建 checkpoint
# 不阻塞合并（exit 0），仅 stderr 输出提醒
#
# 触发条件：近 7 天合并 PR 数 ≥ 3，建议运行 /phase-closeout skill
# 来源：Hermes 借鉴 docs/archive/research/hermes-agent-study-20260418.md

set -eo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# 仅处理 gh pr merge
if ! echo "$COMMAND" | grep -qE '^[[:space:]]*gh pr merge\b'; then
    exit 0
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
[ -z "$PROJECT_ROOT" ] && exit 0
cd "$PROJECT_ROOT"

# 统计近 7 天合并到 develop 的 PR 数
RECENT_MERGES=$(git log --since="7 days ago" --merges --first-parent --oneline 2>/dev/null | wc -l | tr -d ' ')

# 阈值 3：触发 checkpoint 提示
if [ "${RECENT_MERGES:-0}" -ge 3 ]; then
    # 自 5aa78fee 起 checkpoints 已合并入 docs/memory/handoff.md Risks 段（per phase-closeout skill）
    HANDOFF="$PROJECT_ROOT/docs/memory/handoff.md"
    HANDOFF_AGE="未知"
    if [ -f "$HANDOFF" ]; then
        HANDOFF_AGE=$(date -r "$HANDOFF" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "未知")
    fi

    echo "" >&2
    echo "Phase Compaction 提示：" >&2
    echo "  近 7 天 develop 合并 ${RECENT_MERGES} 个 PR" >&2
    echo "  handoff.md 最后修改：${HANDOFF_AGE}" >&2
    echo "  建议：调用 /phase-closeout skill 在 handoff.md Risks 段下方追加 Phase 状态块" >&2
    echo "" >&2
fi

# 反模式启发式扫描（不阻塞，只 stderr 提示）
LAST_PR=$(echo "$COMMAND" | grep -oE 'gh pr merge[[:space:]]+[0-9]+' | awk '{print $NF}')
SCAN_SCRIPT="$PROJECT_ROOT/Scripts/anti-pattern-scan.sh"
if [ -n "$LAST_PR" ] && [ -x "$SCAN_SCRIPT" ]; then
    "$SCAN_SCRIPT" "$LAST_PR" || true
fi

exit 0
