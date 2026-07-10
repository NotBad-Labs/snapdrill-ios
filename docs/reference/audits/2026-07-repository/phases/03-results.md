# Phase 03 Results: Architecture and Runtime Boundaries

## Outcome

Phase 03 在固定 `develop@d62fead8` 上冻结 4 个 SPM package、8 个 production package target、4 个 package test target、4 个 native Xcode target，并审查 compile graph、composition root、DI 实例流、Profile 生命周期、静态 facade、coordinator 与历史 Domain/UseCase 简化。

当前 package 图没有 cycle、反向引用或 Core 第三方依赖，Share Extension 也保持进程/模块隔离。主要风险不在“缺少更多 Clean Architecture 层”，而在现有显式边界没有做透：SwiftUI Environment fallback 的 in-memory helper 会在正常 App 启动清除真实 Profile 偏好；App target 依赖声明依靠传递暴露；ServiceContainer 与 `.shared`/concrete fallback 并存；删除后台提交契约没有接入 App 生命周期。

本阶段只记录事实，不修改产品代码、Xcode target、Package manifest、依赖锁文件或权威架构文档。

## Frozen Inventory

| Surface | Count / result | Classification |
|---|---:|---|
| SPM packages | 4 | keep |
| production package targets | 8 | keep；5 个 Feature + Core/Data/UI |
| package test targets | 4 | keep |
| native Xcode targets | 4 | keep；App/UI tests/Share/Share tests |
| production Swift files | 185 | inventoried by owner target |
| dependency cycles / reverse edges | 0 / 0 | keep |
| Core third-party packages | 0 | invariant holds |
| third-party owners | Mantis→UI；ZIPFoundation→Data；SnapshotTesting→Features tests | keep |
| tracked `Package.resolved` files | 4 | repair ownership/synchronization |

实际 package DAG 为：

```text
SnapDrillFeatureCapture ─┐
SnapDrillFeatureLibrary ─┼──> SnapDrillUI ──> SnapDrillCore
Review/Dashboard/Settings├──> SnapDrillData ─> SnapDrillCore
                         └──> SnapDrillCore

Review/Dashboard/Settings ──> SnapDrillFeatureLibrary
SnapDrillShare: no SnapDrill package dependency
```

App composition root 直接 import Core/Data/UI 与 5 个 Feature module；Xcode target 只声明 5 个 Feature products。当前构建能通过不等于 direct dependency contract 已声明。

## Runtime Flow

```text
DependencyContainer.shared
├── services: LiveServiceContainer
│   ├── analytics: NoOpAnalyticsService (production explicitly injects)
│   ├── activityTracker: AppActivityTracker.shared
│   ├── deletionScheduler: container-owned instance
│   └── six slots with no production services.* reader
├── router: AppRouter
└── createProfileManager()
    └── ProfileManager.create() -> DataExecutor -> RepositoryContainer

ProfileManager construction
├── create(inMemory: false) -> disk bootstrap -> load per-profile preferences
├── create(inMemory: true)  -> direct in-memory init -> clear .standard
└── Environment fallback   -> direct in-memory init -> clear .standard during App render
```

Production Profile switching currently works only because both `LiveServiceContainer.activityTracker` and hard-coded `ProfileManager.switchProfile` resolve to `AppActivityTracker.shared`. An injected alternate tracker or UI-test `MockServiceContainer` creates a split graph.

## Verified Findings

### RA-03-001 — P1 — Profile environment fallback clears live per-profile preferences during App launch

- `ProfileManager+Environment.swift:27-29` builds `ProfileManager(inMemory: true)` as `EnvironmentKey.defaultValue`; `ProfileManager.swift:88-108` routes that direct initializer through `clearPerProfileValues(in: .standard)`.
- `ProfileManager+Preferences.swift:4-10` removes every per-profile and dynamic visibility key. The disk manager loads `preferences.json` at `ProfileManager.swift:147-148`, then `AppRootView.swift:39-44` applies the real manager to the SwiftUI environment.
- C1 first added a sentinel unit test without changing production code: the old direct initializer removed the sentinel and failed deterministically.
- The production path was then reproduced against the App's actual Simulator data container. With `CFFIXED_USER_HOME` set to the path returned by `simctl get_app_container`, the old binary changed a unique per-profile sentinel from `1` to missing after an eight-second normal launch. The repaired binary preserved `1 -> 1` on normal launch while `--uitesting` intentionally produced `1 -> missing`.
- Earlier `simctl spawn defaults` checks without App-container `CFFIXED_USER_HOME` wrote the Simulator user domain and were discarded. A generic macOS EnvironmentKey probe and an isolated iOS hosting test are not used as production proof.
- Impact: normal cold launch can erase active Profile preferences after they are loaded; a later Profile switch may persist the emptied state. Tests/previews also suffer process-global preference interference.
- Smallest repair: keep reset semantics only at the explicit `create(inMemory: true)` UI-test factory; make direct/environment fallback initialization side-effect free and test both contracts.

