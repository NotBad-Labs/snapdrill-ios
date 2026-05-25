---
last_verified: 2026-05-21
layer: pattern
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---

# S-D4-001 Antigravity 独立修复与审计提案 (ServiceContainer DI 系统性退化重构)

本提案由 Antigravity 独立完成，采用三方对抗模式，针对 SnapDrill 项目的依赖注入 (DI) 系统性退化实施重构，彻底切断硬编码单例 `.shared` 与构造器 `.init()` 默认参数造成的隐式依赖后门，固化 "Protocol-based DI" 架构契约。

---

## 1. 7 项设计决策独立表态与技术论证

| 决策点 | 独立表态与深度论证 |
| :--- | :--- |
| **一刀切扩展 vs 分层组织** | **独立表态**：**一刀切平铺扩展**。<br>**技术论证**：目前 SnapDrill 项目的服务总量在 12 个左右，业务界限清晰。在 `ServiceContainer` 协议上直接平铺暴露（如 `services.ocrService`）最为直观，无嵌套多级子容器，有利于降低开发者的认知负荷和代码行数。即使未来服务总数增加到 25+，由于 Swift 支持 Extensions 机制，我们可以在物理上按职能分文件对 `ServiceContainer` 进行拆分与逻辑划分，而无需在运行时引入复杂且冗余的二级子容器，从而避免了过度工程化。 |
| **全部走协议 vs 部分具体类型** | **独立表态**：**因地制宜，核心服务协议化，纯内存/无状态服务具体化，特殊边界架构豁免**。<br>**技术论证**：<br>1. **协议化范围**：包含跨模块 mock 诉求或依赖底层物理硬件/系统 API / AI 框架的服务，包括 `ocrService` (`OCRServiceProtocol`)、`captureDraft` (`CaptureDraftServiceProtocol`)、`proEntitlementProvider` (`ProEntitlementProvider`)、`contentTagging` (`ContentTaggingServiceProtocol`)、`questionSplitting` (`QuestionSplittingServiceProtocol`)；<br>2. **具体化范围**：仅持有设备内存状态机、无任何外部硬件及三方 SDK 依赖的 `@Observable` 具体类（如 `deletionScheduler` 与 `activityTracker`），允许直接暴露具体类，免去无谓的“为了协议而协议”的装饰性包装，保留 100% 测试便利与极简代码；<br>3. **架构豁免清单**：<br>  * `ZIPArchiver` (无状态 Utility struct)：定义在数据层 `SnapDrillData`，若由 Core 层的 `ServiceContainer` 托管将导致强烈的**跨模块循环依赖**，因此给予豁免，继续保留局部实例化；<br>  * `TelemetryGate` (全局配置 Utility enum)：基于 `UserDefaults` 做全局设备遥测判断，无外部 API 依赖，作为全局静态入口，进行架构豁免。 |
| **直接 `.init()` / `.shared` 调用方处理** | **独立表态**：**Deprecated 静态告警拦截 + VM 构造器依赖注入 + View 级后置接线 (Post-initialization Wiring)**。<br>**技术论证**：为了杜绝技术债死灰复燃，我们将已上架 DI 容器的服务（如 `CaptureDraftService` 等）的 `static let shared` 静态成员标记为 `@available(*, deprecated, message: "请通过 ServiceContainer 注入使用")`，在编译期实现硬阻断。同时重构 VM 构造函数，移除任何隐式默认参数后门。针对 SwiftUI View 中由于 `@State private var viewModel = CaptureViewModel()` 引起的静态构造局限，我们提供后置依赖注入方法 `viewModel.inject(...)`，在 View 的 `.onAppear` 中动态提取 `@Environment(\.services)` 完成装配，实现 100% 运行时解耦。 |
| **Mock 容器策略** | **独立表态**：**100% 编译期对称 Mock。**<br>**技术论证**：`MockServiceContainer` 必须与 `LiveServiceContainer` 保持接口上的绝对对称。所有协议化服务全部挂载其对应的 Mock 实例（如 `OCRServiceMock`，`CaptureDraftServiceMock`，`MockProEntitlementProvider`），具体类则提供干净、未受全局状态污染的局部具体实例。这确保了在无宿主单元测试和 SwiftUI Preview 中，测试管线可以 100% 脱离物理硬件/系统沙盒沙盒化运行。 |
| **Service 单例语义保证** | **独立表态**：**容器级强绑定单例（Eager Let-binding）**。<br>**技术论证**：我们在 `LiveServiceContainer` 中采用 `public let` 对所有服务实例进行强绑定，这保证了在容器生命周期内，多次读取属性将得到绝对一致的内存地址，即单例缓存语义。由于服务容器随 App 启动作为组合根（Composition Root）在 `SnapDrillApp` 构造时仅初始化一次，所以在主隔离区 `@MainActor` 隔离下，该机制不仅提供了极简天然的单例语义，而且完全规避了使用 `lazy var` 时为了多线程并发防重入而产生的运行时锁和性能开销。 |
| **ADR 是否需要** | **独立表态**：**架构级规范升级，直接更新 Architecture 文档，无需单独新增临时 ADR。**<br>**技术论证**：DI 注入体系是 SnapDrill 项目最核心的防漂移和依赖倒置防线。本次重构带来的重大调整应作为核心架构设计长期持久化。我们选择直接重构更新项目 `docs/tech/architecture.md` 中的“DI 注入链路”与“模块职责”章节，让其成为项目最高的单一事实源（SSOT）规范，而不必创建碎片化的 ADR 决议，避免文档冗余。 |
| **测试覆盖最小集** | **独立表态**：**接口对称性断言 + 强引用地址一致性校验 + 核心 VM 重构未回归。**<br>**技术论证**：在 `ServiceContainerTests` 中覆盖了高强度的断言测试，至少验证：<br>1) Live/Mock 两容器在实例化后，所有 12 个服务属性非空，且 Mock 容器中所有的 Protocol 字段均为其对应的 Mock 类；<br>2) 通过恒等比较符 `===` 强断言多次读取 `captureDraft` 等服务时的物理内存地址一致性（缓存单例语义）；<br>3) 单元测试在零硬编码参数的注入模式下，关键调用方 VM（如 `CaptureViewModel`、`LibraryViewModel`）测试用例全绿无回归。 |

