# UI Redesign Log

> Purpose: record durable UI design decisions, PO decisions, cross-layer findings, changed files, validation status, and unresolved questions. Private agent memory is not a design source of truth.

## 2026-06-21 - Capture method-grid bottom reachability

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureView.swift`
- `SnapDrillUITests/SnapDrillUITests.swift`
- `docs/ui-redesign/UI-FREEZE-QA-MATRIX.md`
- `docs/ui-redesign/evidence/2026-06-21-capture-methods-deep-*.png`

### Design Decisions

- Added `testUIFreezeCaptureMethodGridDeepScrollScreenshots` to cover Capture method-grid bottom reachability at normal and AX XXXL text sizes.
- The first AX screenshot showed the final `PDF 导入` card still readable under the floating tab bar. The button was hittable, but the visual state still failed the UI-freeze rule that controls must not appear hidden by system chrome.
- Replaced the previous anonymous `96` bottom padding with a named `tabBarBreathingRoom` sized for the iOS 26 floating tab bar. The test now scrolls to the true bottom before capturing evidence, so it proves the final card can sit fully above tab-bar chrome.

### DoD Status

- Passed in this local change:
  - XcodeBuildMCP `test_sim -testPlan UITests -only-testing:SnapDrillUITests/SnapDrillUITests/testUIFreezeCaptureMethodGridDeepScrollScreenshots`
  - XCUITest screenshot attachments exported to `docs/ui-redesign/evidence/2026-06-21-capture-methods-deep-*.png`

## 2026-06-21 - Settings deep-scroll bottom reachability

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/SettingsView.swift`
- `SnapDrillUITests/SnapDrillUITests.swift`
- `docs/ui-redesign/UI-FREEZE-QA-MATRIX.md`
- `docs/ui-redesign/evidence/2026-06-21-settings-deep-*.png`

### Design Decisions

- Added `testUIFreezeSettingsDeepScrollScreenshots` to cover Settings deep-scroll zones that were not exercised by the first-viewport Settings pass: danger zone, clear-all confirmation, about/legal bottom rows, and the true List bottom.
- Visual review rejected an earlier passing XCTest run because the DEBUG-only `生成测试数据 (100 条)` row was still readable under the iOS 26 floating tab bar. The final fix uses a larger named `tabBarBreathingRoom`, a DEBUG-only spacer between the about section and debug tools, and a bottom `safeAreaInset` for the List.
- The DEBUG row is not a shipping surface. It remains useful screenshot evidence because it proves the Settings List bottom can scroll above the floating tab bar instead of relying on partial hidden content.
- `PrivacySettingsView` does not own the global clear-all confirmation. The matrix now records that confirmation under Settings main / danger-zone evidence, while Privacy/export keeps only export options and the system share-sheet follow-up.

### DoD Status

- Passed in this local change:
  - XcodeBuildMCP `test_sim -testPlan UITests -only-testing:SnapDrillUITests/SnapDrillUITests/testUIFreezeSettingsDeepScrollScreenshots`
  - XCUITest screenshot attachments exported to `docs/ui-redesign/evidence/2026-06-21-settings-deep-*.png`

## 2026-06-21 - Taxonomy add/delete edge-state matrix

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/EditCategoryValueView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/EditDimensionView.swift`
- `SnapDrillUITests/SnapDrillUITests.swift`
- `docs/ui-redesign/UI-FREEZE-QA-MATRIX.md`
- `docs/ui-redesign/evidence/2026-06-21-taxonomy-edge-*.png`

### Design Decisions

- Added `testUIFreezeTaxonomyEdgeStateScreenshots` to cover custom taxonomy states not reached by the earlier built-in-value pass: add dimension, custom dimension list, empty custom dimension, add value, custom value list, value delete swipe, and dimension delete swipe.
- Added leaf accessibility identifiers for `EditDimensionView` root/save/cancel/multi-toggle and `EditCategoryValueView` save/cancel. This keeps screenshot tests off broad containers and avoids changing taxonomy behavior.
- Delete states intentionally use native List swipe actions. The screenshots document the system red destructive action instead of replacing it with custom controls.
- The custom ColorPicker remains a system color-picker surface in the matrix; this batch only covers preset swatches and add-value form layout.

### DoD Status

- Passed in this local change:
  - XcodeBuildMCP `test_sim -testPlan UITests -only-testing:SnapDrillUITests/SnapDrillUITests/testUIFreezeTaxonomyEdgeStateScreenshots`
  - XCUITest screenshot attachments exported to `docs/ui-redesign/evidence/2026-06-21-taxonomy-edge-*.png`

## 2026-06-21 - Review physical swipe gesture matrix

### Scope

- `SnapDrillUITests/SnapDrillUITests.swift`
- `docs/ui-redesign/UI-FREEZE-QA-MATRIX.md`
- `docs/ui-redesign/evidence/2026-06-21-review-12-after-left-drag.png`
- `docs/ui-redesign/evidence/2026-06-21-review-13-after-drag-undo.png`
- `docs/ui-redesign/evidence/2026-06-21-review-14-after-right-drag.png`

### Design Decisions

- Added `testUIFreezeReviewSwipeGestureScreenshots` to cover Review's physical horizontal drag path, not only the button-triggered rating path.
- The test uses XCUITest normalized screen coordinates across the visible Review card. It intentionally does not add a broad accessibility identifier to the card container, preserving the previous fix that keeps hidden/non-top card controls out of the accessibility tree.
- The visual contract is progress and control-state based: left drag advances to `2/2` and enables undo, undo returns to `1/2` and disables undo, and right drag advances through the same physical gesture path. Screenshot evidence still captures the card content for human review.

### DoD Status

- Passed in this local change:
  - XcodeBuildMCP `test_sim -testPlan UITests -only-testing:SnapDrillUITests/SnapDrillUITests/testUIFreezeReviewSwipeGestureScreenshots`
  - XCUITest screenshot attachments exported to `docs/ui-redesign/evidence/2026-06-21-review-12-after-left-drag.png` through `docs/ui-redesign/evidence/2026-06-21-review-14-after-right-drag.png`

## 2026-06-21 - Library control-state matrix

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/BatchTagSheet.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/ExportOptionsSheet.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryFilterSheet.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryListView.swift`
- `SnapDrillUITests/SnapDrillUITests.swift`
- `docs/ui-redesign/UI-FREEZE-QA-MATRIX.md`
- `docs/ui-redesign/evidence/2026-06-21-library-controls-*.png`