### RA-03-002 — P2 — App target relies on undeclared transitive package products

- `project.pbxproj:782-788` lists only the five Feature products for the `SnapDrill` target.
- `SnapDrillApp.swift:12-19`, `AppRootView.swift:15-21`, `AppRouter.swift:14-19` and `DependencyContainer.swift:12-13` directly import Core/Data/UI as well as Features.
- Current build succeeds because those modules are present through Feature products, but the App target's declared products do not match its direct imports.
- Impact: package boundary changes can break the app at a distance, and Xcode does not document/enforce the composition root's real dependency contract.
- Smallest repair: add Core/Data/UI as explicit App target package products and retain the same runtime graph.

### RA-03-003 — P2 — Profile switch protection has dual activity-tracker ownership

- `ProfileManager.swift:223-225` always checks `AppActivityTracker.shared`.
- `LiveServiceContainer.swift:65-70` documents that production correctness depends on defaulting its injectable property to that same singleton; `ServiceContainerTests.swift:60-68` guards only this equality.
- Capture/Settings/Privacy/Library edit ViewModels still expose `.shared` fallbacks, while export/print paths use `services.activityTracker`.
- `MockServiceContainer.swift:65` creates a fresh tracker, but Capture's zero-argument construction uses `.shared`; UI-test service identity is therefore split even though the production default happens to converge.
- Impact: injecting a non-shared tracker or finishing only one side of S-D4-001 can silently disable Profile-switch blocking during capture/export/backup.
- Smallest repair: inject one tracker into `ProfileManager` and every production ViewModel construction site, with a cross-layer test that begins on the container tracker and observes `switchProfile` blocking.

### RA-03-004 — P2 — ServiceContainer migration is half-complete and gives false substitution coverage

- `ServiceContainer.swift:15-34` and `architecture.md:46-52` claim Feature services come from one 14-property container.
- Direct production readers exist for analytics, pdfExport, appConfig, notification, deletionScheduler, proEntitlement, activityTracker and metricService.
- No production `services.*` reader exists for privacyConsent, ocr, captureDraft, contentTagging, questionSplitting or reviewScheduler.
- `CaptureView.swift:28-33,214-222` constructs Capture dependencies from concrete/shared defaults; `CaptureViewModel.swift:89-96` and `CaptureResultViewModel.swift:112-133` confirm the alternate instance graph. UI-test mocks for those slots are therefore not exercising Capture.
- Impact: tests can report a complete mock container while production Features bypass it; future partial migration reintroduces split state and system-service side effects.
- Classification: finish injection for OCR/captureDraft/contentTagging; retire the pass-through privacyConsent slot; keep QuestionSplitting implementation deferred behind #626 but remove/defer its unused container slot; keep `ReviewScheduler` engine but retire the speculative container slot unless a real alternate strategy lands.

### RA-03-005 — P2 — Backgrounding does not honor the soft-delete commit contract

- `feat-library.md:42` says `commitImmediately()` persists a pending delete when the App enters background.
- `SnapDrillApp.swift:117-126` handles background only by ending analytics; the only production `commitImmediately()` call is internal when a new delete replaces an older batch (`DeletionScheduler.swift:55-59`).
- Tests create pending scheduler IDs but do not directly exercise background commit or `commitImmediately()`.
- Impact: if the App is suspended/terminated during the five-second undo window, the user's delete can remain uncommitted and the item can reappear on the next launch.
- Smallest repair: connect deletion settlement to scene/background handling with an execution-completion oracle, not merely a fire-and-forget call assertion.

### RA-03-006 — P2 — Capture save rollback/orphan cleanup is not independently testable

- `CaptureSaveCoordinator.swift:8-10,42-84` owns validate → image writes → model insert/save → rollback/orphan cleanup and says extraction makes the transaction independently testable.
- The coordinator depends on concrete `ImageStorage` and `RepositoryContainer`; no test references the coordinator or can fail the second image write / context save deterministically.
- `CaptureResultViewModelTests.swift:80-115,204-216` covers empty input and successful text/image saves, but its failure case is only pre-write validation.
- Impact: the highest-risk failure branches can regress while all current Capture tests stay green, leaving orphan files or dirty context after partial persistence.
- Smallest repair: add a narrow injectable image persistence seam or equivalent deterministic failure harness, then assert first-image cleanup and repository rollback after a mid-transaction failure.

### RA-03-007 — P3 — Architecture documentation overstates both graph shape and DI completion

