# Phase 01d Brief: 2025 History Discontinuity

> **文档状态：固定基线历史证据。** 本文只描述当时基线，不提供当前排期或执行授权；当前恢复入口见 `docs/reference/audits/2026-07-repository/README.md`，产品规范见 `docs/product/vision.md` 与 `docs/product/release-1-prd.md`。

## Fixed Evidence

- base: `develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- issues: `/private/tmp/snapdrill-repository-audit-phase01/issues.json`
- pull requests: `/private/tmp/snapdrill-repository-audit-phase01/pulls.json`
- local repository objects and refs at the fixed base

## C1 Starting Facts

- 2025 has 21 pull requests: 10 closed unmerged and 11 marked merged by GitHub.
- None of the 11 merge SHAs is an ancestor of current `develop`: four objects are
  locally present but not ancestors; seven objects are absent locally.
- Current `develop` begins at an orphan-root commit dated 2025-12-29.

## Question

What work represented by the 21 pre-orphan pull requests is demonstrably absent,
semantically preserved, superseded or unknowable in the current product? Do not
equate missing ancestry with wasted effort without tracing content.

## Rules

- New session. Do not read another agent report, private memory or chat history.
- Read-only local analysis only. No network, edits, builds or broad architecture
  recommendation.
- Classify every 2025 pull request by work type and evidence strength. Inspect local
  commits when objects exist; use titles alone only as a weak signal when objects do
  not exist.
- Search the current tree for semantic descendants of old product, documentation,
  CI and release work. Similar naming is not proof of preservation.
- Separate `FACT`, `INFERENCE` and `UNKNOWN`. Give a lower and upper bound for work
  that is demonstrably discarded, and state the unit being counted.

## Output

Return concise Markdown with Metadata, Ancestry Verification, Per-PR Classification,
Preserved or Superseded Evidence, Discard Bounds, Candidate Findings, Rejected Claims,
Missing Evidence and Handoff. Include exact PR numbers, SHAs, paths and reproducible
commands.
