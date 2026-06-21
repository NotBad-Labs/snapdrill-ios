# UI Freeze QA Matrix

> This is the active UI-freeze verification checklist. It is not a completion
> claim. Do not call the UI layer frozen until every release-facing row is either
> `Pass` with evidence or explicitly `Deferred` with a PO/legal/data reason.

## Review Basis

- Apple HIG: prefer platform-familiar navigation, lists, forms, selection, and
  input patterns over custom chrome when the screen is a settings or data-entry
  task.
- Apple HIG: system colors and materials adapt across appearance and
  accessibility settings; selection indicators must remain visible without
  relying on `Color.primary` on top of arbitrary swatches.
- Repo rule: UI verification must combine static risk scan with simulator
  screenshots or XCUITest screenshot attachments. Static grep is not sufficient.
- Native screenshot tests run through the `SnapDrill` scheme with the `UITests`
  test plan. `AllTests` remains the package/unit build gate and does not execute
  the native `SnapDrillUITests` target.

## Current Findings

| ID | Severity | Surface | Evidence | Status |
| --- | --- | --- | --- | --- |
| UI-FZ-001 | P1 | Settings > Edit Profile > Theme color | Selected swatch used `Color.primary` stroke on the swatch boundary, producing a black ring in light mode and clipped stroke at the row edge. | Fixed in `EditProfileView`: selected swatch now uses reserved 56 pt hit/draw area, accent ring, and white checkmark. |
| UI-FZ-002 | P2 | Library taxonomy manager > Edit value > Color | Same `Color.primary` swatch-selection pattern existed in category value color picker. | Fixed in `EditCategoryValueView`: selected swatch now uses reserved frame, accent ring, white checkmark, and `.isSelected`. |
| UI-FZ-003 | P2 | Review tab empty state | Review used Dashboard/Library empty-state copy (`还没有任何资料` / `开始采集`), making the Review tab look like the wrong surface. Before: `docs/ui-redesign/evidence/2026-06-21-review-empty-before.jpg`. | Fixed in `ReviewDashboardView`: Review now uses Review-specific title, description, icon, and CTA. After: `docs/ui-redesign/evidence/2026-06-21-review-empty-after.jpg`. |
| UI-FZ-004 | P2 | Shared symbol picker from Profile and taxonomy editors | `SFSymbolPickerView` still exposed hard-coded Chinese, education-oriented category titles such as `学术`, `数学/逻辑`, `理化/实验`, and `体育/运动`, and the selected icon state needed the same visible accent/check treatment as the color swatches. | Fixed in `SFSymbolPickerView`: categories are localized general-audience groups, item selection uses accent ring + checkmark + `.isSelected`, and `testIconPickerUsesGeneralAudienceCategories` covers visible categories plus selection round-trip. Evidence: `docs/ui-redesign/evidence/2026-06-21-icon-picker-general-audience.png`. |
| UI-FZ-005 | P2 | Settings main page > floating tab bar underlap | The initial Settings viewport allowed the next `回顾设置` section to remain readable through the iOS floating tab bar, making it look like a row was covered. Before: `docs/ui-redesign/evidence/2026-06-21-settings-main-tabbar-before.png`. | Fixed in `SettingsView`: the capture-field section now reserves named breathing room before the next section, so the field group remains complete and the tab bar sits over empty background. After: `docs/ui-redesign/evidence/2026-06-21-settings-main-tabbar-after.png`; covered by `testUIFreezePrimaryTabSurfaceScreenshots`. |
| UI-FZ-006 | P1 | Settings secondary long-scroll pages > floating tab bar underlap | Settings secondary screenshot pass found readable content under the tab bar in Data & Sync, Privacy Policy, and Terms. Before: `2026-06-21-settings-data-sync-tabbar-before.png`, `2026-06-21-settings-privacy-policy-tabbar-before.png`, `2026-06-21-settings-terms-tabbar-before.png`. | Fixed by hiding the tab bar on self-contained long Settings detail pages (`EditProfileView`, `ReviewAppearanceSettingsView`, `DataAndSyncSettingsView`, `PrivacyPolicyView`, `TermsOfServiceView`) while keeping Category Manager tab access for the existing category-to-capture E2E flow. Covered by `testUIFreezeSettingsSecondarySurfaceScreenshots`; after evidence: `docs/ui-redesign/evidence/2026-06-21-settings-secondary-*.png`. Legal text itself remains legal-gated and unchanged. |
| UI-FZ-007 | P2 | Library populated list > quick filter chips | Library populated-state screenshots showed unselected subject chips as naked text, with the right edge exposing a clipped half glyph. This read like broken layout rather than a horizontal filter rail. | Fixed in `LibraryListView`: unselected chips now keep visible rounded capsule backgrounds and strokes, selected chips stay accent-filled, and edge clipping reads as scroll affordance. Evidence: `docs/ui-redesign/evidence/2026-06-21-library-01-populated-list.png`, `docs/ui-redesign/evidence/2026-06-21-library-04-filtered-list.png`. |
| UI-FZ-008 | P2 | Library selection mode > bottom toolbar | The selected-count label rendered in the bottom toolbar as a circular Liquid Glass-looking control, making status text look like a tappable action. | Fixed in `LibraryView`: selection count moved to the navigation title while the bottom toolbar contains only explicit actions. Evidence: `docs/ui-redesign/evidence/2026-06-21-library-07-selection-toolbar.png`. |
| UI-FZ-009 | P3 | Library batch tag sheet > empty state | Batch tag sheet reused the Library empty-item copy (`还没有题目`) inside a tag-management context. | Fixed in `BatchTagSheet`: empty tag state now says `还没有标签`. Evidence: `docs/ui-redesign/evidence/2026-06-21-library-08-batch-tag-sheet.png`. |
| UI-FZ-010 | P2 | Capture > result editor | Manual-result editor screenshots showed a self-contained editing flow still carrying the app tab bar. It did not fully obscure content, but it was inconsistent with the Settings edit/detail rule and made subject menus compete with bottom app navigation. | Fixed in `CaptureResultView`: tab bar is hidden while preview/edit is active and restored after save/back navigation. Covered by `testUIFreezeCaptureManualResultEditorScreenshots`; evidence: `docs/ui-redesign/evidence/2026-06-21-capture-01-manual-empty-editor.png`, `docs/ui-redesign/evidence/2026-06-21-capture-05-saved-back-to-capture.png`. |

