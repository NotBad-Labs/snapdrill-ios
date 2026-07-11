# Phase 02f Candidate: Product Intent Dependency and Change-Budget Map

> **NON-NORMATIVE AUDIT ARTIFACT** — 本图只说明候选裁决会影响什么、按什么顺序验证和合并。
> 它不批准 Gate A/B/C，不改变 feature status，不授权修改、合并或发布。

## Baseline

- product base: `origin/develop@56e9d27e29e39fdcec083c4ec4e8a230edaa7f84`
- audit branch: `codex/repository-audit-phase04`
- implementation candidate: `codex/single-library-rebaseline@b670a2c8`, Draft PR #868
- main checkout: `develop@d62fead8`, untouched
- open write WIP: Draft PR #867 + Draft PR #868

## Dependency Graph

```text
PO exploration
  -> Gate A activation rule
  -> Product Constitution / typed product decisions
  -> Release 1 Product Contract
  -> feature What/Verify + generated intent/status indexes
  -> bounded runtime/UI/data implementation slices
  -> tests, dogfood, release evidence and public material
  -> separate PO merge / upload / release authorization
```

Reverse derivation is invalid: current tabs, existing code, feature-status rows, a Draft PR or a historical ADR cannot define the Product Constitution or Release 1.

## Change-Budget Scale

This is blast radius, not calendar estimation:

| Class | Typical surface | Required control |
|---|---|---|
| S | up to one authority and its direct pointers; mostly docs | docs gates + semantic review |
| M | several specs plus one UI/runtime flow and targeted tests | contract first, bounded implementation, T3/T4 evidence |
| L | multiple features or package boundaries, public/release effects | characterization, staged commits, broad regression and dogfood |
| XL | data/wire/lifecycle replacement across packages | dedicated product/data contract, rollback point, independent security/data review and T4 |

Counts below are frozen evidence where available. Pattern-search inventories identify consumers for review; they are not proof every matching file must change.

## D1 — Gate A Decision Activation

| Field | Inventory |
|---|---|
| authority first | `AGENTS.md` §意图与事实；`vision.md` header/derivation; `definition-of-ready.md` §PO Ruling Routing |
| direct policy consumers | `docs/README.md`; `po-decision-log.md`; `parallel-lanes.md`; `shape-up.md`; repository-audit charter/checkpoint |
| runtime/test/public | none unless a product decision is ratified in the same slice |
| budget | S |
| validation | docs generators/health, dead-pointer search, examples proving exploration is non-binding and merged authority is effective |

Required order: Gate A must land before any later product choice is called “effective.” The post-base Multi-Profile instruction can be ratified in the same contract commit but cannot be treated as the proof for its own activation rule.

## D2 — B1/B2/B3 Workflow Wedge, Promise and Core Chain

| Layer | Primary consumers |
|---|---|
| authority | `vision.md`; `positioning-and-audience.md`; optionally one typed product decision if the workflow wedge is explicitly provisional |
| product policy | `design-principles.md`; `business-model.md`; `assumptions.md`; `user-journeys.md`; `scope-and-roadmap.md`; review `competitive-analysis.md` only if differentiation/competitor claims change |
| feature intent | capture, library, export, onboarding, dashboard, review and SmartPaper specs; frontmatter only changes when an upstream reference truly changes |
| user-visible/public | Onboarding L10n/view; permission usage descriptions; tab emphasis; Dashboard/Review/SmartPaper labels; `appstore-metadata.md`; screenshot/QA matrices; website/legal copy in their owning repositories |
| tooling/tests/evidence | docs/Capture validators and tests; onboarding/navigation UI tests; `plutil` for both strings files; snapshots; AX routes; moderated dogfood script; metadata review |
| budget | S only when authority changes without user-visible copy; M when onboarding/tab/metadata copy changes; M/L if B3 changes top-level IA or hides features |

Shared seams: `vision.md`, Onboarding copy, `AppRootView`, L10n strings, UI evidence ownership. D2 must precede D6/D7 so Release 1 and navigation do not independently redefine the core chain.

