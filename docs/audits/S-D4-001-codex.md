---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# S-D4-001 Codex 独立修复提案

## 结论

`ServiceContainer` 当前只覆盖 5 个服务，但 Core/Feature 实际存在多条容器外依赖路径。修复应把 Core 层可替换、跨 Feature 使用、或带状态生命周期的服务统一纳入 `ServiceContainer`，同时为不适合纳入的静态 facade/非 Core 工具写明豁免。

当前证据：

- `ServiceContainer.swift:38-52` 只声明 `analytics / pdfExport / appConfig / privacyConsent / notification`。
- `LiveServiceContainer.swift:23-27` 与 `MockServiceContainer.swift:23-27` 只实现这 5 项。
- `CaptureViewModel.swift:82` 默认 `OCRService()`，`CaptureViewModel.swift:109/125` 直接 `CaptureDraftService.shared`。
- `CaptureResultViewModel.swift:155` 默认 `ContentTaggingService()`，`CaptureResultViewModel.swift:293/319/412` 直接 `CaptureDraftService.shared` / `AppActivityTracker.shared`。
- `LibraryViewModel.swift:115` 直接 `DeletionScheduler.shared`。
- `DashboardAnalyticsViewModel.swift:82` 和 `SmartPaperView.swift:34` 默认 `DefaultProEntitlementProvider()`。
- `architecture.md:244` 承诺 `Protocol-based DI + @Environment`，但 `architecture.md:119` 列出的多个 Core service 没有进入容器。

## 7 项设计决策

| 决策点 | Codex 方案 |
|---|---|
| 一刀切扩展 vs 分层组织 | 不引入二级容器，先扩展单一 `ServiceContainer`。当前服务数量约 13 个，仍在可读范围；二级容器会增加调用方访问深度，暂时不值得。用 `// MARK:` 分组保持可读。 |
| 全部走协议 vs 部分具体类型 | 采用“已存在 protocol 就用 protocol；纯值/稳定具体类型保留具体类型”。`OCRServiceProtocol / CaptureDraftServiceProtocol / ContentTaggingServiceProtocol / QuestionSplittingServiceProtocol / AnalyticsServiceProtocol / NotificationServiceProtocol / ProEntitlementProvider` 走协议；`PDFExportService / AppConfiguration / PrivacyConsentService / DeletionScheduler / AppActivityTracker / ReviewScheduler` 暂保具体类型。 |
| 当前直接 `.init()` / `.shared` 调用方处理 | 分两阶段。第一阶段一次性把最危险的状态型/可替换型调用点迁移：`CaptureDraftService.shared`、`DeletionScheduler.shared`、`DefaultProEntitlementProvider()`、`OCRService()`、`ContentTaggingService()`。第二阶段清理 `AppActivityTracker.shared` 与 `TelemetryGate` 静态访问。保留原 initializer 兼容测试，但标注 `TODO(S-D4-001): prefer ServiceContainer injection`。 |
| Mock 容器策略 | `MockServiceContainer` 提供全 mock / fake 可控实例。已有 mock 的用现有 mock；没有 mock 的稳定纯本地服务可用真实实现；有状态服务如 `DeletionScheduler` / `AppActivityTracker` 每个 mock container 创建新实例，避免测试串扰。 |
| Service 单例语义保证 | 容器使用 `let` 属性持有实例，保证同一容器生命周期内同一服务返回同一实例。避免 `lazy var`，因为当前 `ServiceContainer` 是 protocol property，`let` 更直接也能被测试验证。 |
| ADR 是否需要 | 需要 ADR 或 architecture decision 段。该重构改变全局依赖边界，影响 Feature 初始化方式、测试注入策略、未来新增 service 规则；属于架构契约，不只是局部 bug fix。 |
| 测试覆盖最小集 | Core `ServiceContainerTests` 验证 live/mock 初始化与单例缓存；Feature 测试至少覆盖一个迁移调用方，例如 `LibraryViewModel` 使用注入的 `DeletionScheduler`；编译期对称性由 `LiveServiceContainer: ServiceContainer` / `MockServiceContainer: ServiceContainer` 保证。 |

