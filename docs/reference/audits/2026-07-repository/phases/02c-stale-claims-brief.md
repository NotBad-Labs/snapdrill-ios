# Phase 02c Brief: Stale Claims and Evidence Ownership

> **文档状态：固定基线历史证据。** 本文只描述当时基线，不提供当前排期或执行授权；当前恢复入口见 `docs/reference/audits/2026-07-repository/README.md`，产品规范见 `docs/explanations/vision.md` 与 `docs/reference/release-1-contract.md`。

## Fixed Base

- Product base: `develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- Audit worktree: `/private/tmp/snapdrill-repository-audit`
- Mode: read-only review; do not edit, stage, commit, create files or use network tools

Do not read prior audit findings, phase results, checkpoints, private memory, agent reports or another reviewer's output.

## Question

Which tracked claims or evidence are presented as current but have been invalidated by later code, configuration or product decisions, and which historical artifacts still have a clear owner and interpretation?

## Primary Scope

- Root `README.md` and `AGENTS.md`
- `docs/reference/non-functional-requirements.md`
- `docs/reference/appstore-metadata.md`
- `docs/reference/analytics-events.md`
- `docs/reference/apple-platform-limits.md`
- `docs/reference/scope-and-roadmap.md`
- `docs/explanations/privacy-compliance.md`
- `docs/ui-redesign/`
- Relevant live configuration, sources, tests and Git history needed to verify a specific claim

## Checks

1. Verify drift-prone platform, signing, privacy, feature, performance and release claims against the fixed base.
2. Treat `last_verified`, a passing validator and a screenshot as evidence with scope, not proof of current truth.
3. Check whether UI screenshots and matrices are current verification, historical evidence or unlabeled mixtures.
4. Check whether public-facing metadata matches the current product positioning and terminology while respecting explicit legal/PO gates.
5. Do not call an old artifact waste merely because newer code exists; require missing ownership, misleading placement or broken references.

## Output

Use the repository report schema. Return at most eight falsifiable findings with `path:line`, impact and smallest next check; list rejected candidates separately. `No findings` is valid. Do not edit or delete evidence.
