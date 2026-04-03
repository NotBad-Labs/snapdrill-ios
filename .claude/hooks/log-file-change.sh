#!/bin/bash
# 记录文件修改到 session log，压缩后仍可查阅
# 由 PostToolUse hook 触发（matcher: Edit|Write）

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -n "$FILE_PATH" ]; then
    PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
    REL_PATH="${FILE_PATH#$PROJECT_ROOT/}"
    TIMESTAMP=$(date '+%H:%M')
    echo "$TIMESTAMP $REL_PATH" >> "$PROJECT_ROOT/.claude/session-log.txt"
fi

exit 0
