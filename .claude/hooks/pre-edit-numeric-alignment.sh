#!/bin/bash
# PreToolUse (Edit|Write|MultiEdit): 数字凑数巧合 / §N 对照声明防御
#
# 实证锚：feedback_numeric_alignment_blindspot 升级版第 7 条（4 次复发：
# M-002 v1 §10.1 / M-006 v1 §12 / M-001 v1 §13 / M-001 v1 §5）。
#
# 触发：起草 docs/meta/M-NNN-*.md 或 user-decision-log.md 时检测对宪法
# 层 M-NNN §N 的对照声明，stderr 提示主笔人工 grep 原文 + frontmatter
# 标注 mirror_of。
#
# 不阻断（exit 0）：hook 不能验证主笔认知行为，文本检测有假阳性风险，
# 只能保证提示可见。强制力来自主笔纪律 + 异源审计 + user-decision-log
# 记录违纪实证。

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.claude/hooks/_hook_common.sh
source "$HOOK_DIR/_hook_common.sh"

require_command jq

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

case "$TOOL" in
    Edit|Write|MultiEdit) ;;
    *) exit 0 ;;
esac

FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[[ -z "$FILE" ]] && exit 0

# 触发范围：元规则 + 裁决日志（feedback 在 ~/.claude/ 不在 git，不覆盖）
if ! echo "$FILE" | grep -qE '/docs/meta/(M-[0-9]{3}|user-decision-log)[^/]*\.md$'; then
    exit 0
fi

NEW_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // empty')
[[ -z "$NEW_CONTENT" ]] && exit 0

# 检测「§N 对照 / 自反性宣称」类声明特征（任一命中即提示）
PATTERNS=(
    '与[^。\n]{0,30}M-00[0-9][^。\n]{0,30}§[0-9]'
    '对照[^。\n]{0,30}M-00[0-9][^。\n]{0,30}§'
    '已[^。\n]{0,15}grep[^。\n]{0,15}§'
    '原文镜像[^。\n]{0,15}§'
    '宪法层[^。\n]{0,15}列项'
    '自反性[^。\n]{0,15}已[^。\n]{0,15}遵守'
)

HIT_PATTERNS=""
for pat in "${PATTERNS[@]}"; do
    if printf '%s' "$NEW_CONTENT" | grep -qE "$pat"; then
        HIT_PATTERNS="${HIT_PATTERNS}
  · ${pat}"
    fi
done

if [[ -n "$HIT_PATTERNS" ]]; then
    cat >&2 <<HOOK_MSG

⚠️  pre-edit-numeric-alignment: 检测到宪法层 §N 对照声明
    文件: $FILE
    命中模式:$HIT_PATTERNS

    feedback_numeric_alignment_blindspot 升级版纪律：
    1. 真 grep 宪法层 §N 原文（不是 mental 自评），逐项数清预期数量
    2. 心智上区分「原文镜像」(来自 §N 原文逐项) vs「派生扩展」(下游自创)
    3. 异源审计 reviewer 必须独立 grep（不能假设主笔已正确数过）
    4. 升级建议（feedback 第 7 条）：未来 M-005 §J 复审时可加 mirror_of frontmatter
       字段正式强制标注；当前阶段为 warning-only 提示

    实证锚（4 次复发）：
    - M-002 v1 §10.1 「7 字段」漏 M-000 §5 第 8 项「元层级注记」
    - M-006 v1 §12 幻觉式合规（声称「§4 5 档已对照 M-000 §3 原文」，但 §3 无该清单）
    - M-001 v1 §13 自反性 6/7 计数错 + §5 「4 节 = 4 层」实际仅 2 层

    详见 ~/.claude/projects/.../memory/feedback_numeric_alignment_blindspot.md
HOOK_MSG
fi

exit 0
