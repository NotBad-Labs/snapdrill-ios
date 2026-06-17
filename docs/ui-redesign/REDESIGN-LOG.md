# UI Redesign Log

> Purpose: record durable UI design decisions, PO decisions, cross-layer findings, changed files, validation status, and unresolved questions. Private agent memory is not a design source of truth.

## 2026-06-17 - Review flagship polish

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Review.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Accessibility.swift`
- `SnapDrill/Resources/zh-Hans.lproj/Localizable.strings`
- `SnapDrill/Resources/en.lproj/Localizable.strings`
- `docs/features/active/feat-review.md`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Design Decisions

- Review remains a free retention layer, but the UI now presents it as adult productivity "回顾" rather than childlike or gamified "复习".
- Primary actions use clear recall self-assessment labels: `没印象 / 有印象` and `Forgot / Recalled`; the red/green oversized action language is replaced with calmer blue/orange controls that still support gestures and equivalent buttons.
- Entry, session, card, progress, and summary surfaces align with the Library/Capture baseline: system grouped backgrounds, restrained stroke, low shadow, and no decorative purple/blue gradients.
- Completion language is informational rather than motivational: `本轮完成 / 有印象 / 需回看`.
- `feat-review.md` now records the Review polish completion line and corrects the stale GAP-R1 statement: loading already excludes pending-deletion IDs, but active sessions still ignore `reviewDataDidChange`.

### Files Changed

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewDashboardView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewActionButtons.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewProgressHeader.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewSessionSummaryView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewEmptyStateView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewCardContent.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewCardBack.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Review.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Accessibility.swift`
- `SnapDrill/Resources/zh-Hans.lproj/Localizable.strings`
- `SnapDrill/Resources/en.lproj/Localizable.strings`
- `docs/features/active/feat-review.md`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Cross-Layer Findings

- Review and accessibility copy still live in `SnapDrillCore` L10n helpers. This milestone updates required user-facing strings only and does not move the L10n layer.
- Active Review sessions still need a future ViewModel contract for `reviewDataDidChange` during `.reviewing`; this UI milestone does not rewrite Review queue logic.

### DoD Status

- Passed on 2026-06-17:
  - `python3 Scripts/generate_feature_status.py --check`
  - `python3 Scripts/generate_intent_traceability.py --check`
  - `python3 Scripts/validate_docs.py --check`
  - `swiftlint --strict`
  - `xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests`

### Open Questions

- Dogfood should verify the tactile swipe threshold and button hit targets on iPhone 17 with real review data.
- A later contract seed should decide whether Review's `有印象 / 没印象` state names need explicit ViewModel tests beyond current UI copy and accessibility coverage.

## 2026-06-16 - Capture flagship polish planning

### Scope

- `docs/ui-redesign/capture-flagship-polish-plan.md`
- `docs/ui-redesign/REDESIGN-LOG.md`

