#!/bin/bash
# PreToolUse (Edit|Write|MultiEdit): derived_from 字段修改异源 verify 提示
#
# 实证锚：Goal H7 P0 verify 2026-05-26（docs/audits/h7-p0-verify-20260526.md）：
#   主笔自审 6 个 derived_from 修复建议，0% 准确率：
#     - 2 处事实错误（引用不存在的章节/概念）
#     - 1 处术语混淆（CLI 脱敏 vs CLI 权限）
#     - 3 处方向偏差（应双向）
#   双异源（agy + DeepSeek）grep verify 防止了所有 6 处错误修改。
#
# 触发：任何 docs/**/*.md 的 PreEdit 含 `derived_from:` 字段 → stderr 提示
#       counter-verify 纪律。warning-only 不阻断（exit 0）。
#
# 不阻断理由：
#   - 新建文档需要写 derived_from，hook 不能阻塞合理写入
#   - 修改 derived_from 是合理操作（如下游文档随上位演化）
#   - hook 只能确保「counter-verify 提示可见」，强制力来自主笔纪律 +
#     M-005 §G.7（待加）+ user-decision-log 违纪实证

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

FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')
[[ -z "$FILE" ]] && exit 0

# 触发范围：所有 docs/**/*.md（H7 P0 揭出 standards/templates/decisions 都有漂移）
if ! echo "$FILE" | grep -qE '(^|/)docs/[^/]+/.+\.md$'; then
    exit 0
fi

NEW_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // empty')
[[ -z "$NEW_CONTENT" ]] && exit 0

# 检测 derived_from 字段写入
if ! printf '%s' "$NEW_CONTENT" | grep -qE '^derived_from:|derived_from:\s*\['; then
    exit 0
fi

cat >&2 <<HOOK_MSG

ℹ️  pre-edit-derived-from: 检测到 derived_from 字段写入
    文件: $FILE

    H7 P0 verify 实证（2026-05-26）：主笔自审 6 个 derived_from 修复建议
    准确率 0%（2 个事实错误 + 1 个术语混淆 + 3 个方向偏差）。
    双异源 verify 防止所有 6 处错误修改。

    Counter-verify 纪律：
    1. grep derived_from 指向的 M-XXX §N 实际内容，verify 派生关系真实
    2. 如修改派生关系，双异源 verify（agy + DeepSeek 或 Codex + DeepSeek）
    3. 主笔自审不充分（feedback_numeric_alignment_blindspot 第 6 条）
    4. 修复门槛：≥2/3 异源 agreement

    schema 检查（M-000 §11.10 v2.1）：
    - 允许格式：M-NNN / M-NNN §N / M-NNN §N.N / user-decision-log #NNN
    - 注意 ADR-NNN 不在 schema 内（schema gap，待 M-000 §11.10 v2.2 升级）

    详 docs/audits/h7-p0-verify-20260526.md
HOOK_MSG

exit 0
