# Phase 02e Results: Product Workshop Candidate Review

> **文档状态：固定基线历史证据。** 本文只描述当时基线，不提供当前排期或执行授权；当前恢复入口见 `docs/reference/audits/2026-07-repository/README.md`，产品规范见 `docs/explanations/vision.md` 与 `docs/reference/release-1-contract.md`。

## Outcome

The first candidate was useful shaping input but not PO-ready as written. Codex, Claude Fable 5, Antigravity Gemini 3.5 Flash (High) and Grok 4.5 converged that several “recommended” cells could harden current implementation or an unmerged simplification into product truth before evidence. The candidate was revised; it remains explicitly non-normative.

No new ledger finding was created. The challenges refine the PO options already routed by RA-02-013/014/015/017; they do not prove a new product defect or select an answer.

## T0

- product base: `origin/develop@56e9d27e29e39fdcec083c4ec4e8a230edaa7f84`
- primary checkout: `/Users/yiming/Developer/snapdrill-audit-fixed-56e9d27e`, read-only and clean
- candidate/review worktree: `/private/tmp/snapdrill-repository-audit-phase04`
- open write WIP: Draft PR #867 + Draft PR #868; no third branch
- main checkout remained at `d62fead8`; pre-existing `agent-reports/` untouched

## Converged Challenges

### 1. A workflow wedge is not a proven demographic

- Vision and positioning allow sharp exam/question/training workflows but define a broader adult general-audience product.
- User journeys and implemented answer/SM-2 structures show design fit, not external demand or acquisition proof.
- Revision: B1-A now names “structured paper/PDF material needing organization and print,” with exam, certification, training and adult-managed family material as examples. It is a medium-confidence TestFlight hypothesis with no external demand/willingness-to-pay evidence.

### 2. Single-library product behavior and implementation strategy must be separate

- Fixed-base `develop` still treats Multi-Profile as implemented Must; the post-base retirement instruction is not effective under the proposed Gate A.
- #868's 126-file reduction proves impact and feasibility, not user need.
- Revision: Gate A step 0 asks PO to ratify/reject the post-base ruling. B5 asks only what users see and whether future workspaces are planned. Engineering later chooses the simplest implementation; PO is not asked whether `ProfileManager` survives.

### 3. Unlimited free SmartPaper is not a harmless temporary switch

- Current tracked policy is 3/month basic random selection with Pro precise SM-2 selection, deduct-on-export and a visible non-Pro entry.
- Unlimited free use can create a durable expectation and weaken future pricing; current quota with no purchasable upgrade creates a trust-breaking dead end.
- Revision: hiding SmartPaper is the medium-confidence pure-free recommendation; unlimited options require explicit ADR-001 suspension/supersession and a separate choice of random versus precise selector. Internal-only exposure remains an evidence option.

### 4. Equal top-level tabs create accidental product commitments

- Live app has five equal tabs and launches to Dashboard, while Vision calls Review optional and prioritizes capture/manage/export.
- Keeping current IA is a low-churn experiment, not a neutral product decision. Public screenshots and muscle memory can harden it by inertia.
- Revision: Dashboard/Review status quo recommendations were demoted; options now include defaulting to Capture/Library and putting Review behind a secondary entry. PO must re-decide after the first structured feedback packet.

### 5. Release outcomes needed stronger failure/trust coverage

Accepted additions:

- save succeeds without OCR; permission denial has an alternate path;
- cancellation/draft recovery creates no partial records;
- backup restore cannot silently overwrite/lose the prior library;
- corrupt-store recovery reaches a real choice instead of a blank screen;
- local/uninstall data-loss notice and no unexpected content upload;
- TestFlight main-app/App-Group/Share-Extension round trip;
- support/privacy/feedback path for the selected tester audience;
- first external build establishes the compatibility boundary.

### 6. No-telemetry posture requires an explicit learning instrument

- Apple aggregate metrics cannot prove first-task completion, retrieval success or intentional Review/SmartPaper use.
- Revision: a product/research DRI must run scripted moderated dogfood, collect explicit TestFlight feedback and conduct a short follow-up. PO accepts the method before external dogfood.

## C1 Rejected Challenges

### Preserve hidden Multi-Profile code for optionality

Rejected as a default recommendation. Keeping inactive Profile lifecycle, preferences, backup and failure states is speculative flexibility with known cross-cutting cost. The workshop now exposes that option fairly, but after PO chooses product behavior, engineering — not PO — owns whether any abstraction is justified.

### Capture has no storage-failure rollback

Rejected as a factual claim. `CaptureSaveCoordinator.swift:44-84` catches image or context failures, rolls back the repository context and cleans already-written orphan images. A deterministic disk/storage failure test can still strengthen Release 1 evidence; absence of such a test does not prove absence of rollback behavior.

### EXIF/GPS stripping lacks an automated oracle

Rejected. `ImageStorageTests.swift:153-170` constructs a source JPEG with a GPS dictionary, self-checks the fixture and asserts both scaled and unscaled outputs contain no GPS metadata.

### Simplified Chinese exam terminology creates a specific US App Store rejection risk

Rejected as an unsupported legal/platform prediction. The valid requirement is narrower: metadata, screenshots and in-app copy must match the ratified general-audience posture and pass legal/platform fact gates. No reviewer supplied Apple primary evidence for the stronger rejection claim.

### Adults preparing for exams will not accept local-first storage

Rejected as a fact; no user evidence exists. It remains a falsifiable product hypothesis. The workshop already requires backup trust testing and leaves future Apple-private sync open.

### Dashboard is waste

Rejected as unsupported judgment. Its current value is unproven, not zero. The internal dogfood options are designed to create evidence without promoting Dashboard to a durable promise.

## Candidate Revisions

The revised `02e-po-product-workshop-candidate.md` now:

1. states that recommended options are not preselected;
2. adds Gate A step 0 for the post-base Multi-Profile ruling;
3. reframes B1 as a workflow hypothesis and adds the adult-family alternative;
4. separates single-library behavior from architecture implementation;
5. inventories all visible Pro/coming-soon surfaces;
6. demotes status-quo Dashboard/Review IA to experiments with a decision trigger;
7. treats hidden SmartPaper as the current pure-free recommendation and exposes ADR/algorithm consequences;
8. expands failure, privacy, recovery, TestFlight, support and compatibility acceptance;
9. names an explicit no-telemetry evidence-collection method and owner.

## PO Handoff

The candidate is now suitable for discussion, not batch approval. Decision order remains:

1. Integrate the ratified Gate A rules and post-base Multi-Profile ruling into
   their owning authority; neither is effective merely from this audit record.
2. B1-B3 workflow, promise and value chain.
3. B4-B5 data posture and single-library behavior.
4. B6-B7 commercial/platform posture.
5. C1-C2 target and Must outcomes.
6. C3-C5 optional feature treatment.
7. C6 acceptance and learning method.

Only the first group should be requested immediately; later groups need a short PO workshop rather than a single “approve all.”

## Recovery

- candidate: `phases/02e-po-product-workshop-candidate.md`
- review brief: `phases/02e-product-workshop-review-brief.md`
- review result: this file
- upstream structural result: `phases/02d-product-constitution-results.md`
- no raw agent transcript or private memory retained
