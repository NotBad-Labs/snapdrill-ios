#!/bin/bash
# Stop 质量门：检查本次会话是否已通过 lint + build 验证
# 由 Stop hook 触发

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
SESSION_LOG="$PROJECT_ROOT/.claude/session-log.txt"
LINT_STATUS="$PROJECT_ROOT/.claude/validation-status.json.lint"
BUILD_STATUS="$PROJECT_ROOT/.claude/validation-status.json.build"

# 检查本次会话是否修改过 Swift 文件
if [ ! -f "$SESSION_LOG" ]; then
    exit 0
fi

SWIFT_CHANGES=$(grep "\.swift" "$SESSION_LOG" 2>/dev/null | wc -l | tr -d ' ')

if [ "$SWIFT_CHANGES" = "0" ]; then
    # 没改过 Swift 文件，无需验证
    exit 0
fi

# 检查 lint 和 build 是否通过
WARNINGS=""

if [ ! -f "$LINT_STATUS" ]; then
    WARNINGS="${WARNINGS}swiftlint --strict 未执行。"
fi

if [ ! -f "$BUILD_STATUS" ]; then
    WARNINGS="${WARNINGS}xcodebuild build-for-testing 未执行。"
fi

if [ -n "$WARNINGS" ]; then
    echo "质量门提醒：本次会话修改了 ${SWIFT_CHANGES} 个 Swift 文件，但 ${WARNINGS} 请在完成前运行验证。"
fi

exit 0