## Static Risk Queries

Run these before each UI-freeze claim and route every hit into this matrix:

```bash
rg -n "stroke\\(Color\\.primary|strokeBorder\\(Color\\.primary|\\.stroke\\(\\.primary|\\.strokeBorder\\(\\.primary" \
  Packages/SnapDrillFeatures/Sources Packages/SnapDrillUI/Sources SnapDrill/App -g '*.swift'

rg -n "listRowBackground\\(Color\\.clear|listRowInsets|listRowSeparator\\(\\.hidden|toolbar\\(\\.hidden, for: \\.tabBar|ignoresSafeArea|glassEffect|frame\\(width:|frame\\(height:" \
  Packages/SnapDrillFeatures/Sources Packages/SnapDrillUI/Sources SnapDrill/App -g '*.swift'

rg -n "struct .*View: View|public struct .*View: View|navigationDestination|sheet\\(|fullScreenCover|confirmationDialog|popover" \
  Packages/SnapDrillFeatures/Sources Packages/SnapDrillUI/Sources SnapDrill/App -g '*.swift'
```

## Surface Matrix

Legend:

- `Pass`: simulator-reviewed and static-risk-reviewed for the current UI-freeze pass.
- `In progress`: known surface, not yet fully verified in this matrix.
- `Needs data`: requires non-empty library/profile/category data or device capability.
- `Deferred`: outside current engineering authority, with reason.

