# UI Redesign Log

> Purpose: record durable UI design decisions, PO decisions, cross-layer findings, changed files, validation status, and unresolved questions. Private agent memory is not a design source of truth.

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