### Design Decisions

- Added `testUIFreezeLibraryControlStateScreenshots` to cover Library states that were not fully exercised by the populated-list pass: selected filter before reset, post-reset list, selected batch tag, export options, ZIP no-images alert, search result, and search no-result states.
- Added stable leaf accessibility identifiers for quick filters, active-filter clear/remove controls, filter difficulty rows, filter reset/done buttons, batch tag values, batch tag done, CSV export, PDF option toggles, PDF items-per-page stepper, and export close. The identifiers stay on controls and do not replace the accessibility tree for whole containers.
- The batch tag selected-state screenshot creates a real tag value through the existing Category Manager route before returning to Library selection mode. This proves the selected-tag row visually renders with real persisted taxonomy data.
- The export pass captures CSV row visibility, PDF option controls, and the ZIP no-images alert for a text-only item. It does not claim the system share sheet or image-heavy ZIP path are complete; those remain Needs data/system-surface in the matrix.
- Search result and search no-result screenshots intentionally include the keyboard. They verify active search input, clear-search affordance, filtered result, and empty-result layout without treating keyboard dismissal as part of this visual contract.

### DoD Status

- Passed in this local change:
  - XcodeBuildMCP `test_sim -testPlan UITests -only-testing:SnapDrillUITests/SnapDrillUITests/testUIFreezeLibraryControlStateScreenshots`
  - XCUITest screenshot attachments exported to `docs/ui-redesign/evidence/2026-06-21-library-controls-*.png`

## 2026-06-21 - Settings remaining control-state matrix

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/DataAndSyncSettingsView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/LicenseView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/NotificationSettingsView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/ReviewAppearanceSettingsView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/SettingsView.swift`
- `SnapDrillUITests/SnapDrillUITests.swift`
- `docs/ui-redesign/UI-FREEZE-QA-MATRIX.md`
- `docs/ui-redesign/evidence/2026-06-21-settings-controls-*.png`

### Design Decisions

- Added `testUIFreezeSettingsControlStateScreenshots` to cover Settings states not reached by primary/secondary sweeps: Profile delete confirmation, Review Appearance alignment menu, enabled Notification controls, Data & Sync restore/cache dialogs, global clear-all confirmation, feedback alert, and open-source license root/detail pages.
- Wired the existing `SettingsDestination.licenses` / `LicenseView` route into the About section. This does not introduce a new settings concept; it makes the already-authored open-source license screen reachable and testable.
- License root/detail pages now hide the app tab bar, matching the self-contained Settings detail-page rule used for privacy/terms/data/review detail surfaces.
- Follow-up screenshot QA found Review Appearance max-font preview text could be clipped by the form row when the alignment menu was open. Preview text now uses unlimited lines with vertical fixed sizing so the row expands instead of cutting off content.
- Notification settings no longer show the dependent Sound section while daily reminders are off. The disabled state had made a green Sound switch look active even though reminders were disabled; the enabled state remains available once reminders are on.
- Restore confirmation uses iOS 26 `confirmationDialog` behavior without a stable exposed Cancel control. The test captures the dialog state and avoids treating tap-out dismissal as a product contract.

### DoD Status

- Passed in this local change:
  - XcodeBuildMCP `test_sim -testPlan UITests -only-testing:SnapDrillUITests/SnapDrillUITests/testUIFreezeSettingsControlStateScreenshots`
  - XCUITest screenshot attachments exported to `docs/ui-redesign/evidence/2026-06-21-settings-controls-*.png`

## 2026-06-21 - Settings interaction-state matrix

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/LanguageSettingsView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/PrivacySettingsView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/ProfileListView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/ReviewAppearanceSettingsView.swift`
- `SnapDrillUITests/SnapDrillUITests.swift`
- `docs/ui-redesign/UI-FREEZE-QA-MATRIX.md`
- `docs/ui-redesign/evidence/2026-06-21-settings-interactions-*.png`

