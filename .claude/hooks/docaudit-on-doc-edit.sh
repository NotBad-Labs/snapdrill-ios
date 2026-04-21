#!/bin/bash
# PostToolUse (Edit|Write): 对刚修改的 Markdown 文件跑 docaudit links，broken link 时 exit 2。
# 与 swift-autolint 互补：前者管 Swift 行级，本 hook 管 docs 链接。
# 成本：~1s（纯 Python 正则扫描）。

set -eo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# 仅处理 Markdown 文件路径（docs/ 下 + STATUS.md + CLAUDE.md + README.md + .md 通用）
case "$FILE_PATH" in
    */docs/*.md|*/STATUS.md|*/CLAUDE.md|*/README.md) ;;
    *.md) ;;
    *) exit 0 ;;
esac

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [[ -z "$PROJECT_ROOT" ]] || [[ "$FILE_PATH" != "$PROJECT_ROOT"/* ]]; then
    exit 0
fi

# docaudit 不可用静默降级
if [[ ! -f "$PROJECT_ROOT/Scripts/audit/docaudit.py" ]]; then
    exit 0
fi

set +e
OUTPUT=$(cd "$PROJECT_ROOT" && python3 Scripts/audit/docaudit.py links 2>&1)
RESULT=$?
set -e

if [[ $RESULT -eq 0 ]]; then
    exit 0
fi

# broken link 命中 → stderr 打给 Claude
echo "docaudit links 对 $FILE_PATH 编辑后发现 broken link：" >&2
echo "$OUTPUT" >&2
echo "请修复链接或删除引用（Scripts/audit/README.md 有用法）" >&2
exit 2
