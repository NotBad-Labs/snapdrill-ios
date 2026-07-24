# Phase 03b Brief: Runtime Dependency Flow

> **文档状态：固定基线历史证据。** 本文只描述当时基线，不提供当前排期或执行授权；当前恢复入口见 `docs/reference/audits/2026-07-repository/README.md`，产品规范见 `docs/product/vision.md` 与 `docs/product/release-1-prd.md`。

## Fixed Base

- Product base: `develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- Audit worktree: `/private/tmp/snapdrill-repository-audit`
- Mode: read-only review; do not edit, stage, commit, create files or use network tools

Do not read prior audit findings, phase results, checkpoints, private memory, agent reports or another reviewer's output.

## Question

At runtime, do composition root, Environment injection, service/repository lifetimes and Profile switching preserve one instance graph and the documented View -> ViewModel -> Repository -> DataExecutor flow?

## Primary Scope

- `SnapDrill/App/**`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/DI/**`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Service/**`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/AppActivityTracker.swift`
- `Packages/SnapDrillData/Sources/SnapDrillData/{ProfileManager*,RepositoryContainer*,DataExecutor.swift}`
- Feature View/ViewModel construction and `@Environment` access points needed to trace identities
- Relevant focused tests
- `docs/explanations/architecture.md`

Do not audit backup/SwiftData correctness beyond what is necessary to prove an architectural lifetime or injection defect; those belong to Phase 04.

## Checks

1. Trace production, UI-test, preview and unit-test instance creation separately; do not assume default Environment values are production paths.
2. Check whether a service exposed through `ServiceContainer` is also reached through a static singleton or second Environment key, and whether identities can diverge.
3. Verify Profile switch guards observe the same activity tracker used by capture/export/backup/print operations.
4. Locate direct `ModelContext`/`ModelContainer` use in Views and classify debug/preview-only exceptions separately from production behavior.
5. Check fallback/default objects for silent production use, lifetime leaks or false test confidence; require a reachable path before assigning severity.

## Output

Use the repository report schema. Return at most eight falsifiable findings with `path:line`, impact and smallest next check; include one production instance-flow diagram and rejected candidates. `No findings` is valid. Do not turn test seams into speculative protocols.