### Design Decisions

- Added `testUIFreezeSettingsInteractionStateScreenshots` to cover Settings states that are not visible on a first-viewport sweep: Profile add alert, multi-profile list, Language restart alert, Privacy export format dialog, and Review Appearance max font-size previews.
- Added narrow accessibility identifiers for Profile add/row controls, language rows, the Privacy export button, and Review Appearance previews/sliders. These identifiers stay on leaf controls or narrow visual markers and do not replace interactive child controls.
- iOS 26 exposes the Privacy export `confirmationDialog` as JSON/CSV actions without a visible Cancel button in this context. The UI test dismisses it by tapping blank space instead of asserting a non-existent cancel control.
- Screenshot QA found Review Appearance large previews could scroll underneath the transparent navigation chrome after maxing the font-size sliders. `ReviewAppearanceSettingsView` now uses a visible grouped navigation-bar background while preserving the self-contained detail-page rule that hides the app tab bar.
- The Review Appearance screenshots intentionally include scrolled interaction states. They prove the navigation title/back area remains readable at max font size; they do not claim every deeper alignment picker state is complete.

### DoD Status

- Passed in this local change:
  - XcodeBuildMCP `test_sim -testPlan UITests -only-testing:SnapDrillUITests/SnapDrillUITests/testUIFreezeSettingsInteractionStateScreenshots`
  - XCUITest screenshot attachments exported to `docs/ui-redesign/evidence/2026-06-21-settings-interactions-*.png`

