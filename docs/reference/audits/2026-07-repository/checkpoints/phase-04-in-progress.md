# Phase 04 In-Progress Checkpoint

## T0

- rebaseline reference: `develop@d62fead87fb103708652ac5378eda8e2c03f8257`
- product base: `origin/develop@56e9d27e29e39fdcec083c4ec4e8a230edaa7f84`
- main checkout: remains at `d62fead8`; only pre-existing untracked `agent-reports/`, untouched
- worktree: `/private/tmp/snapdrill-repository-audit-phase04`
- branch: `codex/repository-audit-phase04`
- phase start HEAD: `56e9d27e29e39fdcec083c4ec4e8a230edaa7f84`
- open write work: audit branch plus `codex/single-library-rebaseline` implementation branch;
  Draft PR #864 was closed with PO authority; write WIP = 2

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
- Superseded initial runs were discarded. Fresh fixed-base and focused candidate
  reviews completed under the single-library ruling.

## Product Constitution Interlude

- On 2026-07-11 the PO questioned whether product intent and requirements were
  stable enough to keep driving downstream work. Phase 02 was reopened as the
  bounded `02d` product-constitution slice; no third write branch was created.
- `02d` verified five structural findings: PO intent lacks an activation
  lifecycle; the current release lacks a bounded product contract; downstream
  docs can originate cross-feature invariants; decision records mix product and
  architecture authority; SmartPaper bet guidance conflicts.
- Claude Fable 5, Antigravity Gemini 3.5 Flash (High) and Grok 4.5 ran read-only
  fixed-base reviews. C1 retained only claims reproduced on live primary files;
  exaggerated subscription/iPad blockers and agent severity inflation were
  rejected.
- Draft PR #868 remains implementation evidence. Its 126-file blast radius is
  also evidence that single-library must be classified as a durable product
  boundary or Release 1 simplification before merge authorization is considered.
- PO Gate A is now the earliest dependency: decision lifecycle, legacy-baseline
  default and contract-first rule for high-blast changes. The recommended rules
  are recorded in `phases/02d-product-constitution-results.md`.

## Recovery

- `04a` complete: `phases/04a-results.md`; 2×P2 and 2×P3, no P0/P1
- `04b` complete: `phases/04b-results.md`; 2×P1 and 2×P2; P1 fixes committed at
  `codex/single-library-rebaseline@b670a2c8` in Draft PR #868, not merged
- `02d` complete pending PO rulings: `phases/02d-product-constitution-results.md`;
  4×P2 and 1×P3, with four findings requiring product/governance ratification
- next action: obtain PO Gate A rulings, then draft Product Constitution v1 and
  Release 1 Product Contract; no #868 merge request and no `04c` regeneration yet
- stop conditions: base drift, write WIP above 2, verified destructive P0/P1 without fix authority, or a required dynamic probe that cannot run
