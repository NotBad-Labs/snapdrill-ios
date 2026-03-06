#!/usr/bin/env bash
# 核心职责：将外部 AI 工具（如 Google Antigravity）的 code review 结果 post 到当前分支对应的 GitHub PR。
#
# 用法：
#   echo "review 内容" | bash Scripts/post_review.sh [reviewer]
#   bash Scripts/post_review.sh [reviewer] < review.txt
#
# 参数：
#   reviewer  可选，标识 review 来源，默认 "antigravity"
#             支持：antigravity | gemini | claude
#
# 示例（Antigravity 直接调用）：
#   echo "$REVIEW_TEXT" | bash Scripts/post_review.sh antigravity
#
# 依赖：gh CLI（已登录），git

set -euo pipefail

REVIEWER="${1:-antigravity}"

# 读取 stdin 内容
REVIEW_BODY="$(cat)"

if [ -z "$REVIEW_BODY" ]; then
    echo "错误：review 内容为空（通过 stdin 传入）" >&2
    exit 1
fi

# 自动获取当前分支对应的 PR 编号
PR_NUMBER="$(gh pr view --json number --jq '.number' 2>/dev/null || true)"

if [ -z "$PR_NUMBER" ]; then
    echo "错误：当前分支没有关联的 PR，请先创建 PR" >&2
    exit 1
fi

# 构造评论 header
case "$REVIEWER" in
    antigravity)
        HEADER="## Google Antigravity Code Review"
        FOOTER="> 🤖 由 [Google Antigravity](https://antigravity.google) 自动生成。合并前请人工确认。"
        ;;
    gemini)
        HEADER="## Gemini Code Review"
        FOOTER="> 🤖 由 Gemini 自动生成。合并前请人工确认。"
        ;;
    claude)
        HEADER="## Claude Code Review"
        FOOTER="> 🤖 由 [Claude Code CLI](https://claude.ai/claude-code)（claude-sonnet-4-6）自动生成。合并前请人工确认。"
        ;;
    *)
        HEADER="## Code Review（${REVIEWER}）"
        FOOTER="> 🤖 由 ${REVIEWER} 自动生成。合并前请人工确认。"
        ;;
esac

COMMENT="${HEADER}

${REVIEW_BODY}

---
${FOOTER}"

gh pr comment "$PR_NUMBER" --body "$COMMENT"

echo "✅ Review 已 post 到 PR #${PR_NUMBER}"