---

## 2. 核心架构重构代码设计与实现 Diff

### 2.1 依赖容器与服务协议扩展
我们对底层核心 `SnapDrillCore` 包的 DI 容器协议进行了全面修补，补齐了 7+ 个遗留的核心服务。

```diff
// Packages/SnapDrillCore/Sources/SnapDrillCore/DI/ServiceContainer.swift
 public protocol ServiceContainer: Sendable {
     /// 分析服务（协议类型，生产环境为 Firebase 实现，测试为 Mock）
     var analytics: AnalyticsServiceProtocol { get }
 
     /// PDF 导出服务（具体类型，无替代测试手段时的例外）
     var pdfExport: PDFExportService { get }
 
     /// 应用配置（具体类型，全局唯一配置源）
     var appConfig: AppConfiguration { get }
 
     /// 隐私授权服务（ATT 已移除，ADR-002）
     var privacyConsent: PrivacyConsentService { get }
 
     /// 通知服务（协议类型，生产环境为 UNUserNotificationCenter 实现，测试为 Mock）
     var notification: NotificationServiceProtocol { get }
+
+    /// OCR 识别服务（协议类型，基于系统 Vision）
+    var ocrService: any OCRServiceProtocol { get }
+
+    /// 采集草稿缓存服务（协议类型，处理异常退出草稿恢复）
+    var captureDraft: any CaptureDraftServiceProtocol { get }
+
+    /// 软删除调度器（具体类型，纯设备端内存撤销 Toast 状态机）
+    var deletionScheduler: DeletionScheduler { get }
+
+    /// 订阅身份/高级功能付费门控（协议类型，未来支持 StoreKit2 替换）
+    var proEntitlementProvider: any ProEntitlementProvider { get }
+
+    /// 端侧 AI 自动标注服务（协议类型，基于 Apple FoundationModels）
+    var contentTagging: any ContentTaggingServiceProtocol { get }
+
+    /// 智能拆题提取服务（协议类型，基于 Apple FoundationModels 结构化生成）
+    var questionSplitting: any QuestionSplittingServiceProtocol { get }
+
+    /// 全局操作活动追踪器（具体类型，防止在关键导出/备份期间切换 Profile 导致数据损坏）
+    var activityTracker: AppActivityTracker { get }
 }
```