## D3 — B4/B5 Data Posture and Single-Library Behavior

### Contract consumers

- Vision P4 / data product policy; positioning privacy facts; business free/sync policy.
- `feat-profile.md` or replacement local-library spec; onboarding, backup, capture, library, export, settings, dashboard, review, SmartPaper and iCloud specs.
- architecture, NFR, backup-wire reference, API pitfalls, glossary, user journeys, release checklist and generated feature/intent indexes.

### Frozen candidate blast radius

Draft PR #868 changes 126 files: 35 SnapDrillData, 28 SnapDrillFeatures, 20 SnapDrillCore, 29 docs, 5 app files, 5 UI-test files and 4 SnapDrillUI/AGENTS surfaces. Its observed diff is 1,695 insertions / 4,417 deletions.

### Runtime/data consumers

- App composition/session ownership and environment injection.
- Profile models/manager/vault/migration/preferences and all per-profile service keys.
- fixed store/image/draft paths, repository construction, recovery events and lifecycle blocking.
- backup schema/golden fixtures, extraction/staging/rollback and old-wire handling.
- Settings profile UI, backup coordinator, Dashboard header, notification/review/capture preferences.
- Onboarding default-library creation, global completion state and Profile-scoped TipKit state; export activity/switch-block wording.
- Core/Data/Features tests, Settings UI tests and AX navigation.

| Field | Value |
|---|---|
| budget | XL |
| red lines | no silent data deletion after first external-user boundary; image path/EXIF/archive limits; explicit backup compatibility; MigrationPlan only for the chosen live schema |
| validation | Core/Data/Feature tests; frozen current BackupWireV2 fixtures imported and restored by the replacement, or an explicit PO-ratified incompatibility with user-facing rejection; failure injection; `SnapDrill` scheme + `UITests` test plan UI/AX runs; physical-device recovery/backup dogfood; independent security/data review; build is required but never completion proof |

PO decides user-visible product behavior and compatibility appetite. Engineering decides whether any Profile abstraction remains. #868 should be rebased only after its upstream product/data contract is effective.

## D4 — B6/C5 Commercial Posture and SmartPaper

| Layer | Primary consumers |
|---|---|
| authority | `business-model.md`; typed status/supersession of ADR-001; Release 1 Contract |
| feature specs | SmartPaper, advanced stats, iCloud sync, image enhance, Word export; export/library/review where linked |
| runtime/UI | `ProEntitlementProvider`; SmartPaper View/ViewModel/router/Library entry; Dashboard analytics Pro gate; L10n insights/settings; export completion quota callback; in-app PrivacyPolicyView and paired Pro/iCloud policy strings |
| data/preferences | quota month/use keys in `UserDefaultsKeys.swift`; `ProfileManager+Preferences.swift` and related Profile preference ownership; per-profile or device-level storage chosen after B5 |
| tests | SmartPaper selection/quota/month-reset/export tests; entitlement/container tests; Dashboard copy/UI; AX reachable-route matrix |
| public | glossary Pro entry; metadata price/IAP; screenshots; privacy/business copy if StoreKit/CloudKit is exposed |
| budget | M for entry/copy-only hide; L for quota/month-reset or per-profile↔device preference changes; L/XL for StoreKit + CloudKit + public subscription launch |

Decision seams that must not be collapsed:

1. visible/hidden SmartPaper;
2. basic random versus precise SM-2 selector;
3. unlimited versus quota;
4. Pro copy/purchase availability;
5. ADR-001 current/suspended/superseded status.

Any implementation slice must inspect ProEntitlement, SmartPaper quota/export, Dashboard Pro gates, purchase/future-feature copy, in-app privacy Pro/iCloud claims and public metadata. Generic unreachable `.placeholder -> comingSoon` router stubs are not commercial consumers unless shaping also makes them reachable.

Any D4 change touching quota keys or preference scope waits for an effective B5 data decision and the #868 rescope base; otherwise it is implemented once against Multi-Profile and again against the single-library candidate.