Planning reviewed these files without editing them:

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureResultView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureViewModel.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureResultViewModel.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureMethodCard.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureImageSection.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureContentSection.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureMetadataSection.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureDetailsSection.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/PDFPagePickerView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/ScanPagePickerView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/SmartCameraView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/SmartCameraViewController.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/DocumentScannerView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CameraSessionManager.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Capture.swift`
- `SnapDrill/Resources/zh-Hans.lproj/Localizable.strings`
- `SnapDrill/Resources/zh-Hans.lproj/InfoPlist.strings`

### Design Decisions

- Capture is the second UI flagship surface after Library.
- PO confirmation is required before implementation.
- The plan keeps the #820 Library visual direction: calm adult productivity, Telegram/Apple lightness, stable spacing, and no child/game signals.
- The plan explicitly forbids editing `*ViewModel.swift`, Core/Data/OCR logic, or binary release settings unless a later PO decision changes the scope.
- UI implementation should consume existing state such as `isProcessing`, `isRecognizing`, `isSaving`, `isSaved`, `showErrorAlert`, and route-level presentation flags.
- Capture copy changes are PO-gated. Permission usage strings are listed as release-hardening candidates because they affect binary metadata and Capture permission prompts.

### Files Changed

- `docs/ui-redesign/capture-flagship-polish-plan.md`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Cross-Layer Findings

- `SnapDrillCore` `L10n+Capture.swift` is a Core-layer holder for UI strings. This milestone records the boundary and does not move the type.
- `CameraSessionManager` logs no-camera/session-configuration failures without exposing a user-visible state to SwiftUI.
- OCR empty result, low-quality image, timeout, and confidence are not fully represented as UI state. UI can handle empty text and surfaced errors, but deeper reason codes require a cross-layer contract.
- PDF and scan page OCR failure paths can reach an empty result editor with limited user context; the plan proposes UI fallback first and records deeper contracts separately.

### DoD Status

- Planning-only milestone. Swift build was not run because no Swift code changed.
- Passed on 2026-06-16:
  - `git diff --check`

### Open Questions

- Superseded by the implementation milestone below: PO approved the default Capture polish plan and permission usage strings on 2026-06-16.
- Implementation details and final DoD are recorded in "2026-06-16 - Capture flagship polish implementation".

## 2026-06-16 - Capture flagship polish implementation

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureMethodCard.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureContentSection.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureImageSection.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureResultView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/SmartCameraView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/DocumentScannerView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/ScanPagePickerView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/PDFPagePickerView.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Capture.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Accessibility.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Errors.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Onboarding.swift`
- `SnapDrill/Resources/zh-Hans.lproj/Localizable.strings`
- `SnapDrill/Resources/en.lproj/Localizable.strings`
- `SnapDrill/Resources/zh-Hans.lproj/InfoPlist.strings`
- `SnapDrill/Resources/en.lproj/InfoPlist.strings`
- `docs/ui-redesign/capture-flagship-polish-plan.md`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Design Decisions

- PO approved the default Capture polish plan and explicitly approved changing the camera/photo permission usage strings in this milestone.
- Capture remains an adult productivity capture surface: “资料/内容/参考内容/阶段” replaces exposed “题目/答案/年级/试卷” wording within this screen and its direct permission/a11y strings.
- Entry cards now provide local busy/disabled feedback so the first tap has visible response before a sheet, picker, scanner, or OCR flow appears.
- Manual empty state and OCR empty state are separate: manual input invites typing/pasting, while OCR empty explains that no text was recognized.
- PDF and scan page OCR failures now surface user-visible alerts with a “continue editing” fallback instead of silently opening an empty editor.
- Save now has a visible saving/saved status strip in addition to the existing failure alert.
- No `*ViewModel.swift`, Core/Data persistence logic, or OCR/Vision algorithm was changed.

### Files Changed

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureMethodCard.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureContentSection.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureImageSection.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureResultView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/SmartCameraView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/DocumentScannerView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/ScanPagePickerView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/PDFPagePickerView.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Capture.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Accessibility.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Errors.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Onboarding.swift`
- `SnapDrill/Resources/zh-Hans.lproj/Localizable.strings`
- `SnapDrill/Resources/en.lproj/Localizable.strings`
- `SnapDrill/Resources/zh-Hans.lproj/InfoPlist.strings`
- `SnapDrill/Resources/en.lproj/InfoPlist.strings`
- `docs/ui-redesign/capture-flagship-polish-plan.md`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Cross-Layer Findings

- UI text constants for Capture, Accessibility, Errors, and Onboarding still live under `SnapDrillCore`. This milestone updates only approved string defaults and localized resources; it does not move the L10n layer or change dependency direction.
- SmartCamera can still only log some camera-session failures such as no rear camera or session configuration failure. A precise user-facing camera unavailable state needs a future Feature/Core contract.
- OCR quality causes such as low confidence, timeout, and low-quality image are not exposed as structured UI state. This milestone handles surfaced errors and empty text only.

### DoD Status

- Passed on 2026-06-16:
  - `swiftlint --strict`
  - `xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests`

### Open Questions

- iPhone 17 dogfood is still needed for real camera, document scanner, photo picker cancellation, and PDF OCR fallback feel.
- If PO wants exact “camera unavailable” UI beyond simulator/document-scan fallback, define a small error-state contract outside the UI-only lane.

## 2026-06-15 - Library flagship polish

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryListView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryDetailView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/ExportOptionsSheet.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/ExportPreviewView.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Library.swift`
- `SnapDrill/Resources/zh-Hans.lproj/Localizable.strings`
- `SnapDrill/Resources/en.lproj/Localizable.strings`
- `docs/ui-redesign/library-flagship-polish-plan.md`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Design Decisions

