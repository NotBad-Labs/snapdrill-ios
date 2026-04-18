#!/bin/bash
# PreToolUse (Bash): 会话时长检查，> 1h 提示先 compact / phase-closeout
# 不阻塞（exit 0），仅 stderr 输出提醒，每会话只提示一次
#
# 时长基于 .claude/session-log.txt 第一行时间戳（log-file-change.sh 写入）
# 来源：Hermes 借鉴 docs/research/hermes-agent-study-20260418.md

set -eo pipefail

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
[ -z "$PROJECT_ROOT" ] && exit 0

SESSION_LOG="$PROJECT_ROOT/.claude/session-log.txt"
[ ! -f "$SESSION_LOG" ] && exit 0

# 提示标志文件（每会话只提一次）
SEEN_FLAG="$PROJECT_ROOT/.claude/.long-session-warned"
[ -f "$SEEN_FLAG" ] && exit 0

# 读 session log 第一行时间（HH:MM 格式，由 log-file-change.sh 写）
FIRST_LINE=$(head -1 "$SESSION_LOG" 2>/dev/null || echo "")
[ -z "$FIRST_LINE" ] && exit 0

FIRST_TIME=$(echo "$FIRST_LINE" | awk '{print $1}')
[ -z "$FIRST_TIME" ] && exit 0
echo "$FIRST_TIME" | grep -qE '^[0-9]{2}:[0-9]{2}$' || exit 0

# 计算分钟差（macOS date -j -f）
NOW=$(date '+%H:%M')
FIRST_EPOCH=$(date -j -f "%H:%M" "$FIRST_TIME" "+%s" 2>/dev/null || echo "0")
NOW_EPOCH=$(date -j -f "%H:%M" "$NOW" "+%s" 2>/dev/null || echo "0")

[ "$FIRST_EPOCH" = "0" ] || [ "$NOW_EPOCH" = "0" ] && exit 0

DIFF_SECONDS=$(( NOW_EPOCH - FIRST_EPOCH ))
# 跨日处理（负数加 24h）
[ "$DIFF_SECONDS" -lt 0 ] && DIFF_SECONDS=$(( DIFF_SECONDS + 86400 ))
DIFF_MIN=$(( DIFF_SECONDS / 60 ))

# 阈值 60 分钟
if [ "$DIFF_MIN" -gt 60 ]; then
    echo "" >&2
    echo "Long Session 提示：" >&2
    echo "  本会话已持续约 ${DIFF_MIN} 分钟（基于 session-log）" >&2
    echo "  建议：先调用 /compact 或 /phase-closeout 再继续，避免上下文过载" >&2
    echo "  本提示每会话只显示一次" >&2
    echo "" >&2
    touch "$SEEN_FLAG"
fi

exit 0