## 服务覆盖清单

### 纳入 `ServiceContainer`

| 属性 | 类型 | 来源 | 理由 |
|---|---|---|---|
| `analytics` | `AnalyticsServiceProtocol` | 已有 | 外部 SDK 可替换。 |
| `pdfExport` | `PDFExportService` | 已有 | 导出管线共享。 |
| `appConfig` | `AppConfiguration` | 已有 | 全局配置源。 |
| `privacyConsent` | `PrivacyConsentService` | 已有 | 隐私授权 facade。 |
| `notification` | `NotificationServiceProtocol` | 已有 | 系统通知可替换。 |
| `ocr` | `OCRServiceProtocol` | `OCRService()` 直接默认 | Capture/PDF/Scan 页面共用 OCR，测试需要 mock。 |
| `captureDraft` | `CaptureDraftServiceProtocol` | `CaptureDraftService.shared` | 跨 Dashboard/Capture 共享草稿状态，当前全局单例绕过 DI。 |
| `contentTagging` | `ContentTaggingServiceProtocol` | `ContentTaggingService()` | 端上 AI best-effort 服务，需要可禁用/mock。 |
| `questionSplitting` | `QuestionSplittingServiceProtocol` | Core service | 一图多题 AI 服务，未来 capture flow 应统一注入。 |
| `deletionScheduler` | `DeletionScheduler` | `DeletionScheduler.shared` | App 级状态服务，必须由容器持有生命周期。 |
| `proEntitlement` | `any ProEntitlementProvider` | `DefaultProEntitlementProvider()` | Pro 门控不能散落默认实现。 |
| `activityTracker` | `AppActivityTracker` | `AppActivityTracker.shared` | Profile 切换保护全局状态，容器应是唯一 owner。 |
| `reviewScheduler` | `ReviewScheduler` | `ReviewScheduler()` | SM-2 策略服务，ReviewViewModel 应注入以便策略替换/测试。 |

### 显式豁免

| 对象 | 决策 |
|---|---|
| `TelemetryGate` | 暂不作为独立 `ServiceContainer` 属性。它是静态 consent storage facade，当前已有 `PrivacyConsentService` 与 `AppConfiguration` 包装。修复应迁移 Feature/Infrastructure 直接 `TelemetryGate.*` 到 `privacyConsent` / `appConfig`，并在 ADR 中记录剩余静态 facade。 |
| `ZIPArchiver` | 不放入 Core `ServiceContainer`。当前 `ZIPArchiver` 位于 Data/backup 语义，不在 Core DI 边界；若要注入，应进入 `BackupService` 或 Data-layer factory，而不是 Core ServiceContainer。 |
| `ImageStorage` | 不放入全局 `ServiceContainer`。它是 Profile-scoped，并已由 `ProfileManager.activeImageStorage` 管理；放入全局容器会破坏 Multi-Profile 隔离。 |
| `OnboardingManager.shared` / `DependencyContainer.shared` | App composition root / UI 状态，不属于 Core service DI 本轮范围。 |

## 修复 patch

### `Packages/SnapDrillCore/Sources/SnapDrillCore/DI/ServiceContainer.swift`

```diff
 public protocol ServiceContainer: Sendable {
+    // MARK: Analytics / configuration
+
     /// 分析服务（协议类型，生产环境为 Firebase 实现，测试为 Mock）
     var analytics: AnalyticsServiceProtocol { get }
@@
     /// 通知服务（协议类型，生产环境为 UNUserNotificationCenter 实现，测试为 Mock）
     var notification: NotificationServiceProtocol { get }
+
+    // MARK: Capture / AI
+
+    /// OCR 识别服务（生产为 Vision OCR，测试可替换）
+    var ocr: OCRServiceProtocol { get }
+
+    /// 采集草稿服务（跨 Dashboard / Capture 共享）
+    var captureDraft: CaptureDraftServiceProtocol { get }
+
+    /// 端上 AI 标注服务
+    var contentTagging: ContentTaggingServiceProtocol { get }
+
+    /// 一图多题拆分服务
+    var questionSplitting: QuestionSplittingServiceProtocol { get }
+
+    // MARK: Review / Library / entitlement
+
+    /// Soft Delete 撤销窗口调度器（App 生命周期状态）
+    var deletionScheduler: DeletionScheduler { get }
+
+    /// Pro 权益判断
+    var proEntitlement: any ProEntitlementProvider { get }
+
+    /// Profile 切换保护活动追踪器
+    var activityTracker: AppActivityTracker { get }
+
+    /// SM-2 复习调度策略
+    var reviewScheduler: ReviewScheduler { get }
 }
```