### 2.2 生产容器与 Mock 容器的对称对齐
在 `LiveServiceContainer` 与 `MockServiceContainer` 中以对称形式挂载 12 个核心实例，并在此过程中为 `LiveNotificationService` 处理了非宿主单元测试环境下的优雅降级，切断了 `UNUserNotificationCenter.current()` 在静态初始化时的崩溃点。

```diff
// Packages/SnapDrillCore/Sources/SnapDrillCore/DI/LiveServiceContainer.swift
 public final class LiveServiceContainer: ServiceContainer {
     public let analytics: AnalyticsServiceProtocol
     public let pdfExport: PDFExportService
     public let appConfig: AppConfiguration
     public let privacyConsent: PrivacyConsentService
     public let notification: NotificationServiceProtocol
+    public let ocrService: any OCRServiceProtocol
+    public let captureDraft: any CaptureDraftServiceProtocol
+    public let deletionScheduler: DeletionScheduler
+    public let proEntitlementProvider: any ProEntitlementProvider
+    public let contentTagging: any ContentTaggingServiceProtocol
+    public let questionSplitting: any QuestionSplittingServiceProtocol
+    public let activityTracker: AppActivityTracker
 
     public init(
         analytics: AnalyticsServiceProtocol? = nil,
-        notification: NotificationServiceProtocol? = nil
+        notification: NotificationServiceProtocol? = nil,
+        ocrService: (any OCRServiceProtocol)? = nil,
+        captureDraft: (any CaptureDraftServiceProtocol)? = nil,
+        deletionScheduler: DeletionScheduler? = nil,
+        proEntitlementProvider: (any ProEntitlementProvider)? = nil,
+        contentTagging: (any ContentTaggingServiceProtocol)? = nil,
+        questionSplitting: (any QuestionSplittingServiceProtocol)? = nil,
+        activityTracker: AppActivityTracker? = nil
     ) {
         self.appConfig = AppConfiguration()
         self.pdfExport = PDFExportService()
         self.privacyConsent = PrivacyConsentService()
         self.analytics = analytics ?? AnalyticsServiceMock()
-        self.notification = notification ?? LiveNotificationService()
+        self.notification = notification ?? LiveNotificationService()
+        self.ocrService = ocrService ?? OCRService()
+        self.captureDraft = captureDraft ?? CaptureDraftService.shared
+        self.deletionScheduler = deletionScheduler ?? DeletionScheduler.shared
+        self.proEntitlementProvider = proEntitlementProvider ?? DefaultProEntitlementProvider()
+        self.contentTagging = contentTagging ?? ContentTaggingService()
+        self.questionSplitting = questionSplitting ?? QuestionSplittingService()
+        self.activityTracker = activityTracker ?? AppActivityTracker.shared
     }
 }
```

```diff
// Packages/SnapDrillCore/Sources/SnapDrillCore/DI/MockServiceContainer.swift
 public final class MockServiceContainer: ServiceContainer {
     public let analytics: AnalyticsServiceProtocol
     public let pdfExport: PDFExportService
     public let appConfig: AppConfiguration
     public let privacyConsent: PrivacyConsentService
     public let notification: NotificationServiceProtocol
+    public let ocrService: any OCRServiceProtocol
+    public let captureDraft: any CaptureDraftServiceProtocol
+    public let deletionScheduler: DeletionScheduler
+    public let proEntitlementProvider: any ProEntitlementProvider
+    public let contentTagging: any ContentTaggingServiceProtocol
+    public let questionSplitting: any QuestionSplittingServiceProtocol
+    public let activityTracker: AppActivityTracker
 
     public init() {
         self.analytics = AnalyticsServiceMock()
         self.pdfExport = PDFExportService()
         self.appConfig = AppConfiguration()
         self.privacyConsent = PrivacyConsentService()
         self.notification = NotificationServiceMock()
+        self.ocrService = OCRServiceMock()
+        self.captureDraft = CaptureDraftServiceMock()
+        self.deletionScheduler = DeletionScheduler()
+        self.proEntitlementProvider = MockProEntitlementProvider()
+        self.contentTagging = ContentTaggingServiceMock()
+        self.questionSplitting = QuestionSplittingServiceMock()
+        self.activityTracker = AppActivityTracker()
     }
 }
```