## D5 — B7 Platform, Region and Language

| Layer | Primary consumers |
|---|---|
| authority | affirmative production/platform policy; suspended ADR-003/004 pointers; Release 1 Contract |
| build/config | live root `Debug.xcconfig` / `Release.xcconfig` -> `Configs/Shared.xcconfig`; `SnapDrill.xcodeproj/project.pbxproj` device family/orientations/regions/build settings; app/share entitlements; bundle/team/App Group; Privacy Manifest; schemes/test destinations |
| runtime identity | hard-coded App Group consumers in `SnapDrill/App/AppRouter.swift`, `SnapDrillShare/ShareViewController.swift`, `SnapDrillShare/SharedContainerImageWriter.swift` and `SnapDrillCore/Service/LiveMetricService.swift` |
| UI/product | adaptive layout, iPad sidebar/comments, localized resources, Onboarding/policy/help/feedback URLs |
| release/public | `release-and-ci.md`, NFR, Apple platform limits, App Store metadata/localizations, screenshot sets, support/legal URLs |
| verification | archive/export/upload/install, signing profiles, App Group Share round trip, iPhone viewport/rotation, language completeness, public fact/legal review |
| budget | S/M to affirm current iPhone/global/en+zh-Hans facts; L for iPad; XL for China-specific build revival |

Production Team/Bundle/App Group facts are empirical constraints. PO chooses platform/market scope; agents cannot infer a new region from dormant resources.

`Configs/Debug.xcconfig` and `Configs/Release.xcconfig` are currently unreferenced duplicates, not live D5 consumers. They remain outside a product/platform change until Phase 11 proves they can be deleted as configuration debt.

## D6 — C1/C2/C6 Release Target, Must Outcomes and Acceptance

| Layer | Primary consumers |
|---|---|
| new authority | one dated Release 1 Product Contract with artifact, Must outcomes, non-goals, accepted debt and compatibility boundary |
| derived specs | only affected feature What/Verify sections; `feature-status.md` remains implementation state, not release membership |
| operational | release checklist, CI/test-plan coverage map, dogfood script, feedback/support packet, privacy/network/signing evidence |
| runtime | none merely because a contract is written; gaps found by acceptance become separate bounded fixes |
| budget | S for contract; subsequent fixes independently sized |

Must evidence families:

- new/returning user and no-account entry;
- capture with failed OCR/denied permission/cancel/draft/storage failure;
- find/edit/delete/undo;
- PDF/print/share/save and cancellation;
- backup/restore/corrupt-store recovery without silent prior-data loss;
- local/uninstall trust and no unexpected content upload;
- AX/Dynamic Type/localization;
- archive -> TestFlight -> install -> App Group/Share Extension round trip;
- public copy/privacy/entitlements/network/support agreement.

D6 must distinguish internal TestFlight from public App Store acceptance. Public submission cannot inherit an internal dogfood waiver silently.

Review/Dashboard/SmartPaper behavior enters the Must evidence list only if C3/C4/C5 classifies it as Release 1 Must. Any reachable optional feature still needs no-crash/dead-end, AX and accepted-debt regression evidence; implementation status alone cannot promote it to a Must outcome.

## D7 — C3/C4 Dashboard and Review IA

| Layer | Primary consumers |
|---|---|
| authority | core-chain clause + Release 1 Contract + Dashboard/Review specs |
| composition | `AppRootView.swift`; `AppRouter.swift`; Dashboard/Review routers; notification-based tab switches |
| UI/L10n | five tab labels/icons/order; Dashboard cards/header/analytics; Review entry/session/settings; onboarding/screenshots |
| tests | router/tab UI tests; Dashboard/Review unit tests; snapshots; AX navigation/reporting; Dynamic Type screenshots |
| budget | M to change default tab or demote one entry; L if removing/merging modules or changing package composition |

Current five-tab IA is characterization evidence, not product authority. An internal dogfood experiment requires a named re-decision trigger; public screenshots make the chosen IA a soft external commitment.

