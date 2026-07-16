# Phase 04b Brief: Single-Library Rebaseline

> **文档状态：固定基线历史证据。** 本文只描述当时基线，不提供当前排期或执行授权；当前恢复入口见 `docs/reference/audits/2026-07-repository/README.md`，产品规范见 `docs/explanations/vision.md` 与 `docs/reference/release-1-contract.md`。

## Fixed Base

- Rebaseline reference: `develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- Product base: `develop@56e9d27e29e39fdcec083c4ec4e8a230edaa7f84`
- Audit worktree: `/private/tmp/snapdrill-repository-audit-phase04`
- Mode: read-only review; do not edit, stage, commit, create files or use network tools

Do not read prior audit findings, phase results, checkpoints, private memory,
agent reports or another reviewer's output.

## PO Ruling

On 2026-07-11 the PO retired Multi-Profile. SnapDrill has no internal or
external test users whose data needs migration. The replacement may discard
development-era Profile stores, preferences and backups. Git history is the
rollback boundary; runtime compatibility with the retired design is not a
requirement.

The target product has exactly one local library:

- no Profile creation, switching, renaming, deletion or Profile UI;
- one SwiftData store, one image root and one set of preferences;
- no Profile identifier in feature-facing environment or routing contracts;
- backup and restore describe one library directly, not an array of Profiles;
- no compatibility reader or migration for old Profile directories or old
  multi-Profile backup payloads.

This ruling authorizes a destructive development-data reset. It does not
authorize weakening current path validation, restore rollback, EXIF privacy,
store recovery or backup size limits.

## Question

What is the smallest coherent replacement architecture and deletion order that
removes Multi-Profile without leaving a hidden singleton Profile abstraction,
cross-layer residue or a period where production can write to mixed layouts?

## Primary Scope

- `SnapDrill/App/{SnapDrillApp.swift,AppRootView.swift}` and app composition
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Model/{Profile.swift,ProfileScope.swift}`
- `Packages/SnapDrillData/Sources/SnapDrillData/Profile*`
- `RepositoryContainer*`, `DataExecutor.swift`, `Backup*`, `ImageStorage.swift`
- Profile-facing Settings UI, environment values, draft storage, TipKit and
  feature preference callers
- directly coupled tests, fixtures, feature specs, architecture and glossary

Inspect callers repository-wide, but keep the report centered on the removal
contract. General model correctness, ZIP parser internals and image encoding are
owned by `04a`, `04c` and `04d`.

## Checks

1. Draw the current construction and ownership path from app launch to store,
   repositories, image root and feature environments.
2. Identify every behavior that exists only for multiple Profiles versus every
   responsibility still needed for one library, including degraded-mode store
   recovery and UI-test in-memory construction.
3. Propose an ordered compile-safe removal plan. Prefer concrete types already
   present over a renamed singleton Profile facade or speculative protocol.
4. Specify the new filesystem and backup payload shape. Since compatibility is
   explicitly out of scope, optimize for one source of truth and testability.
5. Find hidden Profile coupling in UserDefaults keys, drafts, TipKit, telemetry,
   accessibility identifiers, localization, docs and generated status.
6. Identify security or data-safety guards that must survive the rewrite and
   tests whose oracle would become invalid rather than merely need renaming.
7. Separate blockers for the first coherent implementation PR from cleanup that
   can follow without shipping a mixed state.

## Output

Use the repository report schema. Include:

- a current-to-target ownership table;
- an ordered removal plan with bounded PR candidates;
- at most eight falsifiable risks with `path:line` and the smallest verification;
- a keep / replace / retire list for Profile-related types and tests.

`No findings` is valid. Do not implement the redesign or preserve compatibility
that the PO explicitly retired.
