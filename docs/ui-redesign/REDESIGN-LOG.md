# UI Redesign Log

> Purpose: record durable UI design decisions, PO decisions, cross-layer findings, changed files, validation status, and unresolved questions. Private agent memory is not a design source of truth.

## 2026-06-21 - Settings profile row and detail chrome correction

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/SettingsView.swift`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Design Decisions

- PO reported a second Settings visual issue: the "User / Edit profile" row looked shorter than the following row, and the pushed profile editor appeared to have content covered underneath.
- Root cause: the Settings profile entry still rendered a custom glass card inside a system `List` row, so its visual width, corner treatment, and layer stack did not match the native inset-grouped rows.
- The profile entry now uses the native inset-grouped row container and keeps only row content customizations: 52 pt avatar, headline/subheadline text, and standard row hit area.
- Settings detail pages hide the tab bar after push. This prevents form controls and preview rows from sitting behind the floating iOS tab bar, matching the focused settings-detail navigation model.

### DoD Status

- Passed in this local change:
  - XcodeBuildMCP `build_run_sim` for `SnapDrill` on iPhone 17 simulator
  - XcodeBuildMCP screenshots for Settings main page and Edit Profile detail page
  - `swiftlint --strict`
  - `git diff --check`
  - `xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests`

## 2026-06-21 - Capture HIG contrast and Dynamic Type correction

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureMethodCard.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureView.swift`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Design Decisions

- Simulator HIG audit found that Capture method cards used strongly tinted Liquid Glass surfaces while their labels still used system primary/secondary text colors, producing poor contrast on blue, red, and green cards in both Light and Dark appearances.
- Capture method cards now use neutral interactive Liquid Glass surfaces; feature color is retained in the icon tile only, keeping labels on system text colors for readability.
- Accessibility Dynamic Type sizes switch the method grid from two columns to one column and allow labels more lines, preventing compressed cards and tab bar overlap.
- The Capture scroll content now reserves bottom space so the last method card can scroll above the iOS tab bar.

### DoD Status

- Passed in this local change:
  - `swiftlint --strict`
  - XcodeBuildMCP simulator screenshots: Light, Dark, Accessibility Large
  - `xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests`

## 2026-06-21 - Settings profile section shape correction

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/SettingsView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/SettingsRow.swift`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Design Decisions

- PO reported that the Settings "Switch Workspace" row looked visually misshapen after the UI polish pass.
- Root cause: the custom profile glass card and the standard "Switch Workspace" settings row lived in the same `List` `Section`, mixing a clear custom row background with the default inset-grouped row container.
- The profile card is now isolated in its own clear-background row; the workspace switch entry is a separate standard Settings row so iOS owns its grouped-list shape consistently.
- `SettingsRow` no longer hides list separators internally. Settings section separator behavior should come from the enclosing `List`/`Section` instead of a reusable row label imposing row chrome on every caller.

### DoD Status

- Passed in this local change:
  - `swiftlint --strict`
  - XcodeBuildMCP `build_sim` for `SnapDrill` on iPhone 17 simulator
  - `xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests`

## 2026-06-18 - Onboarding flagship polish implementation

### Scope

- `Packages/SnapDrillUI/Sources/SnapDrillUI/OnboardingView.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Onboarding.swift`
- `SnapDrill/Resources/zh-Hans.lproj/Localizable.strings`
- `SnapDrill/Resources/en.lproj/Localizable.strings`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Design Decisions

- PO approved the Onboarding default plan and three implementation decisions on 2026-06-18: land the candidate Onboarding copy, update the shared field-configuration wording, and align the visual surface with the calm system baseline.
- Onboarding is now framed as a first-run productivity guide rather than a learning or child-oriented tutorial.
- The visual layout uses a grouped system background, one calm page surface, restrained accent icons, custom page dots, and stable bottom controls.
- First-run copy now uses general-audience language: scan/archive/organize questions and documents, searchable records, review queue, export and print.
- Shared `fieldConfigTitle` / `fieldConfigDescription` / `fieldConfigHeader` wording is updated from input-field language to generic record-field language so it works for Capture and TipKit reuse.

### Files Changed

- `Packages/SnapDrillUI/Sources/SnapDrillUI/OnboardingView.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Onboarding.swift`
- `SnapDrill/Resources/zh-Hans.lproj/Localizable.strings`
- `SnapDrill/Resources/en.lproj/Localizable.strings`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Cross-Layer Findings

- Onboarding and shared field-configuration strings still live in `SnapDrillCore` L10n helpers. This milestone updates approved strings only and does not move the L10n layer.
- `L10n.Onboarding.fieldConfigTitle` and `fieldConfigDescription` are shared by `CaptureResultView` and `SnapDrillTips`. The wording is now generic, but a later contract seed should still decide whether shared L10n keys need a Common namespace.
- `onboarding.field_grade` remains a legacy field label. It is not changed in this PR because PO approved the direct Onboarding flow copy and shared field-configuration wording, not field taxonomy.

### DoD Status

- Passed:
  - `swiftlint --strict`
  - `python3 Scripts/validate_docs.py --check`
  - `python3 Scripts/generate_feature_status.py --check`
  - `python3 Scripts/generate_intent_traceability.py --check`
  - `xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests`

### Open Questions

- Onboarding contract seed is deferred to the later batch seed catch-up with Library, Review, and Dashboard.
- Simulator or device review should verify first-run layout, Dynamic Type, and the custom page dots on iPhone 17.

## 2026-06-18 - Dashboard flagship polish implementation

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/DashboardView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/DashboardViewModel.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/ReviewHeroCard.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/BentoCard.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/DashboardAnalyticsView.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Insights.swift`
- `SnapDrill/Resources/zh-Hans.lproj/Localizable.strings`
- `SnapDrill/Resources/en.lproj/Localizable.strings`
- `docs/features/active/feat-dashboard.md`
- `docs/ui-redesign/dashboard-flagship-polish-plan.md`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Design Decisions