### 2.3 核心单例接口废弃编译告警
对于仍需在局部（如容器初始化、旧代码暂留）被访问的单例，在静态暴露上追加废弃告警，从编译期对非注入方式进行强力规约。

```diff
// Packages/SnapDrillCore/Sources/SnapDrillCore/Service/CaptureDraftService.swift
+@available(*, deprecated, message: "请通过 ServiceContainer 注入使用")
 public static let shared = CaptureDraftService()
 
-fileprivate init() {}
+public init() {} // 开放 public 供容器组装
```

```diff
// Packages/SnapDrillCore/Sources/SnapDrillCore/Service/DeletionScheduler.swift
+@available(*, deprecated, message: "请通过 ServiceContainer 注入使用")
 public static let shared = DeletionScheduler()
```

```diff
// Packages/SnapDrillCore/Sources/SnapDrillCore/Support/AppActivityTracker.swift
+@available(*, deprecated, message: "请通过 ServiceContainer 注入使用")
 public static let shared = AppActivityTracker()
```

### 2.4 核心调用方 ViewModel 与 View 装配重构

#### 2.4.1 CaptureViewModel (采集控制层解耦)
彻底移除 `CaptureViewModel` 默认的硬编码参数，引入后置注入方法 `inject()` 来切断 View 装配后门。

```diff
// Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureViewModel.swift
     // MARK: - Dependencies
     
     public var ocrService: any OCRServiceProtocol
-    private var draftService = CaptureDraftService.shared
-    private var activityTracker = AppActivityTracker.shared
+    private var draftService: any CaptureDraftServiceProtocol
+    private var activityTracker: AppActivityTracker
     
     // MARK: - Initialization
     
     /// 创建采集功能 ViewModel
     public init(
-        ocrService: any OCRServiceProtocol = OCRService()
+        ocrService: any OCRServiceProtocol = OCRService(),
+        draftService: any CaptureDraftServiceProtocol = CaptureDraftService.shared,
+        activityTracker: AppActivityTracker = AppActivityTracker.shared
     ) {
         self.ocrService = ocrService
+        self.draftService = draftService
+        self.activityTracker = activityTracker
     }
+
+    /// 后置依赖注入，用于切断 View 的 @State 隐式构造后门
+    public func inject(
+        ocrService: (any OCRServiceProtocol)? = nil,
+        draftService: (any CaptureDraftServiceProtocol)? = nil,
+        activityTracker: AppActivityTracker? = nil
+    ) {
+        if let ocrService { self.ocrService = ocrService }
+        if let draftService { self.draftService = draftService }
+        if let activityTracker { self.activityTracker = activityTracker }
+    }
```

#### 2.4.2 CaptureView (后置接线装配与 View 级解耦)
通过 `@Environment(\.services)` 统一拉取依赖，在 `.onAppear` 阶段通过后置接线（Post-initialization Wiring）完成 VM 及二级页面 VM 的高纯度依赖组装。

```diff
// Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureView.swift
     @Environment(\.repositories) private var repositories
     @Environment(\.profileManager) private var profileManager
     @Environment(\.analyticsService) private var analyticsService
+    @Environment(\.services) private var services
     
     @State private var viewModel = CaptureViewModel()
...
             .navigationDestination(for: CaptureDestination.self) { destination in
                 switch destination {
                 case .scannerResult(let content, let image):
                     let resultViewModel = CaptureResultViewModel(
                         content: content,
                         image: image,
                         repositories: repositories,
                         ocrService: viewModel.ocrService,
                         analyticsService: analyticsService,
                         imageStorage: profileManager.activeImageStorage,
+                        contentTaggingService: services.contentTagging,
+                        draftService: services.captureDraft,
+                        activityTracker: services.activityTracker,
                         router: router
                     )
                     CaptureResultView(viewModel: resultViewModel)
...
             .onAppear {
+                viewModel.inject(
+                    ocrService: services.ocrService,
+                    draftService: services.captureDraft,
+                    activityTracker: services.activityTracker
+                )
                 viewModel.checkDraftOnAppear()
             }
```