### `Packages/SnapDrillCore/Sources/SnapDrillCore/DI/LiveServiceContainer.swift`

```diff
 public final class LiveServiceContainer: ServiceContainer {
@@
     public let privacyConsent: PrivacyConsentService
     public let notification: NotificationServiceProtocol
+    public let ocr: OCRServiceProtocol
+    public let captureDraft: CaptureDraftServiceProtocol
+    public let contentTagging: ContentTaggingServiceProtocol
+    public let questionSplitting: QuestionSplittingServiceProtocol
+    public let deletionScheduler: DeletionScheduler
+    public let proEntitlement: any ProEntitlementProvider
+    public let activityTracker: AppActivityTracker
+    public let reviewScheduler: ReviewScheduler
@@
     public init(
         analytics: AnalyticsServiceProtocol? = nil,
-        notification: NotificationServiceProtocol? = nil
+        notification: NotificationServiceProtocol? = nil,
+        ocr: OCRServiceProtocol? = nil,
+        captureDraft: CaptureDraftServiceProtocol? = nil,
+        contentTagging: ContentTaggingServiceProtocol? = nil,
+        questionSplitting: QuestionSplittingServiceProtocol? = nil,
+        deletionScheduler: DeletionScheduler? = nil,
+        proEntitlement: (any ProEntitlementProvider)? = nil,
+        activityTracker: AppActivityTracker? = nil,
+        reviewScheduler: ReviewScheduler? = nil
     ) {
         self.appConfig = AppConfiguration()
         self.pdfExport = PDFExportService()
         self.privacyConsent = PrivacyConsentService()
         self.analytics = analytics ?? AnalyticsServiceMock()
         self.notification = notification ?? LiveNotificationService()
+        self.ocr = ocr ?? OCRService()
+        self.captureDraft = captureDraft ?? CaptureDraftService.shared
+        self.contentTagging = contentTagging ?? ContentTaggingService()
+        self.questionSplitting = questionSplitting ?? QuestionSplittingService()
+        self.deletionScheduler = deletionScheduler ?? DeletionScheduler()
+        self.proEntitlement = proEntitlement ?? DefaultProEntitlementProvider()
+        self.activityTracker = activityTracker ?? AppActivityTracker()
+        self.reviewScheduler = reviewScheduler ?? ReviewScheduler()
     }
 }
```

说明：`CaptureDraftService.shared` 可作为第一阶段兼容默认值；长期建议给 `CaptureDraftService` 增加 public factory / storage injection 后去掉 singleton。

### `Packages/SnapDrillCore/Sources/SnapDrillCore/DI/MockServiceContainer.swift`