- PO approved the default Dashboard plan on 2026-06-18 after the plan PR landed.
- Dashboard follows the Library/Capture/Review visual baseline: grouped system background, restrained blue/cyan/indigo accents, low-shadow cards, and no game-like celebration.
- The startup loading state now uses a stable redacted skeleton instead of a bare spinner so the first screen has a clear shape while data loads.
- Empty and quick-action copy now uses general-audience productivity language: `资料 / 采集 / 资料库 / 分类 / 回顾`.
- High-saturation Bento and Review hero gradients are reduced to calmer system-aligned tones.
- Draft recovery text is localized in zh/en through L10n while preserving the existing draft restore logic.
- Dashboard analytics and Pro teaser copy now use `资料洞察 / 分类趋势 / 待回顾较多的分类 / 稍后推出` language rather than school-like or paywall-heavy phrasing.

### Files Changed

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/DashboardView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/DashboardViewModel.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/ReviewHeroCard.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/BentoCard.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/DashboardAnalyticsView.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Insights.swift`
- `SnapDrill/Resources/zh-Hans.lproj/Localizable.strings`
- `SnapDrill/Resources/en.lproj/Localizable.strings`
- `docs/features/active/feat-dashboard.md`
- `docs/ui-redesign/dashboard-flagship-polish-plan.md`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Cross-Layer Findings

- `DashboardViewModel.loadData()` and `DashboardAnalyticsViewModel.loadAnalytics()` still log load failures without exposing an error state. PO explicitly chose to record this as a cross-layer blocker for a later contract pass and not change the ViewModel state machine in this UI milestone.
- Dashboard user-visible strings still live in `SnapDrillCore` L10n helpers. This milestone updates approved strings only and does not move the L10n layer.
- `L10n.Library.categoryManager` remains a cross-feature shared string consumed by Dashboard. A later contract seed should decide whether shared L10n keys need a Common namespace.

### DoD Status

- Passed on 2026-06-18:
  - `python3 Scripts/validate_docs.py --check`
  - `python3 Scripts/generate_feature_status.py --check`
  - `python3 Scripts/generate_intent_traceability.py --check`
  - `swiftlint --strict`
  - `xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests`

### Open Questions

- Dashboard contract seed remains a follow-up after this UI PR: error-state blocker, shared L10n ownership, and any minimal state-contract tests should be handled separately.
- Simulator or device review should verify Dynamic Type, loading skeleton density, and the calmer Bento grid against real profile data.

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

## 2026-06-19 - Settings flagship polish

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/SettingsView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/PrivacySettingsView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/SettingsRow.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/*Settings*.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Settings.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Accessibility.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Onboarding.swift`
- `SnapDrill/Resources/zh-Hans.lproj/Localizable.strings`
- `SnapDrill/Resources/en.lproj/Localizable.strings`