- `AGENTS.md:80` describes `Features → UI → Data → Core`; manifests show sibling edges Features→UI/Data/Core, with UI→Core and Data→Core.
- `AGENTS.md:88-92` and `architecture.md:46-52,245-251` state all Core services are injected and the background deletion path exists; RA-03-004/005 disprove those current-state claims.
- Smaller stale comments point to the removed `ShareHelpers.swift` and underdescribe Settings→Library consumers, reinforcing that comments are not synchronized with the live graph.
- Impact: an agent following the tracked architecture can add the wrong edge or assume a mock/lifecycle guard exists.
- Smallest repair: generate/maintain one factual DAG and separate target state from current migration state; do not rewrite package boundaries from prose alone.

### RA-03-008 — P3 — SmartPaper docs name an implementation that the Pro path does not use

- `feat-smartpaper.md:43-49` and `architecture.md:204-208` say selection reuses `ReviewScheduler + SM2State`.
- `SmartPaperViewModel.swift:168-173` delegates to `ArchiveRepository.fetchSmartSelection`; `ArchiveRepository.swift:156-193` sorts raw `nextReviewAt` and `repetitions` fields and never calls `ReviewScheduler` or constructs `SM2State`.
- The data is SM-2-derived, so the product intent is not disproved; the current How section is simply more specific than the implementation.
- Impact: future Pro work may assume scheduler strategy injection/weighting already exists and skip the actual repository algorithm review.
- Smallest repair: describe the current raw-field ordering, and keep the planned weakness/recency strategy explicitly behind #479.

### RA-03-009 — P3 — Four tracked resolution files pin different dependency graphs

- Package-local `SnapDrillUI/Package.resolved:5-10` and `SnapDrillFeatures/Package.resolved:5-19,32-46` pin Mantis 2.31.1 and older transitive test packages.
- workspace `Package.resolved:5-19,32-46` pins Mantis 2.31.2, swift-custom-dump 1.6.0, swift-syntax 603.0.2 and xctest-dynamic-overlay 1.10.0.
- `SnapDrillData/Package.resolved` matches ZIPFoundation 0.9.20; the disagreement is not universal.
- Impact: opening/resolving a package independently can test a different graph from the canonical Xcode workspace, producing non-reproducible dependency behavior and lockfile churn.
- Smallest repair: declare the workspace lock as canonical or add a checked synchronization rule; do not bulk-delete package locks without verifying package-local workflows.

### RA-03-010 — P3 — Bare LiveServiceContainer defaults analytics to a mock

- `LiveServiceContainer.swift:40-57` calls itself the production container but uses `AnalyticsServiceMock()` when `analytics` is omitted.
- `DependencyContainer.swift:48-56` explicitly passes `NoOpAnalyticsService`, so the shipping composition root is currently safe.
- Tests repeatedly construct bare `LiveServiceContainer()`, which normalizes the unsafe default instead of proving a production-safe factory.
- Impact: a new production-like host can silently collect only in-memory test events and diverge from the zero-backend production contract.
- Smallest repair: require analytics explicitly or make NoOp the live default; keep Mock only in `MockServiceContainer`.

## Abstraction Classification

| Object | Decision | Evidence / boundary |
|---|---|---|
| 4-package topology | keep | no cycles/reverse edges; Core invariant holds |
| `ServiceContainer` | repair | real composition seam, but six slots have no reader |
| OCR / ContentTagging protocols | keep + finish | real system implementation and mocks; wire through composition root |
| CaptureDraft protocol/service | keep + finish | cross-Feature state; remove dual container/shared ownership together |
| ActivityTracker | keep + repair | required Profile safety invariant; inject one identity |
| DeletionScheduler | keep + repair | real undo orchestration; connect lifecycle and add direct tests |
| ReviewScheduler engine | keep | pure tested business engine; container slot is speculative |
| QuestionSplitting service | defer | #626 owner exists; container slot has no current consumer |
| PrivacyConsentService | retire | pure TelemetryGate pass-through, no production caller; deletion still requires an authorized fix slice |
| CaptureSaveCoordinator | keep + repair tests | real transaction boundary, not a pass-through |
| SettingsBackupCoordinator | keep | multi-step profile backup/restore orchestration and tests |
| documented static-facade exemptions | keep | TelemetryGate/ZIPArchiver/ImageStorage/Onboarding/DependencyContainer still owned |
| removed Domain/UseCase package | keep deleted | no lost current oracle found; do not revive |

## Historical Rule Mapping

`240887cb` introduced the Domain/UseCase route, `37cb827e` removed UseCase indirection, and `aa5e1de8` removed the remaining Domain package/tests. C1 compared the deleted test assertions rather than using deleted line count:

