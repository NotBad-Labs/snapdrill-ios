#!/bin/bash
# 拦截危险 Git push：禁止直推 develop/main，STATUS.md 例外
# 由 PreToolUse hook 触发（matcher: Bash）

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# 只检查 git push 命令
if ! echo "$COMMAND" | grep -q "git push"; then
    exit 0
fi

# 检查是否推向 develop 或 main
if echo "$COMMAND" | grep -qE "git push.*(develop|main|origin develop|origin main)"; then
    # 检查 diff 是否只有 STATUS.md
    PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
    CHANGED_FILES=$(cd "$PROJECT_ROOT" && git diff --name-only HEAD~1 HEAD 2>/dev/null)

    if [ "$CHANGED_FILES" = "STATUS.md" ]; then
        # STATUS.md 直推例外（docs/workflow.md 文档化）
        exit 0
    fi

    # 阻止直推
    echo '{"decision":"block","reason":"禁止直推 develop/main。请走 PR 流程（docs/workflow.md 铁律）。唯一例外：STATUS.md 直推。"}'
    exit 2
fi

exit 0