```diff
 public final class MockServiceContainer: ServiceContainer {
@@
     public let privacyConsent: PrivacyConsentService
     public let notification: NotificationServiceProtocol
+    public let ocr: OCRServiceProtocol
+    public let captureDraft: CaptureDraftServiceProtocol
+    public let contentTagging: ContentTaggingServiceProtocol
+    public let questionSplitting: QuestionSplittingServiceProtocol
+    public let deletionScheduler: DeletionScheduler
+    public let proEntitlement: any ProEntitlementProvider
+    public let activityTracker: AppActivityTracker
+    public let reviewScheduler: ReviewScheduler
@@
-    public init() {
+    public init(
+        analytics: AnalyticsServiceProtocol = AnalyticsServiceMock(),
+        notification: NotificationServiceProtocol = NotificationServiceMock(),
+        ocr: OCRServiceProtocol = OCRServiceMock(),
+        captureDraft: CaptureDraftServiceProtocol = CaptureDraftServiceMock(),
+        contentTagging: ContentTaggingServiceProtocol = ContentTaggingServiceMock(),
+        questionSplitting: QuestionSplittingServiceProtocol = QuestionSplittingServiceMock(),
+        deletionScheduler: DeletionScheduler = DeletionScheduler(),
+        proEntitlement: any ProEntitlementProvider = ProEntitlementProviderMock(isProUser: false),
+        activityTracker: AppActivityTracker = AppActivityTracker(),
+        reviewScheduler: ReviewScheduler = ReviewScheduler()
+    ) {
-        self.analytics = AnalyticsServiceMock()
+        self.analytics = analytics
         self.pdfExport = PDFExportService()
         self.appConfig = AppConfiguration()
         self.privacyConsent = PrivacyConsentService()
-        self.notification = NotificationServiceMock()
+        self.notification = notification
+        self.ocr = ocr
+        self.captureDraft = captureDraft
+        self.contentTagging = contentTagging
+        self.questionSplitting = questionSplitting
+        self.deletionScheduler = deletionScheduler
+        self.proEntitlement = proEntitlement
+        self.activityTracker = activityTracker
+        self.reviewScheduler = reviewScheduler
     }
 }
+
+public struct ProEntitlementProviderMock: ProEntitlementProvider {
+    public let isProUser: Bool
+    public init(isProUser: Bool) {
+        self.isProUser = isProUser
+    }
+}
```

### 必要 mock 补丁

`ContentTaggingServiceMock` 与 `QuestionSplittingServiceMock` 已存在；`OCRServiceProtocol` 目前只有 Feature test local mock，`CaptureDraftServiceProtocol` 没有通用 mock。建议补两个 mock：

```swift
public final class OCRServiceMock: OCRServiceProtocol {
    public var recognizedText = ""
    public var recognizedRegions: [RecognizedTextRegion] = []
    public var error: Error?

    public init() {}

    public func recognizeText(from image: UIImage) async throws -> String {
        if let error { throw error }
        return recognizedText
    }

    public func recognizeTextWithRegions(from image: UIImage) async throws -> [RecognizedTextRegion] {
        if let error { throw error }
        return recognizedRegions
    }
}
```

```swift
public final class CaptureDraftServiceMock: CaptureDraftServiceProtocol {
    public var hasDraft = false
    public var draftToLoad: CaptureDraftService.Draft?
    public private(set) var saveCalls: [(content: String, subject: String?)] = []
    public private(set) var clearCallCount = 0

    public init() {}

    public func saveDraft(image: UIImage? = nil, content: String, subject: String? = nil) async {
        saveCalls.append((content, subject))
        hasDraft = true
    }

    public func loadDraft() -> CaptureDraftService.Draft? {
        draftToLoad
    }

    public func clearDraft() {
        clearCallCount += 1
        hasDraft = false
        draftToLoad = nil
    }
}
```

如果不想让 production target 暴露 test mock，则把 `MockServiceContainer` 改成必须显式传入 `ocr` / `captureDraft`，或把 mocks 放进 test support target。默认继续使用真实 `OCRService()` / `CaptureDraftService.shared` 是次优方案，因为它会让 Preview/测试容器继续依赖系统 API 和全局状态。

## 3 个代表性调用方迁移

### 1. `CaptureView` / `CaptureViewModel`：OCR + 草稿服务

```diff
 // CaptureView.swift
@@
     @Environment(\.repositories) private var repositories
     @Environment(\.profileManager) private var profileManager
     @Environment(\.analyticsService) private var analyticsService
+    @Environment(\.services) private var services
@@
-    @State private var viewModel = CaptureViewModel()
+    @State private var viewModel: CaptureViewModel?
@@
-                                    let granted = await viewModel.checkCameraPermission()
+                                    let granted = await viewModel?.checkCameraPermission() ?? false
@@
+            .task {
+                if viewModel == nil {
+                    viewModel = CaptureViewModel(
+                        ocrService: services.ocr,
+                        draftService: services.captureDraft,
+                        activityTracker: services.activityTracker
+                    )
+                }
+            }
```

