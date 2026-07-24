# Phase 05 P1 Triage Results: Capture Integrity

> **文档状态：固定基线历史证据。** 本文只描述当时基线，不提供当前排期或执行授权；当前恢复入口见 `docs/reference/audits/2026-07-repository/README.md`，产品规范见 `docs/product/vision.md` 与 `docs/product/release-1-prd.md`。

## Base And Coverage

- fixed base: `origin/develop@5358cfacfc6d74de82b765a8e99865ea674fcf98`
- covered: camera detection/capture, scanner and album/PDF inputs, crop/OCR,
  CaptureResult editing/save, draft recovery and directly relevant tests
- excluded: Library edit (#875, routed to Phase 06), broad performance claims
  without a measured failure, and product changes to Capture scope or copy
- method: Codex live-code review and disposable red probes, followed by
  independent Claude Fable 5, Antigravity Gemini 3.5 Flash (High) and Grok 4.5
  read-only reviews

No P0 was found. Five P1 findings were reproduced on the fixed base. Their
repairs are isolated in Draft PRs #872, #873, #874 and #876; none is merged or
authorized by this report.

## Verified Findings And Repair State

| ID | Failure | Deterministic evidence | Frozen repair |
|---|---|---|---|
| RA-05-001 | a completed Capture save can be invoked again and create a duplicate item | post-success public/UI save oracle changes archive cardinality from one | #872 `6bcb4fbb` |
| RA-05-002 | entering recovery clears its only durable draft before formal save; cleanup timing can also resurrect saved work | injected draft lifecycle tests for recovery, discard and successful save | #872 `6bcb4fbb` |
| RA-05-003 | EXIF-oriented imports are persisted as raw rotated pixels after metadata removal | self-checking Orientation 6 fixture stored as `120 x 80` instead of displayed `80 x 120` | #873 `8354a38e` |
| RA-05-004 | Save can commit while a selected answer photo is still loading, permanently omitting `answerImagePath` | continuation barrier observed one committed row before load release and nil path afterward, in both test-plan configurations | #874 `77d83b99` |
| RA-05-005 | camera detection can disappear while `lastDetectedRect` retains the previous scene; the next photo is cropped with that stale box | pre-fix actor test failed in both configurations; post-fix suite passed 4/4 in each | #876 `17de8fdf` |

All four Draft PR heads passed `swiftlint --strict`, their focused regression
suites, tracked pre-commit validators and `AllTests` build-for-testing. GitHub
Build & Test is green and the exact heads are mergeable. #872 must merge before
#874 because they overlap CaptureResult state files; each merge still requires
separate PO authorization and post-rebase validation.

## Candidate Queue Requiring Another Oracle

These claims remain outside the finding ledger until the named check runs:

1. **Album OCR orientation**: `CaptureViewModel` passes `UIImage.cgImage` to
   Vision without its EXIF orientation. Reuse RA-05-003's Orientation 6 fixture
   after #873 lands; storage correctness does not prove OCR correctness.
2. **CaptureResult ownership**: `navigationDestination` constructs an inline
   ViewModel received as non-owning `@Bindable`. Run a simulator invalidation
   probe before classifying the alleged mid-edit reset as P1.
3. **Edit-session durability**: manual, clipboard, PDF and multi-page inputs do
   not create a draft before the result editor, and background termination does
   not run `onDisappear`. First freeze the required durability boundary; this is
   partly a product contract, not merely a missing callback.
4. **Stale recovery snapshot**: root `onAppear` may synchronously load D1 before
   result `onDisappear` asynchronously writes edited D2. Add a VM-level ordered
   draft-service probe on the post-#872 baseline.
5. **Non-atomic draft image write**: `CaptureDraftService` records metadata and
   logs success after JPEG conversion/path/write failure. Add injected
   filesystem failure oracles before selecting all-or-nothing semantics.
6. **Share handoff durability**: `AppRouter` deletes the App Group image before
   Capture creates a durable draft. Verify force-termination reachability and
   decide whether source-app content counts as recoverable input.

## Normalized Reviewer Results

- Claude's four P1 candidates were retained as candidates: two have static
  chains but still need red probes, one needs a dynamic SwiftUI ownership probe,
  and one needs a product durability contract.
- Grok independently found the draft-image and Share handoff durability gaps.
  Its OCR, camera and PDF observations without failure measurements remain P2.
- Antigravity's three P1 performance claims were reduced to hypotheses because
  it supplied no memory, watchdog or latency oracle. Its stale-context review of
  #875 was separately rejected against MainActor package settings and live guards.
- Codex rejected claims that the test-only temporary ImageStorage initializer is
  used in production, that Capture activity tracking is unpaired, or that the
  existing save cancellation ordering deterministically loses data.

## Dynamic Evidence

Disposable probes were removed after execution. Result bundles remain outside
the repository under `/private/tmp/snapdrill-phase05-evidence/`:

- answer-photo load/save race before and after #874;
- Library edit race before and after #875 (Phase 06 input);
- stale camera crop region before and after #876.

The stale-region pre-fix test failed twice with the previous normalized rect;
the post-fix suite passed in both CI and SnapshotRecord configurations. The
audit and main checkouts remained unmodified throughout probing.

## Handoff

1. Obtain exact-head PO merge decisions for #872 through #876; do not batch
   their authority implicitly.
2. Merge serially and rebase overlapping #874 after #872.
3. Resume Phase 05 on the merged baseline with the six candidate oracles above.
4. Keep broad PDF/scanner memory work in performance triage unless a measured
   crash, watchdog termination or release NFR failure promotes it.
