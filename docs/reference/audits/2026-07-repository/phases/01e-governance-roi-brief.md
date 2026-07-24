# Phase 01e Brief: Governance and Documentation ROI

> **文档状态：固定基线历史证据。** 本文只描述当时基线，不提供当前排期或执行授权；当前恢复入口见 `docs/reference/audits/2026-07-repository/README.md`，产品规范见 `docs/product/vision.md` 与 `docs/product/release-1-prd.md`。

## Fixed Evidence

- base: `develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- Git history snapshot: `/private/tmp/snapdrill-repository-audit-phase01/git-numstat.txt`
  (SHA-256 `f31d9b77a6749334d39a355e6e467a166324938cec4e452edbf9eb4351408053`)
- current repository tree and history at the fixed base

## C1 Starting Signal

A deliberately broad process/governance bucket has 256,694 numeric line changes;
245,453 are on raw paths no longer tracked. This is not yet a finding: the bucket
mixes product SSOT, agent instructions, audit evidence, generated documents, scripts
and temporary status material, and raw paths do not normalize renames.

## Question

How much of the apparent governance/documentation churn is content-preserving
migration, durable control-plane investment, one-off evidence, obsolete policy or
avoidable rebuild-and-purge work?

## Rules

- New session. Do not read another agent report, private memory or chat history.
- Read-only local analysis only. No network, edits or builds.
- Start with path-level semantic classification, then quantify. Do not label every
  `docs/` line as process work or waste.
- Normalize renames and trace replacements using `git log --follow`, diffs, current
  references, validators, hooks and CI enforcement.
- Sample the largest absent paths and the claimed March-May rebuild/purge sequence.
  Record evidence both for and against useful preservation.
- Distinguish decision quality at the time from hindsight after the current leaner
  system existed.

## Output

Return concise Markdown with Metadata, Method, Decontaminated Buckets, Replacement
Tracing, Rebuild-and-Purge Sequences, Durable Value Counterexamples, Candidate
Findings, Rejected Claims, Missing Evidence and Handoff. Every quantitative claim
needs a reproducible command or script and every semantic claim needs file/SHA
evidence.