```diff
 // CaptureViewModel.swift
@@
     public let ocrService: OCRServiceProtocol
+    private let draftService: CaptureDraftServiceProtocol
+    private let activityTracker: AppActivityTracker
@@
-    public init(ocrService: OCRServiceProtocol = OCRService()) {
+    public init(
+        ocrService: OCRServiceProtocol,
+        draftService: CaptureDraftServiceProtocol,
+        activityTracker: AppActivityTracker
+    ) {
         self.ocrService = ocrService
+        self.draftService = draftService
+        self.activityTracker = activityTracker
     }
@@
-        if let draft = CaptureDraftService.shared.loadDraft() {
+        if let draft = draftService.loadDraft() {
@@
-        CaptureDraftService.shared.clearDraft()
+        draftService.clearDraft()
@@
-            AppActivityTracker.shared.begin(.capturing)
-            defer { AppActivityTracker.shared.end(.capturing) }
+            activityTracker.begin(.capturing)
+            defer { activityTracker.end(.capturing) }
```

### 2. `CaptureResultViewModel`：AI 标注 + 草稿 + activity tracker

```diff
 // CaptureView.swift navigationDestination
@@
                         analyticsService: analyticsService,
                         imageStorage: profileManager.activeImageStorage,
+                        contentTaggingService: services.contentTagging,
+                        draftService: services.captureDraft,
+                        activityTracker: services.activityTracker,
                         router: router
```

```diff
 // CaptureResultViewModel.swift
@@
-        contentTaggingService: ContentTaggingServiceProtocol = ContentTaggingService(),
+        contentTaggingService: ContentTaggingServiceProtocol,
+        draftService: CaptureDraftServiceProtocol,
+        activityTracker: AppActivityTracker,
@@
         self.contentTaggingService = contentTaggingService
+        self.draftService = draftService
+        self.activityTracker = activityTracker
@@
-            await CaptureDraftService.shared.saveDraft(image: image, content: content, subject: selectedSubject)
+            await draftService.saveDraft(image: image, content: content, subject: selectedSubject)
@@
-        AppActivityTracker.shared.begin(.capturing)
-        defer { AppActivityTracker.shared.end(.capturing) }
+        activityTracker.begin(.capturing)
+        defer { activityTracker.end(.capturing) }
@@
-        CaptureDraftService.shared.clearDraft()
+        draftService.clearDraft()
```

### 3. `LibraryViewModel` / Pro gates：DeletionScheduler + entitlement

```diff
 // LibraryView.swift or construction site
-LibraryViewModel(repositories: repositories)
+LibraryViewModel(
+    repositories: repositories,
+    deletionScheduler: services.deletionScheduler
+)
```

```diff
 // LibraryViewModel.swift
@@
-    private let deletionScheduler = DeletionScheduler.shared
+    private let deletionScheduler: DeletionScheduler
@@
-    public init(repositories: RepositoryContainer) {
+    public init(repositories: RepositoryContainer, deletionScheduler: DeletionScheduler) {
         self.repositories = repositories
+        self.deletionScheduler = deletionScheduler
     }
```

```diff
 // DashboardAnalyticsViewModel.swift
@@
-        proEntitlementProvider: any ProEntitlementProvider = DefaultProEntitlementProvider()
+        proEntitlementProvider: any ProEntitlementProvider
```

```diff
 // SmartPaperView.swift
@@
     @Environment(\.repositories) private var repositories
+    @Environment(\.services) private var services
@@
-    init(proEntitlementProvider: any ProEntitlementProvider = DefaultProEntitlementProvider()) {
-        self.proEntitlementProvider = proEntitlementProvider
-    }
+    init() {}
@@
-    private var isProUser: Bool { proEntitlementProvider.isProUser }
+    private var isProUser: Bool { services.proEntitlement.isProUser }
```

## 测试用例

### `ServiceContainerTests`

