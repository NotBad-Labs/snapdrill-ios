# Phase 01f Brief: Churn Accounting Verification

> **文档状态：固定基线历史证据。** 本文只描述当时基线，不提供当前排期或执行授权；当前恢复入口见 `docs/reference/audits/2026-07-repository/README.md`，产品规范见 `docs/explanations/vision.md` 与 `docs/reference/release-1-contract.md`。

## Fixed Evidence

- base: `develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- Git history snapshot: `/private/tmp/snapdrill-repository-audit-phase01/git-numstat.txt`
  (SHA-256 `f31d9b77a6749334d39a355e6e467a166324938cec4e452edbf9eb4351408053`)
- current tracked tree at the fixed base

## Claims To Test

- Total numeric churn is 422,176 lines.
- A prior calculation attributed 302,058 lines, or 71.5%, to now-deleted canonical
  files after rename folding.
- A prior calculation attributed 226,770 lines, or 53.7%, to process/docs churn and
  said 93% of it is now deleted.
- A raw C1 check without full rename normalization instead found 334,597 absent-path
  lines and a broader 256,694-line process bucket.

## Question

Which numbers survive a reproducible, correctly ordered rename/copy/deletion model,
and which depend on category definitions or path-normalization mistakes?

## Rules

- New session. Do not read another agent report, private memory or chat history.
- Read-only local analysis only. No network, edits or builds.
- Provide the complete executable Python or shell calculation in the report. Parse
  Git numstat rename syntax explicitly and state how copies, re-additions and path
  reuse are handled.
- Report at least: total numeric churn, binary rows excluded, current canonical-path
  churn, deleted canonical-path churn, rename-operation churn, Swift churn, and
  separately defined governance/docs buckets.
- Category definitions must be explicit. Give sensitivity ranges rather than one
  authoritative percentage when reasonable definitions differ.
- Validate representative rename chains against `git log --follow` and the current
  tree.

## Output

Return concise Markdown with Metadata, Algorithm, Executable Reproduction, Results,
Sensitivity Analysis, Spot Checks, Accepted Claims, Rejected Claims, Missing Evidence
and Handoff.
