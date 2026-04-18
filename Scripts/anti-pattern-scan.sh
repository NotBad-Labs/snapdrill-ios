#!/bin/bash
# anti-pattern-scan.sh — 启发式检测刚合并 PR 的潜在反模式
#
# 用法：Scripts/anti-pattern-scan.sh <PR_NUMBER>
#
# 行为：只 stderr 输出警报，绝不阻塞（exit 0）。检测到命中时提示 phase-closeout
# 时判断是否升级为 feedback 规则（F-019）。
#
# 检测项（启发式，会有假阳性）：
#   1. 单 PR 改动文件数 > 15 → 可能 scope 膨胀（F-013）
#   2. 单 PR additions > 1000 → 可能 over-generation（F-005）
#   3. 删除 *Tests.swift 且未新增测试 → 可能 test evasion（F-014）
#   4. diff 新增 XCTSkip / .disabled / Suite disabled → 可能 test evasion（F-014）
#
# 依赖：gh CLI、jq

set -eo pipefail

PR_NUM="${1:-}"
if [ -z "$PR_NUM" ]; then
    echo "Usage: $0 <PR_NUMBER>" >&2
    exit 0
fi

# 静默依赖检查
command -v gh >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# 读取 PR 元数据
STATS=$(gh pr view "$PR_NUM" --json additions,deletions,changedFiles,files,title 2>/dev/null || echo "")
[ -z "$STATS" ] && exit 0

ADDITIONS=$(echo "$STATS" | jq -r '.additions // 0')
CHANGED=$(echo "$STATS" | jq -r '.changedFiles // 0')
TITLE=$(echo "$STATS" | jq -r '.title // ""')

# 收集警报
WARNINGS=()

# 1. scope 膨胀
if [ "$CHANGED" -gt 15 ]; then
    WARNINGS+=("scope 膨胀疑似：改动 ${CHANGED} 文件（阈值 15，F-013）")
fi

# 2. over-generation
if [ "$ADDITIONS" -gt 1000 ]; then
    WARNINGS+=("over-generation 疑似：新增 ${ADDITIONS} 行（阈值 1000，F-005）")
fi

# 3. 删测试 + 未新增测试
DELETED_TESTS=$(echo "$STATS" | jq -r '[.files[]? | select(.path | endswith("Tests.swift")) | select(.deletions > 0)] | length')
ADDED_TESTS=$(echo "$STATS" | jq -r '[.files[]? | select(.path | endswith("Tests.swift")) | select(.additions > 0)] | length')
if [ "${DELETED_TESTS:-0}" -gt 0 ] && [ "${ADDED_TESTS:-0}" -eq 0 ]; then
    WARNINGS+=("test evasion 疑似：删除 ${DELETED_TESTS} 个 Tests.swift 文件且未新增测试（F-014）")
fi

# 4. diff 含 skip 标记
SKIP_COUNT=$(gh pr diff "$PR_NUM" 2>/dev/null | grep -cE '^\+.*(XCTSkip|\.disabled\b|@Suite\(.*\.disabled)' || true)
if [ "${SKIP_COUNT:-0}" -gt 0 ]; then
    WARNINGS+=("test evasion 疑似：diff 新增 ${SKIP_COUNT} 行 skip 标记（F-014）")
fi

# 输出
if [ "${#WARNINGS[@]}" -gt 0 ]; then
    echo "" >&2
    echo "反模式启发式警报（PR #${PR_NUM}${TITLE:+: $TITLE}）：" >&2
    for W in "${WARNINGS[@]}"; do
        echo "  - ${W}" >&2
    done
    echo "" >&2
    echo "判断原则（F-019）：单次偶然可忽略；同类警报近期出现 3 次 → phase-closeout 时" >&2
    echo "升级为新 feedback 规则或 CI/hook 门禁。避免误杀也避免纵容。" >&2
    echo "" >&2
fi

exit 0