- PO approved the default Library polish plan on 2026-06-15.
- Detail answer behavior: answers and answer images are hidden by default; the detail screen shows a stable “答案与备注” disclosure row and loads answer images only after expansion.
- Detail reading hierarchy: item text is promoted into a distinct reading surface with stronger text weight, line spacing, and text selection.
- List stability: missing primary category now renders a stable placeholder chip so date and following metadata do not shift left after filters refresh.
- List state: initial loading, filtered-empty, and pagination states are explicit and use general-audience productivity language.
- Export/print/share: share-card failures, print failures, PDF generation retry, ZIP progress, and PDF print progress now have user-visible feedback.
- General-audience copy: approved outward-facing Library copy is `SnapDrill 摘录卡`, `SnapDrill 资料集`, `资料集`, and `答案与备注`.
- SmartPaper is hidden from the Library toolbar for the first release; the feature remains in code and needs a separate PO decision before exposure.

### Files Changed

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryListView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryDetailView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/ExportOptionsSheet.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/ExportPreviewView.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Library.swift`
- `SnapDrill/Resources/zh-Hans.lproj/Localizable.strings`
- `SnapDrill/Resources/en.lproj/Localizable.strings`
- `docs/ui-redesign/library-flagship-polish-plan.md`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Cross-Layer Findings

- Library UI strings are exposed through `SnapDrillCore` `L10n+Library.swift`. This is a cross-layer UI concept living in Core; this milestone only updates text constants needed by the approved UI copy and does not move or redesign the L10n layer.
- Mathematical line breaking and formula structure remain beyond pure UI. This milestone improves line spacing and reading width only; OCR segmentation, MathML/LaTeX, and semantic formula wrapping require a future content-interpretation contract.

### DoD Status

- Passed on 2026-06-15:
  - `swiftlint --strict`
  - `xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests`

### Open Questions

- iPhone 17 dogfood is still required to judge real `UIPrintInteractionController` presentation and tactile print flow.
- Library detail still uses “题目” in some in-app labels because the current product keeps question/document scenarios; broader taxonomy changes should be handled in a separate copy sweep.

## 2026-06-14 - Design tool routing and Claude Design

### Scope

- `docs/how-to/parallel-lanes.md`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Design Decisions

- Codex + PO remain the UI design decision owner for SnapDrill.
- Claude Design may be used as a comparison and rapid prototyping tool during UI work.
- Claude Design outputs are candidates only. A candidate enters the project only after it is translated into repo evidence: design log, SwiftUI code, snapshot/XCUITest, or device/simulator validation.
- Recommended workflow: wireframe first, then high fidelity, then SwiftUI implementation and device validation.
- Useful things to inspect from external prototypes: layout hierarchy, information density, component structure, color tokens, spacing, and motion intent.
- Do not treat HTML/CSS/React output, screenshots, or social-media workflow advice as direct SwiftUI architecture decisions.

### Files Changed

- `docs/how-to/parallel-lanes.md`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Cross-Layer Findings

- None. This entry only records UI design workflow governance.

### DoD Status

- Passed:
  - `python3 Scripts/generate_feature_status.py --check`
  - `python3 Scripts/validate_docs.py --check`
  - `git diff --check`

### Open Questions

- None for this milestone.
