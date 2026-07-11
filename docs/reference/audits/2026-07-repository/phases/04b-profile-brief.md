# Phase 04b Brief: Profile Isolation and Migration (Superseded)

> Superseded by `04b-single-library-brief.md` after the PO retired Multi-Profile
> on 2026-07-11. No review run against this brief is valid evidence for the
> current product. The file remains only to preserve the audit trail.

## Fixed Base

- Rebaseline reference: `develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- Product base: `develop@56e9d27e29e39fdcec083c4ec4e8a230edaa7f84`
- Audit worktree: `/private/tmp/snapdrill-repository-audit-phase04`
- Mode: read-only review; do not edit, stage, commit, create files or use network tools

Do not read prior audit findings, phase results, checkpoints, private memory, agent reports or another reviewer's output.

## Historical Question

Do Profile creation, loading, switching, deletion and legacy migration preserve strict store/image/preference isolation without data loss, cross-profile leakage or silent fallback?

## Primary Scope

- `Packages/SnapDrillCore/Sources/SnapDrillCore/Model/{Profile.swift,ProfileScope.swift}`
- `Packages/SnapDrillData/Sources/SnapDrillData/Profile*`
- `Packages/SnapDrillData/Sources/SnapDrillData/{RepositoryContainer*,DataExecutor.swift}`
- App composition and Settings/Profile callers needed to prove reachable lifecycle behavior
- `ProfileTests.swift`, `ProfileVaultTests.swift`, `ProfileMigrationTests.swift` and directly relevant feature tests

Exclude general repository invariants, backup ZIP parsing and image encoding except where Profile directory ownership is the contract.

## Checks

1. Trace first launch, normal relaunch, UI-test construction, profile create/switch/rename/delete and store recovery as separate paths.
2. Verify `profiles.json`, active Profile ID, database, images and per-profile preferences commit or roll back as a coherent lifecycle operation.
3. Check malformed, duplicate, missing and unreadable Profile metadata behavior; distinguish safe empty state from silent data disappearance.
4. Verify dynamic and fixed UserDefaults keys migrate, clear and restore without process-global test pollution or cross-profile leakage.
5. Confirm the fix merged in PR #866 removes normal-construction preference clearing while preserving explicit UI-test cleanup; do not report the fixed old behavior as current.

## Output

Use the repository report schema. Include a Profile state-transition table and at most eight falsifiable findings with `path:line`, deterministic reproduction and smallest next check. `No findings` is valid. Do not alter Profile wire/layout or invent a new migration system.
