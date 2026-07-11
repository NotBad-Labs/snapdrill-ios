# Phase 04d Results: Image Filesystem And Privacy Integrity

## Base And Coverage

- rebaseline reference: `develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- product base: `origin/develop@56e9d27e29e39fdcec083c4ec4e8a230edaa7f84`
- candidate comparison: `codex/single-library-rebaseline@b670a2c8`, Draft PR #868
- covered: ImageStorage writes/reads/deletes, persisted primary/answer paths,
  capture/edit/delete ordering, Profile directory deletion, backup image pack and
  restore, Share Extension handoff, Capture drafts, EXIF/GPS and directly relevant tests
- excluded: camera/scanner UX, OCR/crop quality, v3 crash-recovery design and generic
  performance work without a measured failure

The existing V2 `04c` brief remains superseded. This slice inspected image sinks
on the fixed base but did not revive the retired Profile backup contract or modify
the v3 candidate.

## Independent Review Status

| Reviewer | Runtime | Outcome | Normalization note |
|---|---|---|---|
| Codex C1 | current C1 | complete | reopened every cited path and ran a detached three-hypothesis probe |
| Claude | Claude Code `2.1.206`, `claude-fable-5[1m]` | complete | independently found the backup export escape; classified it P1 |
| Antigravity | `1.1.1`, Gemini 3.5 Flash (High) | complete | found edit re-encoding, but falsely stated the live path guard requires an `images/` prefix |
| Grok | `0.2.93`, `grok-4.5` | complete | bundle exceeded 50 MiB; local Read/Grep/Glob review completed and found the export escape |

All reviewers used the clean fixed checkout and no prior audit result. The first
Antigravity path-guard conclusion was rejected against live
`ImageStorage.swift:204-215`. No reviewer changed the fixed checkout, audit
worktree or main checkout. Raw reports were not committed.

## Image Lifecycle And Sink Matrix

| Operation | Owner / path | Boundary | Failure ordering |
|---|---|---|---|
| app save | `ImageStorage.saveImage` | UUID under scoped `images/`; final CGImageDestination strips metadata | file first; capture/edit clean new files after handled DB failure |
| app load/file URL | ImageStorage sync/async/downsample/file URL APIs | lexical relative-path guard | unsafe/missing/corrupt returns nil; downsample may fall back to full decode |
| item/delete all | ArchiveRepository / RepositoryContainer | scoped ImageStorage | DB save first, then best-effort file delete; soft-delete keeps files through undo |
| library edit | `LibraryEditViewModel` | scoped ImageStorage | existing loaded images are currently treated as new images on every save |
| avatar | `EditProfileView` | active scoped ImageStorage + preference path | new file precedes preference assignment; no old-file cleanup |
| Capture draft | `CaptureDraftService` | fixed Profile UUID directory/name | uses stripped JPEG data; expiry is load-triggered |
| backup pack | `BackupService.writeProfileImages` | raw DTO path joined to Profile root | missing file skipped; unsafe existing file is read and archived |
| backup restore | BackupService staging + RepositoryContainer DB replacement | ZIP entry lexical checks and size caps | fixed-base DB/old-file ordering remains RA-04-006; v3 residual remains RA-04-008 |
| Share handoff | Share writer -> App Group -> AppRouter -> Capture | production UUID filename; main app rejects separators/dot-dot/NUL | atomic handoff write; successful decode removes handoff; final capture save strips again |
| Profile removal | `ProfileManager.deleteProfile` | UUID-derived Profile directory | list is saved before best-effort detached directory removal |

## Verified Findings

### RA-04-009 — P1 — backup export reads and packages a file outside the owning Profile

`RepositoryContainer.restoreFromProfileData` persists untrusted
`imagePath`/`answerImagePath` strings verbatim. A later backup bypasses
ImageStorage and joins those strings directly to the Profile directory before
`Data(contentsOf:)`. An existing `../outside.jpg` is therefore read and written
to a ZIP entry containing the traversal component.

- evidence: `RepositoryContainer.swift:182-197`;
  `BackupService.swift:156-183`; existing traversal test only covers a missing
  target at `BackupServiceTests.swift:301-350`
- reachability: import a crafted backup, then create a user backup or trigger a
  later pre-restore safety backup
- detached reproduction: created a real file next to the Profile directory,
  supplied `imagePath: "../outside.jpg"`, called `createBackup`, extracted
  `profiles/<id>/../outside.jpg` and byte-compared the private content; passed
- impact: crafted backup state can disclose another Profile/sandbox file into an
  exported archive or permanently break later safety-backup creation by naming a directory
- candidate status: #868 validates every referenced path with the tightened
  `images/<child>` grammar before backup, sanitizes restore writes and includes
  direct backup-rejection plus restore-sanitization tests; unmerged
- next: preserve those v3 regression oracles when #868 is rescaled after the
  product/data contract; merge still needs separate PO authorization

### RA-04-010 — P2 — text-only edits silently re-encode unchanged JPEGs

`loadData` puts the current persisted images into `displayedImage` and
`answerDisplayedImage`. `save()` then calls `persistImages`, which saves every
non-nil displayed image to a new UUID path even when the user changed only text
or taxonomy. The DB switches to the new JPEG and asynchronously deletes the old
file after success.

- evidence: `LibraryEditViewModel.swift:91-111,227-273,304-351`
- detached reproduction: saved an initial image, loaded an edit ViewModel,
  changed only `content`, saved, and asserted the persisted image path changed
  to a second existing UUID; passed deterministically
- impact: normal metadata edits perform lossy JPEG generation after generation,
  create avoidable I/O, and open an orphan window if the app exits before the
  fire-and-forget old-file deletion completes
- candidate status: behavior is unchanged in #868
- next: track explicit primary/answer image replacement state, preserve original
  paths when unchanged, and add text-only plus answer-removal regression tests

### RA-04-011 — P3 — photo-avatar replacement and cancellation orphan files

The avatar picker saves a new JPEG, then checks cancellation and assigns the new
path. It never deletes the previous photo path. Cancellation after the detached
save completes returns before assignment and also leaves the new file unreferenced.

- evidence: `EditProfileView.swift:237-285`; photo/SF-symbol display decisions at
  `EditProfileView.swift:286-309`
- reachability: replace a photo avatar repeatedly, switch back to an SF Symbol,
  or leave the screen while a photo save is completing
- impact: unbounded but user-driven storage leakage in the shared images directory
- candidate status: only the storage owner changes in #868; lifecycle is unchanged
- next: capture the old photo path, delete it only after successful preference
  replacement, and delete a newly saved path when cancellation wins

## Existing Findings Revalidated, Not Duplicated

- RA-04-005 owns the too-broad live image-path grammar: `"images"` and other
  Profile-root relative paths pass the guard and can delete a directory/file.
- RA-04-006 owns fixed-base restore data loss when the optional safety backup is
  absent and old files are removed before image restore.
- RA-04-007 owns missing referenced images being skipped and colliding ZIP names.
- RA-04-008 owns the v3 process-kill window between DB commit and per-file commit
  plus Recovery ZIP launch/retention policy.

## Dynamic Evidence

A detached probe added three characterization tests only, then was removed:

1. backup export extracted byte-identical Profile-external content;
2. text-only Library edit changed the stored image UUID;
3. a Share Data input with a self-checked GPS dictionary produced a JPEG with no GPS dictionary.

The three selected suites contained 28 distinct tests and ran under both test-plan
configurations, for 56 executions total; all passed. The probe worktree and its
DerivedData were deleted. No probe code entered either Draft PR.

## Rejected Or Bounded Candidates

- Share GPS leakage was rejected dynamically for the Data path and statically for
  URL/UIImage re-encode paths; ImageStorage already tests scaled and unscaled GPS removal.
- Percent-encoded `..` is a literal filesystem name because these file APIs do
  not URL-decode path strings.
- ZIP symlink entries are excluded by the `.file` filter and extracted bytes are
  written as regular files. No production path creates a traversable symlink
  under a Profile root; hypothetical local sandbox tampering is not a finding.
- Capture save handles DB failure with context rollback plus both-image cleanup;
  the missing deterministic failure injection remains RA-03-006/Phase 05 test debt.
- Soft delete does not touch files until the undo window commits.
- Backup packing holds one complete JPEG at a time. Normal ImageStorage outputs
  are dimension-bounded; retain broader memory measurement for Phase 09 rather
  than infer OOM from `Data(contentsOf:)` alone.
- A corrupt Share handoff is retained on read/decode failure, but the production
  writer atomically emits a valid JPEG and no external process can write the App
  Group. Phase 11 can consider bounded stale-handoff cleanup without promoting a
  security defect now.

## Handoff

1. No third fix branch opens: write WIP remains Draft PR #867 + #868.
2. #868 already covers RA-04-009 and earlier P1s; it remains frozen pending Gate A,
   a product/data contract and separate merge authorization.
3. RA-04-010/011 need a small post-#868 image-lifecycle slice because their live
   files overlap #868; do not patch the old Profile implementation now.
4. Regenerate `04c` only on the merged v3 baseline, beginning with RA-04-008.
