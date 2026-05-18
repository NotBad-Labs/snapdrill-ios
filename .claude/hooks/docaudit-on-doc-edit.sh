#!/bin/bash
# PostToolUse (Edit|Write): 对刚修改的 docs 区 Markdown 文件跑 docaudit links，broken link 时 exit 2。
# 与 swift-autolint 互补：前者管 Swift 行级，本 hook 管 docs 链接。
# 全量 links 扫 <1s（纯 Python 正则），暂不引入增量（Phase D 可加 --paths 参数）。

set -eo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.claude/hooks/_hook_common.sh
source "$HOOK_DIR/_hook_common.sh"

require_command jq
require_command git

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# 仅处理 docs 区 Markdown（docs/ 下 md + STATUS.md + CLAUDE.md + AGENTS.md）
# Issue #711 Interface Delta 指定范围；不包含 README.md（多处存在，避免
# Scripts/audit/README.md 等非 docs 区文档误触发）
case "$FILE_PATH" in
    */docs/*.md|*/STATUS.md|*/CLAUDE.md|*/AGENTS.md) ;;
    *) exit 0 ;;
esac

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [[ -z "$PROJECT_ROOT" ]] || [[ "$FILE_PATH" != "$PROJECT_ROOT"/* ]]; then
    exit 0
fi

if [[ ! -f "$PROJECT_ROOT/Scripts/audit/docaudit.py" ]]; then
    echo "hook dependency missing: $PROJECT_ROOT/Scripts/audit/docaudit.py" >&2
    exit 1
fi

require_command python3

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
