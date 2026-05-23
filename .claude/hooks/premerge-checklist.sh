#!/bin/bash
# PreToolUse (Bash): 拦截 gh pr merge，校验 F-007 STATUS.md 24h 更新 + F-005 PR review 留痕。
# 近 24h 无 STATUS.md 修改 → exit 2 提示。
# PR body 缺 `## F-005 Review Trace` 段或字段不合规 → exit 2 阻断（S-D7-002 共识）。
# Override（紧急）：F005_REVIEW_TRACE_OVERRIDE=1 跳过 F-005 校验（仍写 stderr 留 audit trail）。

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if ! echo "$COMMAND" | grep -qE '^[[:space:]]*gh pr merge\b'; then
    exit 0
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [[ -z "$PROJECT_ROOT" ]]; then
    exit 0
fi

cd "$PROJECT_ROOT"

# F-007: STATUS.md 24h 更新检查
LAST_STATUS_COMMIT=$(git log -1 --since="24 hours ago" --format=%H -- STATUS.md 2>/dev/null || echo "")
if [[ -z "$LAST_STATUS_COMMIT" ]]; then
    echo "PR 合并前提示（F-007 / protocol.md DoD）：" >&2
    echo "  近 24 小时未更新 STATUS.md。" >&2
    echo "  protocol.md DoD 要求合并后立即更新 STATUS.md + 确认 Review 结论已留痕。" >&2
    echo "  若已在 PR 描述里完成留痕，可让用户显式授权后重试。" >&2
    exit 2
fi

# F-005: PR Review Trace 校验（S-D7-002 共识）
if [[ "${F005_REVIEW_TRACE_OVERRIDE:-0}" = "1" ]]; then
    echo "⚠️  F005_REVIEW_TRACE_OVERRIDE=1 — bypassing F-005 review trace check." >&2
    echo "    PR body MUST be patched with Review Trace before next merge." >&2
else
    PR_NUMBER=$(echo "$COMMAND" | grep -oE 'gh pr merge[[:space:]]+[0-9]+' | awk '{print $NF}' || true)
    if [[ -z "$PR_NUMBER" ]]; then
        # 尝试从当前分支推导（gh pr view 默认当前分支）
        PR_NUMBER=$(gh pr view --json number --jq '.number' 2>/dev/null || true)
    fi

    if [[ -z "$PR_NUMBER" ]]; then
        echo "F-005 pre-merge: cannot determine PR number." >&2
        echo "  Use 'gh pr merge <number>' or run from a branch with an open PR." >&2
        exit 2
    fi

    if ! python3 Scripts/audit/pr_review_trace.py --pr "$PR_NUMBER" 2>&1; then
        exit 2
    fi
fi

# F-018: Sprint Contract Closeout 校验（S-D7-003 共识）
# Override（紧急）：F018_SPRINT_CONTRACT_OVERRIDE=1 跳过
if [[ "${F018_SPRINT_CONTRACT_OVERRIDE:-0}" = "1" ]]; then
    echo "⚠️  F018_SPRINT_CONTRACT_OVERRIDE=1 — bypassing F-018 closeout check." >&2
else
    if [[ -n "${PR_NUMBER:-}" ]]; then
        LINKED_ISSUE=$(gh pr view "$PR_NUMBER" --json closingIssuesReferences --jq '.closingIssuesReferences[0].number' 2>/dev/null || true)
        if [[ -n "$LINKED_ISSUE" ]]; then
            if ! python3 Scripts/audit/sprint_contract_gate.py --check-closeout --issue "$LINKED_ISSUE" 2>&1; then
                exit 2
            fi
        fi
    fi
fi

exit 0