### Design Decisions

- PO approved the default Settings polish plan on 2026-06-19.
- The misleading diagnostics toggle is removed from Settings UI because it did not gate production analytics or MetricKit. It is replaced with a static local-only diagnostic explanation.
- No telemetry dependency injection, production `NoOpAnalyticsService`, or MetricKit behavior is changed in this milestone.
- Settings row icons are cooled down from saturated gradient fills to low-saturation system-style icon containers.
- Settings-visible user copy is moved toward general-audience productivity language: `学习者` becomes `资料空间`, `年级` becomes `级别`, `复习` becomes `回顾`, and Settings-owned `题目` copy becomes `资料` or `参考内容` where appropriate.
- Legal policy body copy remains legal-gated and is not rewritten in this UI milestone.

### Files Changed

- `Packages/SnapDrillCore/Sources/SnapDrillCore/Service/PrivacyConsentService.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Accessibility.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Onboarding.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Settings.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/TelemetryGate.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/EditProfileView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/NotificationSettingsView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/PrivacySettingsView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/ProfileListView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/ProfileListViewModel.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/ReviewAppearanceSettingsView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/SettingsBackupCoordinator.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/SettingsRouter.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/SettingsRow.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/SettingsView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/SettingsViewModel.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/SnapDrillFeatureSettings.docc/SnapDrillFeatureSettings.md`
- `SnapDrill/Resources/zh-Hans.lproj/Localizable.strings`
- `SnapDrill/Resources/en.lproj/Localizable.strings`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Cross-Layer Findings

- `TelemetryGate` and `PrivacyConsentService` still preserve local diagnostics preference compatibility. This milestone only updates comments and UI-facing copy; it does not change privacy or telemetry behavior.
- `PrivacySettingsViewModel` still records data-export analytics through `AnalyticsServiceProtocol`; production remains governed by the app-level `NoOpAnalyticsService` baseline.
- Settings-visible edit-profile copy lives partly under `L10n+Onboarding`; this milestone updates only the Settings-exposed edit-profile keys and does not reopen Onboarding copy.
- Legal policy body text is a legal-lane responsibility and was not modified.

### DoD Status

- Passed on 2026-06-19:
  - `git diff --check`
  - `swiftlint --strict`
  - `xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests`

### Open Questions

- Settings contract seed should be included in the planned bulk seed catch-up PR with Library, Review, and Dashboard.
- Release hardening still owns app bundle/display name, first global TestFlight, App Store metadata, and legal sign-off.

## 2026-06-19 - Profile flagship polish

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/ProfileListView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/EditProfileView.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Settings.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Onboarding.swift`
- `SnapDrill/Resources/zh-Hans.lproj/Localizable.strings`
- `SnapDrill/Resources/en.lproj/Localizable.strings`

### Design Decisions

- PO approved the default Profile polish direction on 2026-06-19.
- Profile is framed as productivity workspaces rather than learner/education identity. The list now has a clear workspace section, explanatory footer, selected-state treatment, and localized accessibility hints.
- Edit profile visuals are cooled down to the Settings baseline: smaller avatar, lower shadow, thinner neutral stroke, restrained system gradients, and photo-style edit affordance.
- `每日目标` is clarified as `每日回顾目标` / `Daily Review Goal` because the existing control configures review cadence, not a generic activity goal.
- No Profile switching, deletion, draft recovery, or persistence logic is changed.

### Files Changed

- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Onboarding.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Settings.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/EditProfileView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/ProfileListView.swift`
- `SnapDrill/Resources/zh-Hans.lproj/Localizable.strings`
- `SnapDrill/Resources/en.lproj/Localizable.strings`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Cross-Layer Findings

- Profile management behavior remains owned by `ProfileListViewModel` / `ProfileManager`; this milestone only changes the UI presentation and user-visible copy.
- Settings-visible edit-profile strings still live partly under `L10n+Onboarding`. The shared placement is preserved to avoid a L10n migration inside this screen polish PR.

### DoD Status

- Passed on 2026-06-19:
  - `git diff --check`
  - `swiftlint --strict`
  - `xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests`

### Open Questions

- Profile contract seed should be included in the planned bulk seed catch-up PR with Library, Review, Dashboard, and Settings.

