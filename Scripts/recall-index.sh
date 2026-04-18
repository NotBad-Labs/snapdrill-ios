#!/bin/bash
# 知识/记忆快速召回（Hermes 借鉴，docs/research/hermes-agent-study-20260418.md）
#
# 用法：
#   bash Scripts/recall-index.sh <关键词>
#
# 在以下位置搜索匹配：
#   - docs/ 全部 md
#   - 根级 STATUS.md / CLAUDE.md / CODEX.md
#   - ~/.claude/plans/（一次性研究产物 + 三方对抗汇总）
#   - ~/.claude/projects/.../memory/（私有记忆）
#   - git log commit message

set -eo pipefail

QUERY="${1:-}"
if [ -z "$QUERY" ]; then
    cat <<USAGE
用法: bash Scripts/recall-index.sh <关键词>

例子:
  bash Scripts/recall-index.sh "F-008"           # 找 F-008 纪律所有引用
  bash Scripts/recall-index.sh "ContentTagging"  # 找服务相关讨论
  bash Scripts/recall-index.sh "Hermes"          # 找 Hermes 研究
USAGE
    exit 2
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [ -z "$PROJECT_ROOT" ]; then
    echo "错误: 不在 git 仓库内" >&2
    exit 1
fi

if ! command -v rg >/dev/null 2>&1; then
    echo "错误: 需要 ripgrep（brew install ripgrep）" >&2
    exit 1
fi

echo "==[1] docs/ ==="
rg -n --type md "$QUERY" "$PROJECT_ROOT/docs" 2>/dev/null || echo "(无匹配)"

echo
echo "==[2] 根级 md（STATUS / CLAUDE / CODEX）==="
rg -n --type md "$QUERY" "$PROJECT_ROOT" --max-depth 1 2>/dev/null || echo "(无匹配)"

echo
echo "==[3] ~/.claude/plans/（研究归档 + 三方对抗汇总）==="
if [ -d "$HOME/.claude/plans" ]; then
    rg -n --type md "$QUERY" "$HOME/.claude/plans" 2>/dev/null || echo "(无匹配)"
else
    echo "(目录不存在)"
fi

echo
echo "==[4] 私有记忆 ~/.claude/projects/.../memory ==="
PROJ_MEMORY="$HOME/.claude/projects/-Users-yiming-Developer-snapdrill-ios/memory"
if [ -d "$PROJ_MEMORY" ]; then
    rg -n --type md "$QUERY" "$PROJ_MEMORY" 2>/dev/null || echo "(无匹配)"
else
    echo "(目录不存在)"
fi

echo
echo "==[5] git log commit message（近 100 条）==="
cd "$PROJECT_ROOT"
git log --oneline -100 | grep -i "$QUERY" || echo "(无匹配)"

echo
echo "==[6] PR 标题（近 30 条）==="
if command -v gh >/dev/null 2>&1; then
    gh pr list --state all --limit 30 --json number,title --jq '.[] | "#\(.number) \(.title)"' 2>/dev/null | grep -i "$QUERY" || echo "(无匹配/gh 不可用)"
else
    echo "(gh CLI 不可用，跳过)"
fi
