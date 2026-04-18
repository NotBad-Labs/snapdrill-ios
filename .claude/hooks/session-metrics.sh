#!/bin/bash
# PostToolUse: 记录 tool call 时间戳 + 名称到 .claude/session-metrics.tsv
#
# 目的：给 phase-closeout skill 提供 session 耗时 / tool call 频率数据。
# 非阻塞（exit 0），静默失败。
#
# 不记录 token：Claude Code 当前不通过 hook 暴露 input/output token。
# 如需 token 成本追踪须自建 HTTPS 代理记录请求体，投入与回报不匹配，暂不做。
#
# 不入 git：tsv 在 .gitignore 中，仅本地可用。

set -eo pipefail

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
[ -z "$PROJECT_ROOT" ] && exit 0

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
TS=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

# 简单 TSV：时间戳 \t 工具名
echo -e "${TS}\t${TOOL}" >> "$PROJECT_ROOT/.claude/session-metrics.tsv" || true

exit 0