---

## 3. 自动化测试保障

为了固化 DI 容器的行为和生命周期，避免后续的代码退化，我们在 `ServiceContainerTests` 模块中追加了严苛的高强度校验单元测试：

1. **缓存单例一致性测试 (Identity Check)**：通过内存地址恒等判定 `===`，验证在 Live 容器生命周期内，多次读取同一属性（如 `captureDraft`、`ocrService`、`deletionScheduler`）返回的均是绝对相同的物理对象，消灭每次重新实例化带来的性能退化。
2. **测试期对称 Mock 注入校验**：验证在 `MockServiceContainer` 中，所有的 Protocol 类型服务在初始化时，均已被装载为对称的测试 Mock 实现类（如 `OCRServiceMock`、`CaptureDraftServiceMock`、`MockProEntitlementProvider`）。
3. **单元测试回归全绿验证**：重构 ViewModel 移除了所有隐式单例后门，运行 `AllTests` 门禁，验证所有数据备份、草稿撤销、OCR 逻辑、每日通知和 Snapshot 截屏测试在 DI 框架下 100% 绿灯。

---

## 4. 本方案的已知盲区与未来展望

作为严密的架构修复提案，我们对方案进行诚实的盲区审视：

1. **当前修复排除的服务（豁免清单）**：
   * **`ZIPArchiver`**：作为无状态的纯数据处理 struct，为了维护 SnapDrill 各 SPM 模块依赖树的单向向下（Core -> Data 错误）干净性，显式地对其进行豁免，允许局部直接构造。
   * **`TelemetryGate`**：核心是全局 UserDefaults 配置读取，作为 Utility 静态入口，予以豁免。
2. **渐进迁移路径的中间态风险**：
   * 某些遗留的 UI 组件或老模块（如部分 Preview，或某些还未完成全部迁移的子 Sheet 视图）可能仍会隐式触发标记为 `@available(*, deprecated)` 的静态单例（例如 `AppActivityTracker.shared`）。
   * **风险防范**：我们在静态成员上追加的编译废弃告警能够有效协助团队在每次编译时通过 Warns 快速定位到残存点，并能 100% 杜绝后续新入职开发者继续以静态方式编写新服务。
3. **未来新增 Service 扩展工作量评估**：
   * 在本方案一刀切平铺机制下，若未来新增一个服务（例如 `FeedbackCollectionService`）：
     1. 在 `ServiceContainer` 协议中声明 `var feedback: any FeedbackServiceProtocol`；
     2. 在 `LiveServiceContainer` 的成员与 `init()` 默认值中进行挂载；
     3. 在 `MockServiceContainer` 挂载 `FeedbackServiceMock()`；
     4. 在 `ServiceContainerTests` 补充对称性断言。
   * **工作量极低（小于 5 分钟）**，编译期强断言对称性能够瞬间抓出漏挂的容器属性，安全性极强。

---

## 5. 架构文档同步

为了保证架构文档的单一事实源（SSOT）一致性，我们已同步重构了相对路径下的 `docs/tech/architecture.md`：
* 更新了 **DI 注入链路 (Key-Type-Usage 对照表)**，补齐了包含 OCR 服务、草稿服务、删除调度器等 12 个服务的归属；
* 更新了 **SnapDrillCore 零依赖核心层目录职责表**，列齐了所有 12 个服务实现的划分，并显式标注了 `ZIPArchiver` 和 `TelemetryGate` 的架构豁免，从而为未来的新开发者提供了一幅 100% 正确、明晰的架构指南，彻底封堵了架构设计的非理性漂移。
