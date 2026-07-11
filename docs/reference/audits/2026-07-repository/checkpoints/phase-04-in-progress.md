# Phase 04 In-Progress Checkpoint

## T0

- rebaseline reference: `develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- product base: `origin/develop@56e9d27e29e39fdcec083c4ec4e8a230edaa7f84`
- main checkout: remains at `d62fead8`; only pre-existing untracked `agent-reports/`, untouched
- worktree: `/private/tmp/snapdrill-repository-audit-phase04`
- branch: `codex/repository-audit-phase04`
- phase start HEAD: `56e9d27e29e39fdcec083c4ec4e8a230edaa7f84`
- open write work: audit branch only; Draft PR #864 was closed with PO authority;
  write WIP = 1

## Frozen Slices

- `04a`: SwiftData models, relationships, repository save/delete and migration baseline
- `04b`: destructive Multi-Profile retirement and single-library replacement
- `04c`: backup V2 wire, ZIP validation, restore staging, rollback and round-trip
- `04d`: image paths, Profile filesystem ownership, EXIF privacy and orphan cleanup

Each slice uses the same product base and an independent neutral brief. Claude, Antigravity and Grok remain read-only reviewers; Codex C1 reproduces every candidate before ledger entry.

## PO Decisions

- Draft PR #864 was closed on 2026-07-11. Any retained work must later be
  respun as separate App Store copy, legal copy and SmartPaper copy slices.
- If Phase 04 verifies a P0/P1, C1 may open a second bounded fix worktree and
  Draft PR without further approval. Merge remains separately authorized.
- Multi-Profile is retired. The target is one local library with no Profile UI,
  lifecycle or feature-facing Profile identity.
- SnapDrill has no test users whose data must survive this change. Development
  Profile stores, Profile preferences and multi-Profile backups may be discarded;
  no migration or compatibility reader is required. Git is the rollback boundary.
- The interrupted external `04b` runs used the superseded Multi-Profile brief and
  were discarded before normalization; they are not audit evidence.

## Recovery

- `04a` complete: `phases/04a-results.md`; 2×P2 and 2×P3, no P0/P1
- next action: run independent `04b` reviews from
  `phases/04b-single-library-brief.md`
- stop conditions: base drift, write WIP above 2, verified destructive P0/P1 without fix authority, or a required dynamic probe that cannot run
