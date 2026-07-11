# Phase 04b Results: Multi-Profile Retirement And Single-Library Rebaseline

## Base And Coverage

- rebaseline reference: `develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- product base: `develop@56e9d27e29e39fdcec083c4ec4e8a230edaa7f84`
- PO ruling: one local library; zero users; no old Profile layout migration or old backup reader
- implementation branch: `codex/single-library-rebaseline@b670a2c8`
- covered: composition ownership, Profile runtime/UI retirement, filesystem layout, backup v3, image-path guards, restore rollback, notifications, drafts, preferences, UI tests and SSOT
- excluded: general ZIP parser/supply-chain review (`04c`/`10c`) and launch-time Recovery ZIP UX (`04c` follow-up)

## Independent Review Status

| Reviewer | Runtime | Outcome | Normalization note |
|---|---|---|---|
| Codex C1 | current C1 | complete | reproduced every promoted finding and implemented the bounded replacement branch |
| Claude | Claude Code `2.1.206`, `claude-fable-5` | complete | full-worktree max-effort run was terminated after no output; the 93KB focused diff review completed read-only |
| Antigravity | `1.1.1`, `Gemini 3.5 Flash (High)` | complete | fixed-base review plus focused implementation review; four cited safety candidates reproduced |
| Grok | `0.2.93`, `grok-4.5` | complete | whole-repo upload exceeded 50 MiB; a generated 93KB read-only review repo completed successfully |

Raw reports remain outside git under `/private/tmp/snapdrill-repository-audit-raw/56e9d27e/04b/` and the focused implementation-review paths. They are evidence inputs, not SSOT.

## Target Ownership

| Concern | Retired owner | Replacement | Result |
|---|---|---|---|
| store/repository lifetime | `ProfileManager` + per-Profile executors | one `LibrarySession` retaining `DataExecutor`, `ModelContainer` and repositories | implemented |
| filesystem | `profiles/<id>/...` | `Application Support/SnapDrill/Library/default.store` + `images/` | implemented |
| Settings data partition UI | `ProfileListView` / ViewModel | none; personal avatar/nickname remains a device preference | retired |
| backup payload | v2 array of Profile payloads | v3 direct `reviewItems` / `dimensions` / `categoryValues` | implemented; old schemas rejected |
| reminders/drafts/tips | Profile-scoped IDs and preference moves | one device/library namespace | implemented |
| restore safety | best-effort temporary backup + DB/file sequencing | preflight, persistent Recovery ZIP, staged images and outer rollback | implemented with residual crash window |

## Verified Findings

### RA-04-005 — P1 — bare `images` path can delete the complete image root

The fixed-base path validator accepts `"images"`. `deleteImage(path:)` then resolves that value to the image directory itself and removes it recursively. A malformed backup can persist the value and later item/full-data deletion reaches the sink.

- evidence: fixed-base `ImageStorage.swift:196-207`; `deleteImage:82-93`
- fix candidate: `7af361de` requires `images/` plus at least one child component, sanitizes restore writes and tests root deletion, traversal, absolute and backslash vectors
- status: verified on develop; fix is committed but unmerged

### RA-04-006 — P1 — restore can mutate without a viable full safety net

The fixed-base coordinator treats pre-restore backup failure as best-effort and continues. Repository restore commits DB replacement and removes old image files before ZIP image restore finishes. Disk pressure or malformed entries can therefore leave rollback without usable old images.

- evidence: fixed-base `SettingsBackupCoordinator.swift:141,188-205,329-349`; `RepositoryContainer.swift:147-211`
- fix candidate: `7af361de` preflights payload/image completeness, requires a persistent `Library/Recovery/*.zip`, retains old files until image success, and uses a tolerant safety snapshot so an already damaged library does not deadlock future recovery
- implementation reviews caught and removed two intermediate defects: safety-backup failure swallowing and strict-missing-image recovery lockout
- status: verified on develop; fix is committed but unmerged

### RA-04-007 — P2 — backup success does not imply referenced-image completeness

Fixed-base backup creation logs and skips missing image files, while payload paths remain encoded. It also names ZIPs at one-second resolution, so a pre-restore safety backup can collide with a just-created source backup.

- evidence: fixed-base `BackupService.swift:82-86,159-174`
- fix candidate: `7af361de` makes user backups fail on missing/unsafe referenced images, validates all payload image entries before mutation, deduplicates the progress denominator and adds UUID filenames; recovery snapshots alone may skip already-missing images
- status: verified on develop; fix is committed but unmerged

### RA-04-008 — P2 — SwiftData and image files still lack one crash-atomic transaction

Staging prevents target writes until all ZIP entries extract, and the persistent Recovery ZIP supports thrown-error rollback. A process kill after DB commit but before image commit can still leave new DB references with old/missing files. Recovery ZIPs left by a crash or failed rollback have no launch-time presentation or bounded retention policy.

- evidence: candidate `SettingsBackupCoordinator.applyRestore`; `BackupService.commitStagedFiles`; `feat-backup.md` known-limit note
- next: regenerate `04c` on the merged v3 baseline; decide transaction marker/launch recovery and retention before external testing
- status: verified residual; no P0/P1 remains after focused review

## Replacement Result

- no production reference remains to `ProfileManager`, `ProfileVault`, `ProfileScope`, Profile list routes or `activeProfileId`
- personal `EditProfileView` is intentionally retained; it edits avatar/nickname/goal, not data partitions
- old Profile source/tests/fixtures are deleted rather than renamed into a hidden singleton abstraction
- backup v3 and single-library specs become the only active contract; v1/v2 rejection is explicit
- code delta at candidate HEAD: 3 commits from `56e9d27e`, including 94 product/test files and 30 SSOT files; no product edit occurred in the audit worktree

## Validation

- `swiftlint --strict`: 234 files, 0 violations
- `AllTests build-for-testing`: passed on iPhone 17 / iOS 26.5 Simulator
- AllTests CI configuration: 476 total, 475 passed, 1 skipped, 0 failed
- Settings UI screenshot flows: 3 passed
- enforced AX audit: 11/11 screens, 0 blocked, 0 issues
- both `Localizable.strings`: `plutil -lint` passed
- feature-status, intent-traceability, docs health, Capture contract, script regression and `git diff --check`: passed; existing legal/fact warnings remain
- main checkout stayed untouched except its pre-existing untracked `agent-reports/`

## Handoff

1. Draft PR #868 is open from `codex/single-library-rebaseline`; do not merge without fresh PO authority.
2. After merge, rebaseline `04c` on v3. The existing V2/Profile brief is superseded and must not be executed.
3. Carry RA-04-008 into `04c` as the first crash-recovery/retention question.
