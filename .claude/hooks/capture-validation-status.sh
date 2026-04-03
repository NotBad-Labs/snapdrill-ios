#!/bin/bash
# 记录 lint/build 验证状态，供 Stop 质量门检查
# 由 PostToolUse hook 触发（matcher: Bash）

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_result.exit_code // empty')

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
STATUS_FILE="$PROJECT_ROOT/.claude/validation-status.json"

# 检查是否是 swiftlint --strict
if echo "$COMMAND" | grep -q "swiftlint --strict"; then
    if [ "$EXIT_CODE" = "0" ]; then
        echo "{\"lint_pass\":\"$(date -Iseconds)\"}" > "$STATUS_FILE.lint"
    fi
fi

# 检查是否是 xcodebuild build-for-testing
if echo "$COMMAND" | grep -q "build-for-testing"; then
    if [ "$EXIT_CODE" = "0" ]; then
        echo "{\"build_pass\":\"$(date -Iseconds)\"}" > "$STATUS_FILE.build"
    fi
fi

exit 0
