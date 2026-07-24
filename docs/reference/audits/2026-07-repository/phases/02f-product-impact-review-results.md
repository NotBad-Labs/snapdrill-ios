# Phase 02f Results: Product Intent Impact Map Review

> **文档状态：固定基线历史证据。** 本文只描述当时基线，不提供当前排期或执行授权；当前恢复入口见 `docs/reference/audits/2026-07-repository/README.md`，产品规范见 `docs/product/vision.md` 与 `docs/product/release-1-prd.md`。

## Outcome

The impact map is fit to guide later Gate B/C work after correction. Codex,
Claude Fable 5, Antigravity Gemini 3.5 Flash (High) and Grok 4.5 converged that
the dependency order is sound, but the first draft omitted several live runtime
and verification consumers and allowed an unsafe branch-retarget option.

No new ledger finding was created. The map refines the blast radius and execution
controls for RA-02-014, RA-02-015 and RA-02-017; it does not ratify Gate A/B/C or
authorize a merge.

## T0

- product base: `origin/develop@56e9d27e29e39fdcec083c4ec4e8a230edaa7f84`
- primary checkout: `/Users/yiming/Developer/snapdrill-audit-fixed-56e9d27e`, read-only and clean
- candidate/review worktree: `/private/tmp/snapdrill-repository-audit-phase04`
- implementation evidence: Draft PR #868 at `b670a2c8`
- write WIP: Draft PR #867 + Draft PR #868; no third branch
- main checkout remained at `d62fead8`; pre-existing `agent-reports/` untouched

## Accepted Corrections

### 1. User-visible wording is not an S-class authority-only change

Onboarding, tabs and App Store metadata are T3 product surfaces even when the
underlying product rule is unchanged. D2 now reserves S for authority changes
with no user-visible copy and classifies copy changes as M.

### 2. Single-library has additional direct product consumers

Onboarding and export encode Profile-scoped behavior even though they do not own
the storage implementation. D3 now names onboarding completion/TipKit behavior,
export activity wording and their tests as first-class consumers.

### 3. Data compatibility cannot be proved by regenerated fixtures

A replacement can pass golden tests if the fixtures are rewritten alongside the
code. D3 now requires the frozen current BackupWireV2 fixtures to import and
restore through the replacement, unless the PO explicitly ratifies incompatibility
and the product gives a user-facing rejection. This remains conditional on the
pending no-user/no-compatibility ruling rather than inventing migration work.

### 4. `AllTests` build is not UI or AX execution

The native UI tests are not run by the `AllTests` test plan. D3, D4 and D7 now
name the `SnapDrill` scheme and `UITests` test plan, in addition to unit tests and
build evidence.

### 5. Commercial changes cross preference and policy surfaces

D4 now includes `UserDefaultsKeys.swift`, `ProfileManager+Preferences.swift`,
in-app `PrivacyPolicyView` and paired Pro/iCloud policy strings. Entry/copy hiding
is M; quota/month reset is L; StoreKit + CloudKit exposure remains L/XL. Quota
work is serialized behind an effective B5 decision and #868 rescope.

### 6. Platform identity has live runtime consumers and dead duplicates

D5 now includes `SnapDrill.xcodeproj/project.pbxproj`, the live root Debug/Release
xcconfigs, entitlements and hard-coded App Group consumers in AppRouter, the Share
Extension writer/controller and LiveMetricService. The duplicate files under
`Configs/Debug.xcconfig` and `Configs/Release.xcconfig` are unreferenced and are
deferred to Phase 11 cleanup rather than treated as product consumers.

### 7. Broad router placeholders are not commercial requirements

Generic unreachable `.placeholder -> comingSoon` routes matched the search but do
not implement a Pro promise. D4 now limits mandatory review to named/reachable Pro,
SmartPaper, quota, purchase and iCloud surfaces.

### 8. Audit and normative contract work must remain separate

Retargeting #867 as a contract branch would mix evidence with product authority.
The map now allows a contract branch only after the PO separately merges #867 or
closes it while accepting unmerged evidence and a durable recovery pointer. The
recommended sequence remains audit merge, small contract branch, then #868 rebase
and rescope; every merge requires separate authorization.

## Rejected Or Bounded Concerns

### Exclude onboarding because it does not depend on SnapDrillData

Rejected. The map records normative and behavioral consumers, not only module
imports. `feat-onboarding.md` and onboarding state encode Profile creation,
completion and TipKit semantics that B5 changes directly.

### Make Review a Release 1 Must because it is implemented and free

Rejected. Implementation status cannot promote a feature into the release
contract. D6 includes Review only if C4 classifies it as Must; reachable optional
behavior still needs no-crash, AX and accepted-debt evidence.

### Preserve old Multi-Profile restore compatibility unconditionally

Rejected. Compatibility appetite is a pending PO product/data decision. The map
requires frozen-wire compatibility or an explicit, user-visible incompatibility
boundary; it does not preselect migration.

### Treat every `comingSoon` match as a commercial consumer

Rejected as a keyword false positive. Only reachable or specifically named
commercial surfaces belong in D4.

## Review Integrity

The first Antigravity run attempted to inspect the audit branch and was discarded
as boundary-tainted. A fresh whitelist run against the fixed primary checkout was
retained. Claude and Grok remained read-only and fixed-base. No raw agent transcript
or private memory is stored as project truth.

## Recovery

- candidate: `phases/02f-product-intent-impact-map-candidate.md`
- review brief: `phases/02f-product-impact-review-brief.md`
- review result: this file
- upstream workshop: `phases/02e-po-product-workshop-candidate.md`
- structural findings: `phases/02d-product-constitution-results.md`
- next dependency: Gate A authority integration after PO ratification; this
  result does not select Gate B/C answers or authorize a merge
