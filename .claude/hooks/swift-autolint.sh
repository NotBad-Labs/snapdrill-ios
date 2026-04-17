#!/bin/bash
# PostToolUse (Edit|Write): 对刚修改的 Swift 文件跑 swiftlint。
# 违规时 exit 2，stderr 打给 Claude 作为 feedback。
#
# 过滤策略（Issue #666）：
# - 单文件 swiftlint --strict 会报 file-level 规则（file_length 等）
# - 这些与"单次 Edit 行"无关，且存量违规会反复阻塞无关 Edit
# - 因此 hook 只报**行级违规**（line-specific），过滤文件级规则

set -eo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# 仅处理 .swift 文件
if [[ "$FILE_PATH" != *.swift ]]; then
    exit 0
fi

# 仅处理项目内文件
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [[ -z "$PROJECT_ROOT" ]] || [[ "$FILE_PATH" != "$PROJECT_ROOT"/* ]]; then
    exit 0
fi

if ! command -v swiftlint >/dev/null 2>&1; then
    echo "warning: swiftlint not installed, skipping autolint" >&2
    exit 0
fi

RAW=$(cd "$PROJECT_ROOT" && swiftlint lint --strict --quiet "$FILE_PATH" 2>&1 || true)

# 过滤掉文件级规则（与单次 Edit 无关，存量违规应由独立 PR 处理）
# 参考 Issue #666：file_length / type_body_length / blanket_disable_command / superfluous_disable_command 属于文件整体结构
FILTERED=$(echo "$RAW" | grep -vE "\((file_length|type_body_length|blanket_disable_command|superfluous_disable_command)\)" || true)

if [[ -z "$FILTERED" ]]; then
    exit 0
fi

echo "swiftlint 对 $FILE_PATH 报行级违规：" >&2
echo "$FILTERED" >&2
echo "请修复后再继续（文件级违规已过滤，见 Issue #666）。" >&2
exit 2
