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
  screenshots. Static grep is not sufficient.

## Current Findings

| ID | Severity | Surface | Evidence | Status |
| --- | --- | --- | --- | --- |
| UI-FZ-001 | P1 | Settings > Edit Profile > Theme color | Selected swatch used `Color.primary` stroke on the swatch boundary, producing a black ring in light mode and clipped stroke at the row edge. | Fixed in `EditProfileView`: selected swatch now uses reserved 56 pt hit/draw area, accent ring, and white checkmark. |
| UI-FZ-002 | P2 | Library taxonomy manager > Edit value > Color | Same `Color.primary` swatch-selection pattern existed in category value color picker. | Fixed in `EditCategoryValueView`: selected swatch now uses reserved frame, accent ring, white checkmark, and `.isSelected`. |

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
| App shell | Tab bar + root loading + degraded-mode banner | `AppRootView` | normal profile, in-memory fallback | In progress |
| Onboarding | First-run onboarding | `OnboardingView` full-screen cover | first launch, skip/finish, Dynamic Type | In progress |
| Dashboard | Home tab empty state | `DashboardView` | no items | In progress |
| Dashboard | Home tab populated | `DashboardView`, `ReviewHeroCard`, bento grid, analytics | due items, all done, analytics locked/unlocked | Needs data |
| Dashboard | Category manager sheet | `DashboardView` -> `CategoryManagerView` | list, add dimension, edit value | In progress |
| Library | Library tab empty/list/search/filter chrome | `LibraryView`, `LibraryListView` | empty, populated, search, selection mode | Needs data |
| Library | Filter sheet | `LibraryFilterSheet` | no filters, selected filters, reset/apply | Needs data |
| Library | Batch tag sheet | `BatchTagSheet` | no tags, selected tags | Needs data |
| Library | Export sheet + PDF preview + share | `ExportOptionsSheet`, `ExportPreviewView` | PDF, CSV, ZIP, no image / image items | Needs data |
| Library | Detail page | `LibraryDetailView` | text-only, image item, answer shown, share card | Needs data |
| Library | Edit item | `LibraryEditView` | text/image item, cropper, field rows | Needs data |
| Library | Full-screen image | `FullScreenImageView` | portrait/landscape image, zoom/pan | Needs data |
| Library | Taxonomy manager | `CategoryManagerView`, `CategoryValueListView` | list, add/edit/delete dimension values | In progress |
| Library | Edit taxonomy value | `EditCategoryValueView` | preset color selected, custom color selected, symbol picker | Code fixed; needs simulator screenshot |
| Library | Symbol picker | `SFSymbolPickerView` | search, selected symbol, empty search | In progress |
| Capture | Capture tab method grid | `CaptureView`, `CaptureMethodCard` | regular text size, accessibility text size | In progress |
| Capture | Camera scanner | `SmartCameraView` | simulator unavailable camera, controls, close | Needs device/simulator capability |
| Capture | Document scanner | `DocumentScannerView` | scanner unavailable/available | Needs device capability |
| Capture | PDF page picker | `PDFPagePickerView` | multi-page PDF, cropper | Needs data |
| Capture | Scan page picker | `ScanPagePickerView` | multi-page scan, cropper | Needs data |
| Capture | Result editor | `CaptureResultView` + sections | manual text, image text, field config tip, cropper | Needs data |
| Review | Review tab empty state | `ReviewView`, `ReviewDashboardView` | no items | Pass in recent run; keep in matrix for re-screenshot if UI changes |
| Review | Review tab idle populated | `ReviewDashboardView` | due items, all done | Needs data |
| Review | Active card session | `ReviewView`, `ReviewActionButtons`, card front/back | flip, swipe, undo, pause, summary | Needs data |
| Review | Card edit sheets | `ReviewCardContent`, `ReviewCardBack` | edit from front/back | Needs data |
| Settings | Settings main page | `SettingsView` | normal rows, toggles, tab bar, Dynamic Type | In progress |
| Settings | Edit profile | `EditProfileView` | default symbol avatar, theme swatches, photo avatar, symbol picker | Default symbol-avatar swatch fixed and simulator-reviewed; photo-avatar and symbol-picker states still in progress |
| Settings | Profile list | `ProfileListView` | one profile, multiple profiles, delete disabled/enabled | In progress |
| Settings | Data and sync | `DataAndSyncSettingsView` | export, import, backup progress, restore dialog | Needs data |
| Settings | Privacy/export | `PrivacySettingsView` | export options, clear data confirmation | In progress |
| Settings | Review appearance | `ReviewAppearanceSettingsView` | front/back previews | In progress |
| Settings | Notifications | `NotificationSettingsView` | enabled/disabled, permission denied/granted | Needs device/system permission state |
| Settings | Language | `LanguageSettingsView` | current language, switch confirmation | In progress |
| Settings | Storage | `StorageManagementView` | image cache populated/empty | Needs data |
| Settings | Legal/info pages | `PrivacyPolicyView`, `TermsOfServiceView`, `LicenseView` | scroll, link rows, license detail | In progress |

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