```swift
@Suite("ServiceContainer DI 完整性")
struct ServiceContainerDITests {
    @Test("LiveServiceContainer 初始化所有 Core services")
    func liveContainerProvidesAllServices() {
        let container = LiveServiceContainer()

        #expect(container.analytics is AnalyticsServiceMock)
        #expect(container.pdfExport === container.pdfExport)
        #expect(container.notification is LiveNotificationService)
        #expect(container.ocr is OCRService)
        #expect(container.captureDraft is CaptureDraftService)
        #expect(container.contentTagging is ContentTaggingService)
        #expect(container.questionSplitting is QuestionSplittingService)
        #expect(container.deletionScheduler === container.deletionScheduler)
        #expect(container.activityTracker === container.activityTracker)
        #expect(container.proEntitlement.isProUser == false)
    }

    @Test("MockServiceContainer 与 LiveServiceContainer 接口对称")
    func mockContainerConformsToSameProtocol() {
        let live: any ServiceContainer = LiveServiceContainer()
        let mock: any ServiceContainer = MockServiceContainer()

        _ = live.captureDraft
        _ = mock.captureDraft
        _ = live.deletionScheduler
        _ = mock.deletionScheduler
        _ = live.proEntitlement
        _ = mock.proEntitlement
    }

    @Test("同一容器内服务实例保持缓存语义")
    func sameContainerReturnsSameInstances() {
        let container = MockServiceContainer()

        #expect(container.deletionScheduler === container.deletionScheduler)
        #expect(container.activityTracker === container.activityTracker)
        #expect(container.notification as AnyObject === container.notification as AnyObject)
    }
}
```

说明：`OCRService` 和 `ContentTaggingService` 是 actor，`is` 断言可能需要按 Swift actor existential 编译结果调整；如 `#expect(container.ocr is OCRService)` 不可编译，可降级为执行 mock 注入断言。

### 调用方迁移测试

`LibraryViewModel` 注入 `DeletionScheduler` 后：

```swift
@Test("LibraryViewModel 使用注入的 DeletionScheduler")
func libraryUsesInjectedDeletionScheduler() async throws {
    let scheduler = DeletionScheduler()
    let vm = LibraryViewModel(repositories: repos, deletionScheduler: scheduler)

    try await seedItems(count: 1)
    await vm.loadDataAsync()
    let id = try #require(vm.filteredItems.first?.id)

    vm.softDeleteItems(ids: [id])

    #expect(scheduler.pendingDeletionIDs == [id])
    #expect(scheduler.showUndoToast == true)
}
```

`CaptureViewModel` 注入草稿服务后：

```swift
@Test("CaptureViewModel 从注入 draftService 恢复草稿")
func captureViewModelUsesInjectedDraftService() {
    let draft = CaptureDraftService.Draft(image: nil, content: "draft", date: Date(), subject: "Math")
    let draftService = CaptureDraftServiceMock()
    draftService.draftToLoad = draft
    let vm = CaptureViewModel(
        ocrService: MockOCRService(),
        draftService: draftService,
        activityTracker: AppActivityTracker()
    )

    vm.checkDraftOnAppear()

    #expect(vm.pendingDraft?.content == "draft")
    #expect(vm.showDraftAlert == true)
}
```

`SmartPaperView` / `DashboardAnalyticsViewModel` 注入 Pro provider 后：

```swift
@Test("DashboardAnalyticsViewModel 使用注入的 ProEntitlementProvider")
func dashboardAnalyticsUsesInjectedProProvider() {
    let vm = DashboardAnalyticsViewModel(
        repositories: repos,
        proEntitlementProvider: ProEntitlementProviderMock(isProUser: true)
    )

    #expect(vm.isProUser == true)
}
```

## Architecture 文档同步 patch

### `docs/tech/architecture.md`

