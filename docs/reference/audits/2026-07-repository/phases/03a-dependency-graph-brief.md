# Phase 03a Brief: Package and Target Graph

> **文档状态：固定基线历史证据。** 本文只描述当时基线，不提供当前排期或执行授权；当前恢复入口见 `docs/reference/audits/2026-07-repository/README.md`，产品规范见 `docs/explanations/vision.md` 与 `docs/reference/release-1-contract.md`。

## Fixed Base

- Product base: `develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- Audit worktree: `/private/tmp/snapdrill-repository-audit`
- Mode: read-only review; do not edit, stage, commit, create files or use network tools

Do not read prior audit findings, phase results, checkpoints, private memory, agent reports or another reviewer's output.

## Question

Does the compiler-enforced package/target graph match the documented one-way architecture, with every direct import and external dependency owned at the narrowest justified boundary?

## Primary Scope

- `Packages/*/Package.swift`
- `Packages/*/Sources/**`
- `SnapDrill.xcodeproj/project.pbxproj`
- `SnapDrill.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- `SnapDrill/App/**`
- `SnapDrillShare/**`
- `docs/explanations/architecture.md`
- Architecture boundaries in `AGENTS.md`

Tests may be read only to verify a claimed compile-time contract. Do not broaden into runtime data correctness or UI review.

## Checks

1. Reconstruct the package, product and native-target DAG from manifests/project files, then compare it with actual module imports.
2. Identify cycles, reverse dependencies, undeclared reliance on transitive products, or a feature target importing another feature without a documented contract.
3. Verify Core has no third-party package dependency and Share Extension remains isolated from Data/Core as documented.
4. Distinguish Apple framework imports from third-party dependencies; do not call platform frameworks a Core dependency violation.
5. Treat a broad dependency as a finding only when it creates a falsifiable build/ownership risk, not merely because finer granularity is possible.

## Output

Use the repository report schema. Return at most eight falsifiable findings with `path:line`, impact and smallest next check; include the reconstructed graph and rejected candidates. `No findings` is valid. Do not propose a new package solely for architectural aesthetics.