| Area | Surface | Entry / route | Required states | Status |
| --- | --- | --- | --- | --- |
| App shell | Tab bar + root loading + degraded-mode banner | `AppRootView` | normal profile, in-memory fallback | Normal primary-tab navigation screenshot-covered; degraded-mode banner still In progress |
| Onboarding | First-run onboarding | `OnboardingView` full-screen cover | first launch, skip/finish, Dynamic Type | In progress |
| Dashboard | Home tab empty state | `DashboardView` | no items | Pass: XCUITest screenshot `docs/ui-redesign/evidence/2026-06-21-primary-dashboard-empty.png` |
| Dashboard | Home tab populated | `DashboardView`, `ReviewHeroCard`, bento grid, analytics | due items, all done, analytics locked/unlocked | Needs data |
| Dashboard | Category manager sheet | `DashboardView` -> `CategoryManagerView` | list, add dimension, edit value | In progress |
| Library | Library tab empty/list/search/filter chrome | `LibraryView`, `LibraryListView` | empty, populated, search, selection mode | Empty root chrome Pass: `docs/ui-redesign/evidence/2026-06-21-primary-library-empty.png`; populated quick-filter rail Pass: `docs/ui-redesign/evidence/2026-06-21-library-01-populated-list.png`; selected quick-filter state Pass: `docs/ui-redesign/evidence/2026-06-21-library-04-filtered-list.png`; selection toolbar Pass: `docs/ui-redesign/evidence/2026-06-21-library-07-selection-toolbar.png`; search still In progress |
| Library | Filter sheet | `LibraryFilterSheet` | no filters, selected filters, reset/apply | Default and selected-filter states Pass: `docs/ui-redesign/evidence/2026-06-21-library-02-filter-sheet.png`, `docs/ui-redesign/evidence/2026-06-21-library-03-filter-selected.png`; reset edge state still In progress |
| Library | Batch tag sheet | `BatchTagSheet` | no tags, selected tags | No-tag state Pass: `docs/ui-redesign/evidence/2026-06-21-library-08-batch-tag-sheet.png`; selected-tag state still Needs data |
| Library | Export sheet + PDF preview + share | `ExportOptionsSheet`, `ExportPreviewView` | PDF, CSV, ZIP, no image / image items | Text-only PDF export options and preview Pass: `docs/ui-redesign/evidence/2026-06-21-library-09-export-sheet.png`, `docs/ui-redesign/evidence/2026-06-21-library-10-export-preview.png`; CSV/ZIP/share activity and image-heavy states still Needs data |
| Library | Detail page | `LibraryDetailView` | text-only, image item, answer shown, share card | Text-only detail Pass: `docs/ui-redesign/evidence/2026-06-21-library-05-detail-text.png`; image, answer-expanded, and share-card states still Needs data |
| Library | Edit item | `LibraryEditView` | text/image item, cropper, field rows | Text-only edit sheet first viewport Pass: `docs/ui-redesign/evidence/2026-06-21-library-06-edit-sheet.png`; image/cropper and deeper field interaction states still Needs data |
| Library | Full-screen image | `FullScreenImageView` | portrait/landscape image, zoom/pan | Needs data |
| Library | Taxonomy manager | `CategoryManagerView`, `CategoryValueListView` | list, add/edit/delete dimension values | Category manager list Pass: `docs/ui-redesign/evidence/2026-06-21-settings-secondary-09-category-manager.png`; value-list and edit sheets still In progress |
| Library | Edit taxonomy value | `EditCategoryValueView` | preset color selected, custom color selected, symbol picker | Code fixed; needs simulator screenshot |
| Library | Symbol picker | `SFSymbolPickerView` | search, selected symbol, empty search | Pass for default selected state and visible default categories via XCUITest screenshot attachment; search and empty-search states still need visual pass |
| Capture | Capture tab method grid | `CaptureView`, `CaptureMethodCard` | regular text size, accessibility text size | Regular text size Pass: `docs/ui-redesign/evidence/2026-06-21-primary-capture-methods.png`; accessibility text size still In progress |
| Capture | Camera scanner | `SmartCameraView` | simulator unavailable camera, controls, close | Needs device/simulator capability |
| Capture | Document scanner | `DocumentScannerView` | scanner unavailable/available | Needs device capability |
| Capture | PDF page picker | `PDFPagePickerView` | multi-page PDF, cropper | Needs data |
| Capture | Scan page picker | `ScanPagePickerView` | multi-page scan, cropper | Needs data |
| Capture | Result editor | `CaptureResultView` + sections | manual text, image text, field config tip, cropper | Manual text editor, keyboard, subject menu, selected subject, and saved-return states Pass after UI-FZ-010: `docs/ui-redesign/evidence/2026-06-21-capture-01-manual-empty-editor.png` through `docs/ui-redesign/evidence/2026-06-21-capture-05-saved-back-to-capture.png`; image text, field config tip, and cropper still Needs data |
| Review | Review tab empty state | `ReviewView`, `ReviewDashboardView` | no items | Pass: simulator-reviewed on iPhone 17 after UI-FZ-003; evidence `docs/ui-redesign/evidence/2026-06-21-review-empty-after.jpg` and `docs/ui-redesign/evidence/2026-06-21-primary-review-empty.png` |
| Review | Review tab idle populated | `ReviewDashboardView` | due items, all done | Needs data |
| Review | Active card session | `ReviewView`, `ReviewActionButtons`, card front/back | flip, swipe, undo, pause, summary | Needs data |
| Review | Card edit sheets | `ReviewCardContent`, `ReviewCardBack` | edit from front/back | Needs data |
| Settings | Settings main page | `SettingsView` | normal rows, toggles, tab bar, Dynamic Type | Normal rows/toggles/tab bar Pass after UI-FZ-005: `docs/ui-redesign/evidence/2026-06-21-primary-settings-main.png`; Dynamic Type still In progress |
| Settings | Edit profile | `EditProfileView` | default symbol avatar, theme swatches, photo avatar, symbol picker | Default symbol-avatar swatch fixed and screenshot-covered: `docs/ui-redesign/evidence/2026-06-21-settings-secondary-01-edit-profile.png`; shared symbol picker component covered by UI-FZ-004; photo-avatar state still Needs data |
| Settings | Profile list | `ProfileListView` | one profile, multiple profiles, delete disabled/enabled | One-profile state Pass: `docs/ui-redesign/evidence/2026-06-21-settings-secondary-02-profile-list.png`; multi-profile/delete states still Needs data |
| Settings | Data and sync | `DataAndSyncSettingsView` | export, import, backup progress, restore dialog | Default local-data state Pass after UI-FZ-006: `docs/ui-redesign/evidence/2026-06-21-settings-secondary-05-data-sync.png`; progress/dialog states still Needs data |
| Settings | Privacy/export | `PrivacySettingsView` | export options, clear data confirmation | Default state Pass: `docs/ui-redesign/evidence/2026-06-21-settings-secondary-07-privacy-export.png`; export dialog/share states still In progress |
| Settings | Review appearance | `ReviewAppearanceSettingsView` | front/back previews | Default preview state Pass after UI-FZ-006: `docs/ui-redesign/evidence/2026-06-21-settings-secondary-03-review-appearance.png`; interaction states still In progress |
| Settings | Notifications | `NotificationSettingsView` | enabled/disabled, permission denied/granted | Disabled state Pass: `docs/ui-redesign/evidence/2026-06-21-settings-secondary-04-notifications.png`; permission states still Needs device/system state |
| Settings | Language | `LanguageSettingsView` | current language, switch confirmation | Current-language state Pass: `docs/ui-redesign/evidence/2026-06-21-settings-secondary-08-language.png`; restart alert state still In progress |
| Settings | Storage | `StorageManagementView` | image cache populated/empty | Empty-cache state Pass: `docs/ui-redesign/evidence/2026-06-21-settings-secondary-06-storage.png`; populated cache still Needs data |
| Settings | Legal/info pages | `PrivacyPolicyView`, `TermsOfServiceView`, `LicenseView` | scroll, link rows, license detail | Privacy Policy and Terms first viewport Pass after UI-FZ-006: `docs/ui-redesign/evidence/2026-06-21-settings-secondary-10-privacy-policy.png`, `docs/ui-redesign/evidence/2026-06-21-settings-secondary-11-terms.png`; legal content remains legal-gated; License still In progress |

## Exit Criteria

- No `Color.primary` selection ring on arbitrary color swatches.
- No selected indicator clipped by its own frame or list row.
- Each system `List` / `Form` page uses native row semantics unless a custom row
  is explicitly justified.
- Every `toolbar(.hidden, for: .tabBar)` occurrence is justified by a full-screen
  or editor workflow and has a simulator screenshot proving no bottom content is
  obscured.
- Every `listRowBackground(Color.clear)` hit is either visually verified or
  converted back to native grouped rows.
- All rows in the Surface Matrix are resolved before the UI layer is called
  frozen.
