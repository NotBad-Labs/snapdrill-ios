# Phase 04 In-Progress Checkpoint

> **文档状态：固定基线历史证据。** 本文只描述当时基线，不提供当前排期或执行授权；当前恢复入口见 `docs/reference/audits/2026-07-repository/README.md`，产品规范见 `docs/explanations/vision.md` 与 `docs/reference/release-1-contract.md`。

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
- `04c`: superseded V2 brief; regenerate from merged single-library v3 before execution
- `04d`: image paths, Profile filesystem ownership, EXIF privacy and orphan cleanup; complete

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

- **2026-07-12 status**: #867 audit evidence, #869 Gate A activation and #870
  Simplified-Chinese workshop have merged. Gate A is effective. The PO then
  approved B1-A through B7-A individually; `codex/gate-b-product-constitution-v1`
  is the bounded authority branch that will make Gate B effective only after a
  separate merge authorization. Gate C remains open and #868 remains Draft.

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
- On 2026-07-11 the PO ratified all three Gate A rules. PR #869 later landed the
  activation clause on `develop`; that ruling is now effective and did not
  authorize #868 or later contract merges.
- While Gate A awaited PO response, `02e` produced a non-normative workshop
  candidate with options for workflow wedge, promise, data posture, single
  library, commercial/platform scope, Release 1 outcomes and optional features.
- Three-agent challenge rejected preselected answers and forced revisions:
  workflow rather than demographic wedge; product behavior separate from
  `ProfileManager` implementation; hidden SmartPaper as the current pure-free
  recommendation; Dashboard/Review IA as time-bounded dogfood; explicit failure,
  recovery, TestFlight and no-telemetry learning evidence.
- C1 rejected unsupported reviewer claims about missing EXIF tests, absent
  capture rollback and inevitable App Store rejection; primary code/tests show
  the first two are false and no Apple/legal source supported the third.
- `02f` mapped Gate B/C blast radius from authority through runtime, wire,
  public and verification consumers. Independent review added live App Group
  identity paths, onboarding/export behavior, frozen-wire compatibility or
  explicit rejection, the native `UITests` plan and shared preference seams.
- The map rejected retargeting #867 into a normative contract branch. #867 has
  since merged; the separate Gate B authority branch now occupies the second
  write slot while #868 stays frozen implementation evidence.

## Phase 04d Image Integrity

- Codex, Claude Fable 5, Antigravity Gemini 3.5 Flash (High) and Grok 4.5
  independently reviewed the fixed base. C1 rejected Antigravity's false claim
  that the live guard requires an `images/` prefix.
- A detached probe proved that backup export packages an existing Profile-external
  file named by malicious `imagePath`, that text-only edits replace the image UUID,
  and that the Share Data path strips a self-checked GPS dictionary.
- Three findings were added: RA-04-009 P1 backup-export escape (already addressed
  in unmerged #868), RA-04-010 P2 edit re-encoding and RA-04-011 P3 avatar orphans.
- Existing restore loss/root-delete findings remain RA-04-006/005 and were not
  double counted. The probe worktree/DerivedData were deleted.

## Recovery

- `04a` complete: `phases/04a-results.md`; 2×P2 and 2×P3, no P0/P1
- `04b` complete: `phases/04b-results.md`; 2×P1 and 2×P2; P1 fixes committed at
  `codex/single-library-rebaseline@b670a2c8` in Draft PR #868, not merged
- `02d` Gate A effective via #869: `phases/02d-product-constitution-results.md`;
  Gate B B1-A through B7-A ratified on 2026-07-12, Gate C remains open
- `02e` workshop packet/review complete: `phases/02e-po-product-workshop-candidate.md`
  and `phases/02e-product-workshop-review-results.md`; no new ledger finding
- `02f` impact map/review complete: `phases/02f-product-intent-impact-map-candidate.md`
  and `phases/02f-product-impact-review-results.md`; no new ledger finding
- `04d` complete: `phases/04d-results.md`; 1×P1, 1×P2 and 1×P3 new findings;
  P1 candidate fix is already in frozen Draft PR #868
- next action: validate and manually review Product Constitution v1, then obtain
  separate merge authorization; only after it is effective start the Release 1
  Product Contract. No #868 merge request and no `04c` regeneration yet
- stop conditions: base drift, write WIP above 2, verified destructive P0/P1 without fix authority, or a required dynamic probe that cannot run