## 2026-06-19 - Backup and data sync polish

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/DataAndSyncSettingsView.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Settings.swift`
- `SnapDrill/Resources/zh-Hans.lproj/Localizable.strings`
- `SnapDrill/Resources/en.lproj/Localizable.strings`

### Design Decisions

- PO approved continuing the Settings-adjacent Backup/Data screen after Profile. The screen stays inside the adult productivity baseline: system list structure, calm icon accents, explicit local-data warning, and no education/child-facing framing.
- Backup, restore, and CSV import now present as explicit action rows with subtitles and operation-owned progress feedback. The import spinner no longer depends on localized status text matching.
- Local storage copy now says items are stored on this device and asks the user to create a backup before switching devices, uninstalling, or erasing the device.
- Cache copy is clarified as temporary cache and the destructive clear action uses a familiar trash icon.

### Files Changed

- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Settings.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/DataAndSyncSettingsView.swift`
- `SnapDrill/Resources/zh-Hans.lproj/Localizable.strings`
- `SnapDrill/Resources/en.lproj/Localizable.strings`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Cross-Layer Findings

- `SettingsViewModel` reuses `isBackupInProgress`, `backupProgress`, and `backupStatusMessage` for backup, restore, and import. This milestone keeps the contract unchanged and adds local view state to identify the active UI operation.
- If future work needs richer operation reporting across Settings subviews, expose an explicit operation enum from the ViewModel as a cross-layer contract change rather than inferring from localized status strings.

### DoD Status

- Passed:
  - `git diff --check`
  - `swiftlint --strict`
  - `xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests`

### Open Questions

- Backup/Data contract details should be included in the planned bulk seed catch-up PR with Library, Review, Dashboard, Settings, and Profile.

## 2026-06-19 - UI contract seed catch-up

### Scope

- `docs/features/active/feat-library.md`
- `docs/features/active/feat-review.md`
- `docs/features/active/feat-dashboard.md`
- `docs/features/active/feat-onboarding.md`
- `docs/features/active/feat-settings.md`
- `docs/features/active/feat-profile.md`
- `docs/features/active/feat-backup.md`
- `docs/features/active/feat-export.md`

### Design Decisions

- PO approved closing the accumulated contract seed debt after the eight flagship UI screens reached develop.
- Contracts were added to existing feature specs instead of creating a duplicate summary document. This keeps the feature spec as the SSOT for each screen.
- Contract language records intended behavior, not merely current implementation. Where the implementation lacks an exposed seam, the spec records a blocker instead of blessing the current gap.
- Enforcement is right-sized: behavior contracts point to tests or dogfood, policy/copy contracts point to grep/review gates, and unavailable runtime evidence is recorded as dogfood or cross-layer follow-up.

### Files Changed

- `docs/features/active/feat-library.md`
- `docs/features/active/feat-review.md`
- `docs/features/active/feat-dashboard.md`
- `docs/features/active/feat-onboarding.md`
- `docs/features/active/feat-settings.md`
- `docs/features/active/feat-profile.md`
- `docs/features/active/feat-backup.md`
- `docs/features/active/feat-export.md`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Cross-Layer Findings

- Library filtering still needs stable snapshot behavior (#816) so rows do not partially reflow before disappearing.
- Dashboard error state remains a ViewModel seam blocker; the UI must not fabricate error states without source state.
- Shared L10n keys are now explicitly tracked: `L10n.Library.categoryManager` and `L10n.Onboarding.fieldConfigTitle` / `fieldConfigDescription` should move to Common/Shared or be registered as shared.
- Profile switching/deletion reliability still depends on GAP-R4 `AppActivityTracker` and GAP-R2 draft image isolation follow-ups.
- Backup import still carries GAP-R6 CSV field strictness debt.
- Export/print still needs GAP-R5 and real-device dogfood for direct/indirect print behavior.

### DoD Status

- This is a docs-only T0/T1 governance PR. Required verification:
  - `git diff --check`
  - feature status generation check
  - intent traceability generation check
  - capture contract check
- No Swift files are changed, so `xcodebuild build-for-testing` is intentionally not part of this PR's validation under the verification tier table.

### Open Questions

- Follow-up enforcement can be added selectively where cheap and useful: shared L10n namespace gate, focused Review rating tests, Dashboard error-state seam, and Export print dogfood tracking.
