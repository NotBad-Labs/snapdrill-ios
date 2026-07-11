# Phase 04d Brief: Image Filesystem and Privacy Integrity

## Fixed Base

- Rebaseline reference: `develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- Product base: `develop@56e9d27e29e39fdcec083c4ec4e8a230edaa7f84`
- Audit worktree: `/private/tmp/snapdrill-repository-audit-phase04`
- Mode: read-only review; do not edit, stage, commit, create files or use network tools

Do not read prior audit findings, phase results, checkpoints, private memory, agent reports or another reviewer's output.

## Question

Do all image-producing, loading, backup/restore and deletion paths keep files inside the owning Profile, strip prohibited metadata and avoid orphaning or deleting user data across partial failures?

## Primary Scope

- `Packages/SnapDrillCore/Sources/SnapDrillCore/Capture/ImageStorage.swift`
- Stored `imagePath` and `answerImagePath` consumers in Data/Features needed to prove filesystem behavior
- Backup image staging/extraction and Profile directory ownership
- `SnapDrillShare/{ShareImageDownsampler.swift,SharedContainerImageWriter.swift}` and main-App import boundary
- Image, backup and capture-persistence tests directly tied to the filesystem contract

Exclude camera/scanner UX, OCR quality and crop behavior; those belong to Phase 05.

## Checks

1. Enumerate every image write/read/delete/copy/move sink for primary and answer images, including Share Extension and backup restore.
2. Test relative, absolute, dot-component, empty-component, backslash, encoded and symlink-assisted path escape candidates at every reachable sink.
3. Verify persisted JPEGs and Share handoff files remove GPS/location metadata and do not retain unintended source metadata.
4. Trace image/database ordering for save, edit, delete, undo, Profile deletion and failed restore; identify only reproducible orphan or premature-delete behavior.
5. Check temporary-file cleanup, missing/corrupt image behavior and large-image memory boundaries without broadening into visual quality review.

## Output

Use the repository report schema. Include an image lifecycle/sink table and at most eight falsifiable findings with `path:line`, deterministic reproduction and smallest next check. `No findings` is valid. Do not change image format, compression policy or user-visible behavior in this slice.
