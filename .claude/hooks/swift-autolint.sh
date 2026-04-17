#!/bin/bash
# PostToolUse (Edit|Write): 对刚修改的 Swift 文件跑 swiftlint。
# 违规时 exit 2，stderr 打给 Claude 作为 feedback。

set -euo pipefail

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

OUTPUT=$(cd "$PROJECT_ROOT" && swiftlint lint --strict --quiet "$FILE_PATH" 2>&1 || true)

if [[ -z "$OUTPUT" ]]; then
    exit 0
fi

echo "swiftlint 对 $FILE_PATH 报违规：" >&2
echo "$OUTPUT" >&2
echo "请修复后再继续。" >&2
exit 2
