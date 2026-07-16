# Phase 04a Brief: SwiftData Models and Repository Integrity

> **文档状态：固定基线历史证据。** 本文只描述当时基线，不提供当前排期或执行授权；当前恢复入口见 `docs/reference/audits/2026-07-repository/README.md`，产品规范见 `docs/explanations/vision.md` 与 `docs/reference/release-1-contract.md`。

## Fixed Base

- Rebaseline reference: `develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- Product base: `develop@56e9d27e29e39fdcec083c4ec4e8a230edaa7f84`
- Audit worktree: `/private/tmp/snapdrill-repository-audit-phase04`
- Mode: read-only review; do not edit, stage, commit, create files or use network tools

Do not read prior audit findings, phase results, checkpoints, private memory, agent reports or another reviewer's output.

## Question

Do the current SwiftData schema, relationship rules and repository save/delete paths preserve model invariants and recover cleanly from duplicate, relationship and persistence failures?

## Primary Scope

- `Packages/SnapDrillData/Sources/SnapDrillData/{ArchiveItemModel*,CategoryDimensionModel.swift,CategoryValueModel.swift,MigrationPlan.swift}`
- `Packages/SnapDrillData/Sources/SnapDrillData/{ArchiveRepository.swift,CategoryDimensionRepository.swift,CategoryValueRepository.swift,DataExecutor.swift}`
- Corresponding model, repository, migration and executor tests
- Active feature specs only where they define a model invariant or deletion contract

Exclude Profile lifecycle, backup wire/archive parsing and filesystem image contents except where a stored path or relationship is part of the model invariant.

## Checks

1. Inventory every persisted property, default, relationship, delete rule, index and sentinel value; distinguish schema-enforced constraints from repository-only rules.
2. Trace insert/update/delete and save failure paths through `DataExecutor`, including rollback and stale-model behavior.
3. Verify single-value dimensions, built-in `systemKey` uniqueness, item content/image requirements and model ID uniqueness have reachable enforcement or an explicit accepted boundary.
4. Check relationship deletion for dangling values, orphan references, partial saves and restart consistency; do not infer a defect from `.nullify` alone.
5. Compare current V1 schema and migration tests with the zero-user release baseline; do not propose a V2 schema without a demonstrated compatibility need.

## Output

Use the repository report schema. Include a persisted-model invariant table and at most eight falsifiable findings with `path:line`, deterministic reproduction and smallest next check. `No findings` is valid. Do not change schema or recommend CloudKit-driven constraints in this slice.
