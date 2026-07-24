# Phase 01c Brief: Git Churn and Rework Hotspots

> **文档状态：固定基线历史证据。** 本文只描述当时基线，不提供当前排期或执行授权；当前恢复入口见 `docs/reference/audits/2026-07-repository/README.md`，产品规范见 `docs/product/vision.md` 与 `docs/product/release-1-prd.md`。

## Fixed Evidence

- base: `develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- Git numstat: `/private/tmp/snapdrill-repository-audit-phase01/git-numstat.txt` (`1,285` commits, SHA-256 `f31d9b77a6749334d39a355e6e467a166324938cec4e452edbf9eb4351408053`)
- issue/PR metadata: `/private/tmp/snapdrill-repository-audit-phase01/{issues,pulls}.json`

## Question

Where did repeated edits, reversals, abandoned code or high-churn seams consume effort? Separate healthy iteration from avoidable rework. Identify candidate hotspots that should be kept, simplified, frozen or audited next, without proposing a rewrite.

## Rules

- New session; do not read other agent reports, private memory or chat history.
- Read-only local analysis only: Python, `git log/show/diff`, `jq`, `rg` and named evidence files.
- Normalize renames and exclude generated/binary/evidence assets before ranking churn.
- File churn alone is not waste. For each hotspot inspect the commit sequence, issue/PR chain and current file existence.
- Search for revert/fix/follow-up/cleanup/rewrite patterns, but verify semantics from diffs before classifying.
- No edits, builds, network or broad architecture recommendation.

## Output

Return Markdown with Metadata, Method, Ranked Hotspots, Healthy-Churn Counterexamples, Candidate Findings, Rejected Signals, Missing Evidence and Handoff. Include exact paths, SHAs/PR numbers and reproducible commands.
