# Phase 04c Brief: Backup Wire, Restore and Rollback

## Fixed Base

- Rebaseline reference: `develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- Product base: `develop@56e9d27e29e39fdcec083c4ec4e8a230edaa7f84`
- Audit worktree: `/private/tmp/snapdrill-repository-audit-phase04`
- Mode: read-only review; do not edit, stage, commit, create files or use network tools

Do not read prior audit findings, phase results, checkpoints, private memory, agent reports or another reviewer's output.

## Question

Can every accepted backup be restored atomically within bounded resources while preserving the V2 wire contract, Profile ownership, images and pre-restore data on failure?

## Primary Scope

- `Packages/SnapDrillData/Sources/SnapDrillData/{BackupDTO.swift,BackupService.swift,ZIPArchiver.swift}`
- RepositoryContainer backup/restore paths and Settings restore orchestration needed to trace commit/rollback
- `Fixtures/BackupWireV2/**`
- `BackupDTOTests.swift`, `BackupService*Tests.swift`, `RepositoryContainerBackupTests.swift`, `ZIPArchiverTests.swift`
- Backup/privacy/compatibility requirements in active specs and reference docs

Exclude redesigning schema fields, changing golden fixtures, generic Profile UI and export formats unrelated to backup.

## Checks

1. Inventory manifest/data/image entries, schema version rules, required/optional fields and compatibility behavior against golden fixtures.
2. Trace validation, extraction, staging, database replacement, image placement and cleanup for success and every thrown failure boundary.
3. Verify path traversal, duplicate entries, symlinks, malformed ZIP metadata, declared-vs-actual size and single/total extraction limits cannot escape or exhaust the process.
4. Prove restore rollback retains the previous Profile store/images/preferences when decoding, extraction, staging or persistence fails.
5. Check export/restore round-trip parity for text-only, image, answer-image, dimensions, review state and Profile metadata; do not treat fixture absence alone as a behavior defect.

## Output

Use the repository report schema. Include a backup compatibility/rollback matrix and at most eight falsifiable findings with `path:line`, deterministic reproduction and smallest next check. `No findings` is valid. The V2 wire, schema version and golden fixtures are immutable in this slice.