## 2026-06-21 - Taxonomy and swatch control-state matrix

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/CategoryValueListView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/EditCategoryValueView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/SFSymbolPickerView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/EditProfileView.swift`
- `SnapDrillUITests/SnapDrillUITests.swift`
- `docs/ui-redesign/UI-FREEZE-QA-MATRIX.md`
- `docs/ui-redesign/evidence/2026-06-21-taxonomy-*.png`

### Design Decisions

- Added `testUIFreezeTaxonomyControlStateScreenshots` to cover Profile theme swatches, taxonomy value lists, taxonomy value color swatches, and symbol-picker default/search-empty states.
- Added leaf accessibility identifiers for Profile color swatches, taxonomy color swatches, taxonomy value roots, and symbol-picker search/empty states. This keeps the identifiers on controls or narrow state markers and avoids broad container identifiers that hide child controls.
- Verified the Profile and taxonomy selected-color states use accent rings plus white checkmarks, with reserved draw/hit frames; the reported black/clipped selection-ring pattern does not remain in these controls.
- During test hardening, `-userAvatarColorIndex 0` was rejected because UserDefaults launch arguments override `@AppStorage` writes and can make a real tap appear ineffective. The final test exercises the real AppStorage write path.
- Symbol-picker empty search is intentionally captured with the keyboard visible. That screenshot covers the active search-input state; non-keyboard empty-state layout can be added later if needed.

### DoD Status

- Passed in this local change:
  - XcodeBuildMCP `test_sim -testPlan UITests -only-testing:SnapDrillUITests/SnapDrillUITests/testUIFreezeTaxonomyControlStateScreenshots`
  - XCUITest screenshot attachments exported to `docs/ui-redesign/evidence/2026-06-21-taxonomy-*.png`

## 2026-06-21 - Primary tabs AX Dynamic Type matrix

### Scope

- `SnapDrillUITests/SnapDrillUITests.swift`
- `docs/ui-redesign/UI-FREEZE-QA-MATRIX.md`
- `docs/ui-redesign/evidence/2026-06-21-primary-ax-*.png`

### Design Decisions

- Added `testUIFreezePrimaryTabAccessibilityTextScreenshots` to capture Dashboard, Library, Capture, Review, and Settings first viewports at `UICTContentSizeCategoryAccessibilityXXXL`.
- The AX pass confirmed the current primary tabs remain reachable by XCUITest and that the highest-priority leaf controls exist at maximum accessibility text size.
- iOS 26 Liquid Glass tab bars intentionally float above and visually sample the content layer. An attempted opaque bottom overlay was rejected because it clipped scroll content in Library, Capture, and Settings instead of solving the layout. Future fixes should improve the affected page layout or scroll reachability directly, not mask content behind the tab bar.
- Settings' existing normal-size `tabBarBreathingRoom` remains in place; removing it regressed the normal primary Settings screenshot by making the next section readable through the tab bar.

### DoD Status

- Passed in this local change:
  - XcodeBuildMCP `test_sim -testPlan UITests -only-testing:SnapDrillUITests/SnapDrillUITests/testUIFreezePrimaryTabAccessibilityTextScreenshots`
  - XCUITest screenshot attachments exported to `docs/ui-redesign/evidence/2026-06-21-primary-ax-*.png`
- Re-checked and preserved:
  - XcodeBuildMCP `test_sim -testPlan UITests -only-testing:SnapDrillUITests/SnapDrillUITests/testUIFreezePrimaryTabSurfaceScreenshots`

## 2026-06-21 - Onboarding visual and Dynamic Type matrix

### Scope

- `Packages/SnapDrillUI/Sources/SnapDrillUI/OnboardingView.swift`
- `SnapDrillUITests/SnapDrillUITests.swift`
- `docs/ui-redesign/UI-FREEZE-QA-MATRIX.md`
- `docs/ui-redesign/evidence/2026-06-21-onboarding-*.png`

### Design Decisions

- Added `testUIFreezeOnboardingPagedScreenshots` to capture all first-run onboarding pages and the finish path, plus `testUIFreezeOnboardingAccessibilityTextScreenshots` to capture AX XXXL text size and the skip path.
- The onboarding root now uses contained accessibility children instead of combining the entire first-run flow into one accessibility element. This keeps Skip / Previous / Next / Get Started reachable to assistive technologies and XCUITest.
- Onboarding page controls use leaf identifiers (`onboarding.skip`, `onboarding.previous`, `onboarding.next`, `onboarding.getStarted`) plus non-action page markers. Broad identifiers are avoided on interactive groups.
- AX XXXL screenshot review found title truncation and card clipping. Titles now wrap, and accessibility sizes hide the decorative icon, tighten card padding, and place the page card in a vertical `ScrollView` so the first viewport keeps a complete rounded card.
- Normal-size onboarding remains visually centered and keeps the icon treatment.

### DoD Status

- Passed in this local change:
  - XcodeBuildMCP `test_sim -testPlan UITests -only-testing:SnapDrillUITests/SnapDrillUITests/testUIFreezeOnboardingPagedScreenshots`
  - XcodeBuildMCP `test_sim -testPlan UITests -only-testing:SnapDrillUITests/SnapDrillUITests/testUIFreezeOnboardingAccessibilityTextScreenshots`
  - XCUITest screenshot attachments exported to `docs/ui-redesign/evidence/2026-06-21-onboarding-*.png`

## 2026-06-21 - Review interaction visual matrix

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewCardContent.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewCardBack.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewCardFactory.swift`
- `SnapDrillUITests/SnapDrillUITests.swift`
- `docs/ui-redesign/UI-FREEZE-QA-MATRIX.md`
- `docs/ui-redesign/evidence/2026-06-21-review-06-*.png` through `docs/ui-redesign/evidence/2026-06-21-review-11-*.png`

### Design Decisions

- Added `testUIFreezeReviewInteractionSurfaceScreenshots` to capture multi-card Review progress, pause confirmation, front/back edit-sheet entry, enabled undo, and after-undo recovery.
- Screenshot QA found that non-top Review cards and opacity-hidden card backs were still visible to XCUITest/accessibility. This made hidden `Menu` controls selectable and could expose actions for the wrong card face.
- Review card stacking now treats non-top cards as decorative, and Review card edit menus render only on the visible top card face. This keeps the visual stack while removing hidden controls from interaction and accessibility paths.
- The card front/back menu identifiers are leaf identifiers only. The broad `review.card.front` / `review.card.back` identifiers were removed because they caused child controls to inherit container identifiers.
- The shared edit sheet still uses the `编辑题目` title from both front and back entry points. That is tracked as a naming consistency follow-up; this pass only claims there is no clipping, underlap, or hidden-control leak in the entry sheets.
- Physical drag/swipe screenshot coverage remains open. This pass covers the button-rating path, undo, pause alert, and edit-sheet interaction states.

### DoD Status

- Passed in this local change:
  - XcodeBuildMCP `test_sim -testPlan UITests -only-testing:SnapDrillUITests/SnapDrillUITests/testUIFreezeReviewInteractionSurfaceScreenshots`
  - XCUITest screenshot attachments exported to `docs/ui-redesign/evidence/2026-06-21-review-06-*.png` through `docs/ui-redesign/evidence/2026-06-21-review-11-*.png`