```diff
@@
 DependencyContainer.shared（App 启动时初始化）
 ├── services: ServiceContainer（协议）→ LiveServiceContainer（实现）
+│   ├── analytics / notification / privacyConsent / appConfig
+│   ├── captureDraft / ocr / contentTagging / questionSplitting
+│   ├── pdfExport / deletionScheduler / proEntitlement
+│   └── activityTracker / reviewScheduler
@@
-| `\.services` | `ServiceContainer` | PDF 导出、通知、隐私授权、Analytics |
+| `\.services` | `ServiceContainer` | Core service 注入：Analytics、PDF、通知、隐私、OCR、草稿、AI 标注、题目拆分、删除调度、Pro 权益、活动追踪、复习调度 |
@@
-| `Service/` | Protocol 定义 + 实现（OCRServiceProtocol、PDFExportService、NotificationServiceProtocol、AnalyticsServiceProtocol、CaptureDraftService、PrivacyConsentService、DeletionScheduler、ContentTaggingService、QuestionSplittingService、ProEntitlementProvider、TelemetryGate）|
+| `Service/` | Protocol 定义 + 实现（OCRServiceProtocol、PDFExportService、NotificationServiceProtocol、AnalyticsServiceProtocol、CaptureDraftService、PrivacyConsentService、DeletionScheduler、ContentTaggingService、QuestionSplittingService、ProEntitlementProvider）。除 Profile-scoped `ImageStorage` 与静态 consent facade 外，Core service 必须经 `ServiceContainer` 注入 |
@@
-| Protocol-based DI + @Environment | 替换实现只需改 DependencyContainer，Feature 层不感知 |
+| Protocol-based DI + @Environment | Core service 替换实现只需改 DependencyContainer / ServiceContainer；Feature 层禁止直接 `.shared` 或默认 concrete init 获取服务 |
```

建议同步补一段“新增 Core service 规则”：

```markdown
**新增 Core service 规则**：
1. 若服务跨 Feature 使用、持有状态、依赖系统 API/AI/外部 SDK、或测试需要替换，必须进入 `ServiceContainer`。
2. Profile-scoped 服务走 `ProfileManager` / `RepositoryContainer`，不得放入全局 `ServiceContainer`。
3. 静态 facade 必须有 ADR 豁免，并提供可注入 wrapper；不得直接从 Feature 层调用。
```

## 验证命令

应用 patch 后需要跑：

```bash
swiftlint --strict
xcodebuild build-for-testing \
  -scheme AllTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -testPlan AllTests
```

本任务要求独立修复提案，且禁止直接修改 `Packages/SnapDrillCore/.../DI/`，所以我未 apply patch，也未执行修复后 build-for-testing。

## 已知盲区

1. 本方案第一阶段仍保留 `CaptureDraftService.shared` 作为 `LiveServiceContainer` 默认值。它把访问路径收束到容器，但没有彻底移除 singleton。彻底修复需要给 `CaptureDraftService` 增加可注入 storage/defaults/fileManager 初始化器。
2. `TelemetryGate` 没有直接进入 `ServiceContainer`。理由是当前已有 `PrivacyConsentService` / `AppConfiguration` wrapper；本轮应先禁止 Feature 层直接访问 `TelemetryGate`，再用 ADR 决定是否拆成协议。
3. `ZIPArchiver` 不在本轮 Core DI 范围。它属于 Data backup/restore 管线，若要 DI，应在 `BackupService` 或 Data-layer composition root 中做，不应塞进 Core service container。
4. `ImageStorage` 明确排除，因为它是 Profile-scoped。未来如果需要注入，也应经 `ProfileManager.activeImageStorage` 或 `RepositoryContainer`，不是全局 ServiceContainer。
5. 渐进迁移中间态风险：容器属性已加但部分调用方仍可能继续用 `.shared` / default concrete init。需要用 `rg "\\.shared|DefaultProEntitlementProvider\\(|ContentTaggingService\\(|OCRService\\(" Packages/SnapDrillFeatures` 作为迁移门禁，并在后续 PR 中逐步降到 0。
6. `AppActivityTracker` 目前被 `ProfileManager` 直接用。若要完全迁移，需要让 `ProfileManager` 构造器接收 tracker 或让 `DependencyContainer.createProfileManager()` 注入，这会触及 Data/App composition root；本提案把它列入容器，但建议作为单独小 PR 应用，避免和 Feature 初始化迁移混在一个 diff。
7. 未来新增 Service 的扩展成本：新增一个容器属性、Live 默认实现、Mock 默认实现、ServiceContainerTests 断言、architecture 表格一行。这个成本是有意的，用来阻止“随手 `.shared` / `.init()`”重新扩散。