- Review due/future selection → current `ArchiveRepositoryTests` + `ReviewViewModelTests`.
- empty content/image and image-only save → current `CaptureResultViewModelTests` + coordinator validation.
- SM-2 interval/ease/reset rules → current `ReviewSchedulerTests` and Review ViewModel persistence tests.
- save/delete/count → current Archive repository tests.
- taxonomy add/delete/reference/dedupe/rename → current dynamic-dimension `CategoryRepositoryTests`, which match the replacement data model rather than legacy string cascades.
- Dashboard notification refresh → current `DashboardViewModelTests`.

No concrete business rule requires restoring Domain or UseCase packages. The verified gap is the coordinator's mid-transaction failure oracle (RA-03-006), not missing architectural layers.

## Routed Candidates

1. Phase 04: recheck Antigravity's Profile preference JSON/Data, in-memory fallback image lifetime, restore image completeness and backup failure claims; they were outside architecture scope and are not findings yet.
2. Phase 05: implement/verify RA-03-006 failure injection alongside Capture persistence review.
3. Phase 06: align SmartPaper current algorithm/docs and verify soft-delete background behavior from the user journey.
4. Phase 09: ensure UI-test composition really substitutes system services; map package-local dependency resolution into canonical CI.
5. Phase 11: verify dependency lock ownership on a clean checkout before deleting or synchronizing files.

## Rejected Claims

- **“Current production Profile switching already ignores active export”**: rejected. The live default aliases `AppActivityTracker.shared`; risk is dual ownership and incomplete injection, not a current default-path failure.
- **“Restore Domain/UseCase for Clean Architecture”**: rejected. Deleted oracles have current equivalents and the old layers were mostly repository pass-throughs.
- **“Every one-implementation protocol is waste”**: rejected. OCR, notification, analytics, metric and AI services have real mocks/system boundaries.
- **“QuestionSplitting is dead code and should be deleted now”**: rejected. It has a tracked #626 owner and focused tests; only the unused container slot is premature.
- **“SettingsView violates the repository boundary”**: rejected. Its direct ModelContext access is inside DEBUG seeding code; other ModelContainer hits are previews.
- **“CaptureSaveCoordinator should be inlined”**: rejected. It owns a real transaction; the problem is failure-test controllability.
- **“Tracked package lockfiles can all be deleted because swift test is unsupported”**: rejected. Package-local Xcode workflows were not disproved; first define canonical ownership.
- **“SmartPaper is not SM-2 based”**: rejected. Current ordering uses SM-2-derived fields, but not the specific scheduler/state implementation claimed by docs.

## Agent Challenge Notes

- Claude Fable、Antigravity `Gemini 3.5 Flash (High)`、Grok 4.5 均完成 03a/03b/03c；Grok 03c 因只读工具不含 shell，明确把 Git history 标为未覆盖，历史由 C1 独立验证。
- 三方在 App direct dependencies、activity tracker 双所有权、ServiceContainer 半迁移上收敛；severity 仍由 C1 按 shipping path 降噪。外部 agent 把后两项报为 P1，C1 因生产默认当前收敛为同一实例而定为 P2。
- Agy/Grok 把若干 current-code hazard 绝对化为用户数据 bug；C1 对 RA-03-001 使用 App sandbox 的 container-domain sentinel 独立复现为生产 P1，其余数据候选仍路由 Phase 04。
- Grok 的自动 repo bundle 超过 50 MiB，但 local Read/Grep/Glob 正常；raw transcript、debug/auth log 和 brain artifact 不入仓。

## Validation

- Profile preference probe：旧 direct initializer 红测；旧 App-container normal launch `1 -> missing`；fixed normal/UI-test launch `1 -> 1` / `1 -> missing`。
- feature status / intent traceability `--check`：通过。
- docs generators：8 passed；docs health / Capture contract：通过，保留既有人工复核 warnings，无 error。
- script regression tests：25 passed。
- `swiftlint --strict`：245 files，0 violations。
- focused architecture tests：ServiceContainer/AppActivityTracker 15、Profile preferences 4、CaptureResult/Library 26，共 45 passed。
- `AllTests build-for-testing`：`TEST BUILD SUCCEEDED`。
- `git diff --check`：clean。

## Recovery

- briefs：`03a-dependency-graph-brief.md`、`03b-runtime-flow-brief.md`、`03c-abstraction-debt-brief.md`
- invocation contract：`../agent-invocation-protocol.md`
- ledger：`../findings.md`
- checkpoint：`../checkpoints/phase-03.md`
- next：Phase 04 Data safety，先冻结 SwiftData model/profile/backup/image contract 与 fixtures；RA-03-001 由独立 P1 修复分支处理，不在审计分支改产品代码