## 2026-06-21 - Dashboard populated visual matrix

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/DashboardView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/ReviewHeroCard.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/DashboardAnalyticsView.swift`
- `SnapDrillUITests/SnapDrillUITests.swift`
- `docs/ui-redesign/UI-FREEZE-QA-MATRIX.md`
- `docs/ui-redesign/evidence/2026-06-21-dashboard-*.png`

### Design Decisions

- Added `testUIFreezeDashboardPopulatedSurfaceScreenshots` to capture the Dashboard due hero, shortcut grid, category-manager sheet opened from Dashboard, locked analytics gate, and all-done hero after completing one Review item.
- Added stable Dashboard identifiers only to leaf buttons/cards and the noninteractive analytics-gate marker. Broad container identifiers are avoided so XCUITest does not hide child controls.
- Screenshot QA found that scrolled Dashboard content could render underneath the transparent status bar. A noninteractive top safe-area background mask now prevents the greeting/date header from overlapping system status text while preserving the existing layout.
- This pass covers the free/locked analytics gate. Pro-unlocked analytics remains gated by StoreKit / #479 and is not claimed as visually complete.

### DoD Status

- Passed in this local change:
  - XcodeBuildMCP `test_sim -testPlan UITests -only-testing:SnapDrillUITests/SnapDrillUITests/testUIFreezeDashboardPopulatedSurfaceScreenshots`
  - XCUITest screenshot attachments exported to `docs/ui-redesign/evidence/2026-06-21-dashboard-*.png`

## 2026-06-21 - Review populated session visual matrix

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureDetailsSection.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewDashboardView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewActionButtons.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewCardContent.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewCardBack.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewProgressHeader.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewSessionSummaryView.swift`
- `SnapDrillUITests/SnapDrillUITests.swift`
- `docs/ui-redesign/UI-FREEZE-QA-MATRIX.md`
- `docs/ui-redesign/evidence/2026-06-21-review-*.png`

### Design Decisions

- Added `testUIFreezeReviewPopulatedSessionScreenshots` to capture the populated Review dashboard, one-card session front, card back with answer, summary, and completed dashboard state.
- Stable Review QA identifiers are placed on leaf/action controls or on noninteractive background markers. A first attempt to put identifiers on broad Review containers hid child controls from XCUITest and was removed.
- The manual-capture helper can now fill the answer field so the Review card-back screenshot proves the answer-side layout, not only the same front-card surface.
- A short run-loop wait is used after the flip action so the screenshot records the stable card-back state instead of a mid-animation transition frame.
- This pass covers one-card Review flow only. Multi-card swipe, undo, pause alert, and card edit sheets remain tracked in `UI-FREEZE-QA-MATRIX.md`.

### DoD Status

- Passed in this local change:
  - XcodeBuildMCP `test_sim -testPlan UITests -only-testing:SnapDrillUITests/SnapDrillUITests/testUIFreezeReviewPopulatedSessionScreenshots`
  - XCUITest screenshot attachments exported to `docs/ui-redesign/evidence/2026-06-21-review-*.png`

## 2026-06-21 - Capture manual-result editor visual matrix

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureResultView.swift`
- `SnapDrillUITests/SnapDrillUITests.swift`
- `docs/ui-redesign/UI-FREEZE-QA-MATRIX.md`
- `docs/ui-redesign/evidence/2026-06-21-capture-*.png`

### Design Decisions

- Added `testUIFreezeCaptureManualResultEditorScreenshots` to capture the manual-result editor, keyboard state, subject menu, selected subject, and saved return to Capture root.
- A first screenshot pass showed the editor still carried the app tab bar. This was not an immediate content-underlap failure, but it conflicted with the Settings edit/detail rule and made the subject menu compete with app-level navigation.
- `CaptureResultView` now hides the tab bar while preview/edit is active. The tab bar is visible again after save/back navigation returns to the Capture root.
- The first attempt to add section-level accessibility identifiers to grouped editor sections swallowed the existing `capture.contentEditor` child identifier. Those section identifiers were removed; UI-freeze markers must not alter the accessibility tree of interactive controls.
- This pass covers manual text entry. Camera, document scan, PDF import, image OCR, cropper, field-config tip, and answer/difficulty optional fields remain tracked in `UI-FREEZE-QA-MATRIX.md`.

### DoD Status

- Passed in this local change:
  - XcodeBuildMCP `test_sim -testPlan UITests -only-testing:SnapDrillUITests/SnapDrillUITests/testUIFreezeCaptureManualResultEditorScreenshots`
  - XCUITest screenshot attachments exported to `docs/ui-redesign/evidence/2026-06-21-capture-*.png`

## 2026-06-21 - Library populated-state visual matrix

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryListView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryDetailView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryEditView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryFilterSheet.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/BatchTagSheet.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/ExportOptionsSheet.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/ExportPreviewView.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Library.swift`
- `SnapDrillUITests/SnapDrillUITests.swift`
- `docs/ui-redesign/UI-FREEZE-QA-MATRIX.md`
- `docs/ui-redesign/evidence/2026-06-21-library-*.png`

