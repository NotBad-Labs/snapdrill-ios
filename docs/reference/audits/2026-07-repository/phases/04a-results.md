# Phase 04a Results: SwiftData Models and Repository Integrity

## Base And Coverage

- rebaseline reference: `develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- product base: `develop@56e9d27e29e39fdcec083c4ec4e8a230edaa7f84`
- brief checkpoint: `4335cdaf`
- covered: three persisted models, V1 schema/migration plan, three repositories, DataExecutor, cross-repository delete/restore seams and directly relevant tests/spec contracts
- excluded: Profile lifecycle, backup wire validation and image bytes; candidates requiring those owners are routed to `04b`/`04c` instead of being promoted early

## Independent Review Status

| Reviewer | Runtime | Outcome | Normalization note |
|---|---|---|---|
| Codex C1 | current C1 | complete | reopened every cited path; ran existing and one-time probe tests |
| Claude | Claude Code `2.1.206`, `claude-fable-5[1m]` | complete | report lacked Shell access to self-report exact CLI metadata; invocation contract is authoritative |
| Antigravity | `1.1.1`, `Gemini 3.5 Flash (High)` | complete | report self-labelled CLI/model imprecisely; invocation was pinned and no fallback occurred |
| Grok | `0.2.93`, `grok-4.5` | complete | repository bundle exceeded 50 MiB; local Read/Grep/Glob review completed |

Raw reports stayed under `/private/tmp/snapdrill-repository-audit-raw/56e9d27e/04a/` and were not committed.

## Invariant Classification

| Invariant | Current owner | Result |
|---|---|---|
| V1 model membership/defaults/sentinels/indexes | schema + migration plan | keep; disk and in-memory round-trip tests pass |
| dimension name and value-name uniqueness | repository create paths | keep; restore-time bypass moves to `04c` |
| built-in dimensions cannot be user-deleted | UI + repository guard | keep |
| value/dimension deletion detaches item relationships | repository | keep; 20-item probe found no mutation-during-enumeration loss |
| item has content or image | Capture/Edit orchestration | accepted application-layer boundary; one test name is false evidence |
| single-value dimension has at most one linked value | UI writers only | repair/pending PO; changing an existing multi-value dimension breaks the semantic invariant |
| failed save leaves shared context clean | caller + repository rollback | repair; two reachable create-value callers omit rollback |
| built-in `systemKey` and backup IDs are unique | not enforced below restore | `04c` candidate; malformed backup reachability must be settled there |

## Verified Findings

### RA-04-001 — P2 — failed inline value creation can leak into a later save

`CaptureResultViewModel.createValue` and `LibraryEditViewModel.createValue` call `fetchOrCreate`, which inserts a pending `CategoryValueModel`, then call `saveContext`; their catch blocks report failure but do not roll back. The shared ModelContext contract explicitly requires rollback after a failed save, and sibling mutation paths already do so.

- evidence: `CaptureResultViewModel.swift:226-238`; `LibraryEditViewModel.swift:167-179`; `CategoryValueRepository.swift:65-80`; `feat-capture.md:73`; `feat-library.md:42`
- impact: after a user-visible create failure, a later unrelated successful save can persist a taxonomy value that the UI reported as failed
- next: bounded code slice should add rollback in both catch paths and a deterministic injected save-failure oracle; general `insertAndSave` hardening can be evaluated in the same slice without changing repository contracts

### RA-04-002 — P2 — multi-to-single conversion preserves conflicting links

The custom-dimension toggle changes only `isMultiValue`. Existing items with multiple values retain all links; the single-value UI displays the first sorted value while all linked menu entries remain selected.

- evidence: `CategoryValueListView.swift:79-84`; `CategoryValueListViewModel.swift:139-154`; `DimensionInputRow.swift:97-115,166-169`
- dynamic reproduction: one-time detached probe created an item linked to A+B, persisted `isMultiValue=false`, reopened the item and observed two links; probe passed because it asserted current behavior
- status: `pending-po`
- recommended rule: block multi-to-single conversion while any item has more than one value in that dimension; do not silently discard links

### RA-04-003 — P3 — image-only boundary test does not create an image-only item

`ArchiveRepositoryTests.nilContentWithImagePath` is named as an image-path case, but its helper hardcodes `imagePath:nil`; the test proves a fully empty item persists below the UI rather than the named boundary.

- evidence: `ArchiveRepositoryTests.swift:31-40,129-138`
- next: make the named test pass a path and add an explicit test/comment for the accepted schema-permissive both-nil boundary

### RA-04-004 — P3 — public taxonomy wipe API has no caller or test

`RepositoryContainer.deleteAllTaxonomy()` contains invariant-critical detach/save/rollback logic but has no production or test caller. Live restore and full-delete paths use the private in-memory helper instead.

- evidence: `RepositoryContainer.swift:100-116`; repository-wide `rg -n 'deleteAllTaxonomy\(' --glob '*.swift'`
- next: classify `retire` or add an owning use case/test in synthesis; do not delete during the audit

## Rejected Or Routed Candidates

- duplicate-name failure does not leave a dirty insert: validation throws before `modelContext.insert`; Antigravity's proposed reproduction was invalid.
- deleting an in-use value at repository level is not a current user-path violation: both Library management ViewModels block it; repository detach is an internal consistency capability.
- mutating inverse relationships during delete did not skip or crash with 20 referencing items in the one-time probe.
- repeated unsaved `fetchOrCreate` returned the same pending inverse value and persisted one row in the one-time probe.
- `fetchDueCount`/`fetchSmartSelection` memory paths are documented fallbacks; without scale measurement they route to Phase 06/09, not a data-safety finding.
- duplicate `systemKey` is accepted by the repository probe, but normal UI creation uses `nil` and initial seed is atomic. Backup restore is the reachable untrusted path, so severity and fix owner remain in `04c`.
- no V2 schema, `#Unique`, CloudKit redesign or relationship rewrite is justified by this slice.

## Validation

- existing focused tests: 53 tests across six reported suites, all passed
- one-time detached probe: 17 tests, all passed; confirmed duplicate `systemKey` acceptance and multi-to-single residual links; rejected relationship-iteration and unsaved-fetch duplication hypotheses
- probe worktree was removed after recording results; no probe code entered the audit branch
- audit worktree remained clean throughout external review

## Handoff

- proceed to `04b` Profile isolation/migration on the same product base
- carry RA-04-001 to a bounded fix only after write WIP is available and PO grants P2 implementation priority
- obtain PO decision for RA-04-002 before designing a migration or destructive normalization