## D8 — Success Signals and No-Telemetry Learning

| Layer | Primary consumers |
|---|---|
| authority | Vision success definition or explicitly owned success-policy section; `assumptions.md`; business H4-H8 |
| evidence policy | ADR-005; analytics-events reference; release feedback/support guide |
| runtime | existing NoOp analytics + MetricKit remain; no event SDK/identifier/consent expansion implied |
| instruments | moderated task script, TestFlight feedback form, short follow-up interview, App Store Connect aggregate quality/retention |
| budget | S docs/evidence design; any new telemetry is a separate privacy/product decision |

The method, owner, sample boundary and falsification criterion must be named before claiming that TestFlight will resolve a hypothesis.

## Shared Seams and Serialization

These files cannot be assigned to parallel write lanes without a prior contract or explicit ownership split:

- `vision.md`, `positioning-and-audience.md`, `business-model.md`;
- `po-decision-log.md`, typed decision records and Release 1 Contract;
- `AppRootView.swift`, `AppRouter.swift` and cross-feature tab/navigation tests;
- shared L10n files and both `Localizable.strings` files;
- `ProfileManager*.swift`, `UserDefaultsKeys.swift`, `MigrationPlan.swift`, backup DTO/golden fixtures and SmartPaper View/ViewModel while #868 remains open;
- generated feature-status/intent indexes;
- `AGENTS.md`, release guide, NFR and public metadata.

Safe sequence under write WIP <= 2:

1. Keep #868 frozen as implementation evidence.
2. Gate A/constitution/release-contract work needs a docs-only branch based on latest `develop`.
3. Because #867 already occupies the audit write slot, no contract branch can open until the PO separately authorizes merging #867 as audit evidence or closes it and explicitly accepts that its audit evidence remains unmerged with a durable recovery pointer. A third branch is not allowed.
4. Recommended clean sequence: merge #867 only with separate PO authorization; open/merge a small contract branch while #868 remains frozen; rebase and rescope #868 onto the effective contract. Do not retarget #867: mixing normative product changes into the audit branch breaks audit/fix separation.
5. While #868 remains open, D3/D4/D7 implementation is serial unless shaping publishes a concrete non-overlapping file set; the current sets collide on Profile preferences, SmartPaper, L10n, AppRoot and tests. A second implementation lane is available only after #868 is merged/closed/rescoped so its ownership is explicit. Every merge remains serial and separately authorized.

Putting the contract only inside #868 makes it effective atomically with 126-file implementation rather than providing a stable upstream base.

## Post-Decision Verification Matrix

| Decision cluster | Minimum validation level | Evidence before completion |
|---|---|---|
| D1/D2 authority only | T1/T2 | docs gates, semantic link review, no unresolved conflicting owner |
| D3 data/library | T4 | data/security tests, frozen-wire compatibility or explicit rejection, failure/rollback matrix, build, `SnapDrill` scheme + `UITests` test plan UI/AX and physical dogfood |
| D4 SmartPaper/Pro UI | T3; T4 if quota/entitlement persistence changes | targeted unit plus `SnapDrill` scheme + `UITests` test plan UI/AX, copy grep, export completion and month-boundary tests |
| D5 platform/release | T4 | archive/sign/export/upload/install, App Group/Share, device/language/screenshots |
| D6 release contract | T3/T4 by Must journey | every outcome has direct automated or dogfood oracle; no checklist-only green |
| D7 navigation | T3 | `SnapDrill` scheme + `UITests` test plan UI/AX, Dynamic Type/screenshots and task-based dogfood |
| D8 learning | T1 design, T3 execution | reproducible script, consent/feedback owner, evidence packet and explicit limitations |

## Stop Conditions

- a candidate option is treated as approved without PO ratification;
- a downstream spec/code diff is used to rewrite upstream intent;
- write WIP would exceed 2;
- a product/data contract and implementation are merged out of order;
- legal, Apple platform or live-code facts are inferred from agent preference;
- a merge, TestFlight upload or public release lacks its separate PO authorization.