### Design Decisions

- Added stable Library accessibility identifiers and `testUIFreezeLibraryPopulatedSurfaceScreenshots` so populated Library states can be regenerated instead of relying on ad hoc manual navigation.
- Native screenshot QA for this target runs through the `SnapDrill` scheme with the `UITests` test plan. `AllTests` remains the package/unit build gate and does not execute the native `SnapDrillUITests` target.
- Populated-state screenshots found that Library quick-filter chips rendered unselected states as naked text and exposed a clipped edge glyph. Unselected chips now keep visible rounded capsule backgrounds and strokes, while selected chips remain accent-filled.
- Selection mode no longer puts selected-count status text in the bottom toolbar, where it rendered like a floating Liquid Glass action. The selected count now lives in the navigation title and the bottom toolbar contains actions only.
- Batch tag sheet empty state now uses tag-specific copy (`还没有标签`) rather than the Library item empty-state copy (`还没有题目`).
- This pass covers text-only populated Library, filter sheet, selection toolbar, batch-tag empty state, export options, and PDF preview. Image-heavy item states, share activity, CSV/ZIP export visuals, search, and full-screen image remain tracked in `UI-FREEZE-QA-MATRIX.md`.

### DoD Status

- Passed in this local change:
  - `xcodebuild test -project SnapDrill.xcodeproj -scheme SnapDrill -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan UITests -only-testing:SnapDrillUITests/SnapDrillUITests/testUIFreezeLibraryPopulatedSurfaceScreenshots -resultBundlePath /tmp/snapdrill-library-ui-freeze.xcresult`
  - XCUITest screenshot attachments exported to `docs/ui-redesign/evidence/2026-06-21-library-*.png`

## 2026-06-21 - Settings secondary-page visual matrix and tab-bar underlap fixes

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/SettingsView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/EditProfileView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/ProfileListView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/ReviewAppearanceSettingsView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/NotificationSettingsView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/DataAndSyncSettingsView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/StorageManagementView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/PrivacySettingsView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/LanguageSettingsView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/PrivacyPolicyView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/TermsOfServiceView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/CategoryManagerView.swift`
- `SnapDrillUITests/SnapDrillUITests.swift`
- `docs/ui-redesign/UI-FREEZE-QA-MATRIX.md`
- `docs/ui-redesign/evidence/2026-06-21-settings-secondary-*.png`

### Design Decisions

- Added stable Settings route/root accessibility identifiers and `testUIFreezeSettingsSecondarySurfaceScreenshots` so secondary-page visual QA is reproducible.
- Screenshot review found true bottom underlap on long Settings details: `DataAndSyncSettingsView`, `PrivacyPolicyView`, and `TermsOfServiceView` had readable rows or legal body text behind the floating tab bar.
- Long, self-contained Settings details now hide the tab bar, matching the existing Edit Profile pattern and preventing controls or legal text from sitting under floating chrome.
- `CategoryManagerView` intentionally keeps the tab bar visible because existing category-management E2E flows configure taxonomy and then switch to Capture without popping the Settings stack.
- Legal text and legal dates were not edited in this visual pass. The screenshots only verify chrome; Privacy Policy and Terms content remains legal-gated.

### DoD Status

- Passed in this local change:
  - XcodeBuildMCP `test_sim -testPlan UITests -only-testing:SnapDrillUITests/SnapDrillUITests/testUIFreezeSettingsSecondarySurfaceScreenshots`
  - Before screenshots for the validated underlap: `2026-06-21-settings-data-sync-tabbar-before.png`, `2026-06-21-settings-privacy-policy-tabbar-before.png`, `2026-06-21-settings-terms-tabbar-before.png`
  - After screenshots for 11 Settings secondary surfaces: `docs/ui-redesign/evidence/2026-06-21-settings-secondary-*.png`

## 2026-06-21 - Primary tab screenshot matrix and Settings tab-bar underlap fix

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/DashboardView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryListView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/SettingsView.swift`
- `SnapDrillUITests/SnapDrillUITests.swift`
- `docs/ui-redesign/UI-FREEZE-QA-MATRIX.md`
- `docs/ui-redesign/evidence/2026-06-21-primary-*.png`
- `docs/ui-redesign/evidence/2026-06-21-settings-main-tabbar-before.png`
- `docs/ui-redesign/evidence/2026-06-21-settings-main-tabbar-after.png`

### Design Decisions

- Added stable root accessibility identifiers for the five primary tabs so UI-freeze evidence can be regenerated through XCUITest instead of manual screenshots.
- Added `testUIFreezePrimaryTabSurfaceScreenshots`, which launches a clean empty-library state, visits Dashboard, Library, Capture, Review, and Settings, and stores keep-alive screenshot attachments.
- Visual review of those screenshots found that the Settings main page allowed the next `回顾设置` section to remain readable behind the floating iOS tab bar. This matched the PO-reported class of “component looks covered underneath.”
- The Settings capture-field section now reserves named breathing room before the next section. The field group keeps its complete rounded container and the tab bar sits over empty grouped-list background instead of readable row content.
- This entry covers the regular-size primary empty states only. It is not a full UI-freeze completion claim; populated states, secondary pages, device-only capture flows, and Dynamic Type remain tracked in `UI-FREEZE-QA-MATRIX.md`.

### DoD Status

- Passed in this local change:
  - XcodeBuildMCP `test_sim -testPlan UITests -only-testing:SnapDrillUITests/SnapDrillUITests/testUIFreezePrimaryTabSurfaceScreenshots`
  - XCUITest screenshot attachments exported to `docs/ui-redesign/evidence/2026-06-21-primary-*.png`
  - Settings before/after screenshots exported to `docs/ui-redesign/evidence/2026-06-21-settings-main-tabbar-before.png` and `docs/ui-redesign/evidence/2026-06-21-settings-main-tabbar-after.png`

## 2026-06-21 - Shared symbol picker general-audience correction

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/SFSymbolPickerView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/EditDimensionView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/EditCategoryValueView.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Library.swift`
- `SnapDrill/Resources/zh-Hans.lproj/Localizable.strings`
- `SnapDrill/Resources/en.lproj/Localizable.strings`
- `SnapDrillUITests/SnapDrillUITests.swift`
- `docs/ui-redesign/UI-FREEZE-QA-MATRIX.md`
- `docs/ui-redesign/evidence/2026-06-21-icon-picker-general-audience.png`

### Design Decisions

- The shared SF Symbol picker is reachable from Profile avatar-symbol editing and taxonomy/category editing, so it is a cross-surface control, not a single Library detail.
- Static matrix review found hard-coded Chinese education categories in the picker (`学术`, `数学/逻辑`, `理化/实验`, `体育/运动`). This created both a localization defect in English UI and a post-pivot positioning regression in a general-audience tool.
- Picker presets now use localized general-audience groups: common, documents, work, ideas, writing, places, people, nature, tools, and measurement.
- Selected symbol tiles now use the same accent-ring + checkmark language as corrected color swatches, plus `.isSelected` for accessibility.
- The picker now exposes stable category and symbol accessibility identifiers so control-level UI tests can verify visible categories and selection round-trips.

### DoD Status

- Passed in this local change:
  - `plutil -lint SnapDrill/Resources/zh-Hans.lproj/Localizable.strings SnapDrill/Resources/en.lproj/Localizable.strings`
  - `swiftlint --strict`
  - `git diff --check`
  - XcodeBuildMCP `test_sim -testPlan UITests -only-testing:SnapDrillUITests/SnapDrillUITests/testIconPickerUsesGeneralAudienceCategories`
  - XCUITest screenshot attachment exported to `docs/ui-redesign/evidence/2026-06-21-icon-picker-general-audience.png`

## 2026-06-21 - Swatch selection indicators and UI QA matrix

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/EditProfileView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/EditCategoryValueView.swift`
- `docs/ui-redesign/UI-FREEZE-QA-MATRIX.md`

### Design Decisions

- PO reported that the Edit Profile theme-color picker used a black selected circle for the default blue swatch, and that the selected circle was clipped.
- Root cause: the selected-state ring used `Color.primary`, which becomes black in light mode, and it was drawn on the swatch boundary without reserving extra frame space.
- Profile theme swatches now use a reserved hit/draw frame, an accent-color selection ring, and a white checkmark. The selected indicator is no longer clipped by its own swatch frame.
- Category value color swatches used the same `Color.primary` selection-ring pattern and were fixed in the same pass.
- A route-derived `UI-FREEZE-QA-MATRIX.md` was added so future UI freeze claims require explicit surface-by-surface status instead of informal "full scan" wording.

### DoD Status

- Passed in this local change:
  - `rg "stroke\\(Color\\.primary|strokeBorder\\(Color\\.primary|\\.stroke\\(\\.primary|\\.strokeBorder\\(\\.primary" ...` returns no hits
  - `swiftlint --strict`
  - `git diff --check`
  - XcodeBuildMCP `build_run_sim` for `SnapDrill` on iPhone 17 simulator
  - XcodeBuildMCP screenshot of Edit Profile theme-color row confirming no black/clipped selected ring

## 2026-06-21 - Review empty-state chrome correction

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewDashboardView.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Review.swift`
- `SnapDrill/Resources/zh-Hans.lproj/Localizable.strings`
- `SnapDrill/Resources/en.lproj/Localizable.strings`
- `docs/ui-redesign/UI-FREEZE-QA-MATRIX.md`
- `docs/ui-redesign/evidence/2026-06-21-review-empty-before.jpg`
- `docs/ui-redesign/evidence/2026-06-21-review-empty-after.jpg`

### Design Decisions

- PO reported that the Review tab looked visually awkward on a fresh/empty library.
- Root cause: the Review empty state already used native `ContentUnavailableView`, but its title, description, icon, and CTA were borrowed from the Dashboard/Library empty state. In the Review tab this read like the wrong surface: `还没有任何资料` / `开始采集`.
- The empty-library Review state now uses Review-specific copy and iconography: `暂无回顾内容`, a clock/review symbol, explanatory body copy, and a `去采集` CTA.
- English localization now mirrors the same Review-specific state: `No Review Items Yet`, `Capture or import content first. Scheduled items will appear here when due.`, and `Capture Content`.
- Non-empty Review idle states keep the existing status dashboard and review-session entry point.

### DoD Status

- Passed in this local change:
  - XcodeBuildMCP before screenshot: `docs/ui-redesign/evidence/2026-06-21-review-empty-before.jpg`
  - XcodeBuildMCP after screenshot: `docs/ui-redesign/evidence/2026-06-21-review-empty-after.jpg`

## 2026-06-21 - Profile workspace default naming and selection chrome

### Scope

- `Packages/SnapDrillData/Sources/SnapDrillData/ProfileManager.swift`
- `Packages/SnapDrillData/Sources/SnapDrillData/ProfileMigration.swift`
- `Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Settings.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/EditProfileView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/ProfileListView.swift`
- `SnapDrill/Resources/zh-Hans.lproj/Localizable.strings`
- `SnapDrill/Resources/en.lproj/Localizable.strings`

### Design Decisions

- Fresh-install Settings still exposed the old default Profile name `同学`, which reintroduced a student-oriented signal in a release-facing UI surface.
- Default Profile fallback naming is now localized as `默认资料空间` / `Default Workspace` instead of hard-coded Chinese text in the Data layer.
- Profile switching rows now use selection-list semantics: the active workspace shows a checkmark, while inactive rows no longer show a disclosure chevron that incorrectly implies navigation to a detail page.
- Edit Profile basic-info rows now use system `LabeledContent` instead of fixed 80 pt labels, avoiding Dynamic Type and non-Chinese locale truncation.
- Source/category taxonomy terms such as `学科` / `来源` remain out of scope for this UI chrome cleanup and require a separate PO taxonomy decision.

### DoD Status

- Passed in this local change:
  - `swiftlint --strict`
  - `plutil -lint SnapDrill/Resources/zh-Hans.lproj/Localizable.strings SnapDrill/Resources/en.lproj/Localizable.strings`
  - `git diff --check`
  - XcodeBuildMCP fresh simulator install via uninstall + `build_run_sim`
  - XcodeBuildMCP screenshot of Settings > Switch Workspace confirming `默认资料空间`
  - XcodeBuildMCP screenshot of Edit Profile confirming `LabeledContent` rows and unobscured theme-color section
  - `xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests`

## 2026-06-21 - Settings profile row and detail chrome correction

### Scope

- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/SettingsView.swift`
- `Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/EditProfileView.swift`
- `docs/ui-redesign/REDESIGN-LOG.md`

### Design Decisions

- PO reported a second Settings visual issue: the "User / Edit profile" row looked shorter than the following row, and the pushed profile editor appeared to have content covered underneath.
- Root cause: the Settings profile entry still rendered a custom glass card inside a system `List` row, so its visual width, corner treatment, and layer stack did not match the native inset-grouped rows.
- The profile entry now uses the native inset-grouped row container and keeps only row content customizations: 52 pt avatar, headline/subheadline text, and standard row hit area.
- The Edit Profile form hides the app tab bar while editing, so the theme-color row is not visually covered by the floating iOS tab bar. Other Settings detail pages keep the tab bar available.

### DoD Status

- Passed in this local change:
  - XcodeBuildMCP `build_run_sim` for `SnapDrill` on iPhone 17 simulator
  - XcodeBuildMCP screenshots for Settings main page and Edit Profile detail page
  - `swiftlint --strict`
  - `git diff --check`
  - `xcodebuild build-for-testing -scheme AllTests -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan AllTests`
  - `xcodebuild test -scheme SnapDrill -testPlan UITests -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SnapDrillUITests/SnapDrillUITests/testCustomDimensionAppearsInCaptureForm`

### Follow-up Validation

- GitHub CI UI Tests exposed an over-broad first implementation that hid the tab bar on all Settings detail pages and broke `SnapDrillUITests.testCustomDimensionAppearsInCaptureForm()`, which intentionally switches tabs after configuring a custom dimension. The fix was narrowed to hiding the tab bar only on Edit Profile.

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
