---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# S-D4-001 修复提案 — Claude CLI 独立产出

> Phase 11 B 方案三任务并行之一（**ServiceContainer DI 系统性退化重构**）。
> 本提案在主 worktree 独立完成，全程未读 codex / antigravity 产出。

## 1. Bug 复现与根因定位

### 1.1 现状清单（grep 实证）

**当前 ServiceContainer 协议声明的 Service**（`ServiceContainer.swift:38-53`）：

```swift
public protocol ServiceContainer: Sendable {
    var analytics: AnalyticsServiceProtocol { get }
    var pdfExport: PDFExportService { get }
    var appConfig: AppConfiguration { get }
    var privacyConsent: PrivacyConsentService { get }
    var notification: NotificationServiceProtocol { get }
}
```

**实际 `Packages/SnapDrillCore/Sources/SnapDrillCore/Service/` 公开服务清单**：

| Service | 协议 | 实现 | 是否在 ServiceContainer | 当前注入路径 |
|---|---|---|---|---|
| `AnalyticsServiceProtocol` | ✅ | FirebaseAnalyticsService / Mock | ✅ analytics | 容器 |
| `PDFExportService` | ❌ 具体类 | PDFExportService | ✅ pdfExport | 容器 |
| `AppConfiguration` | ❌ 具体类 | AppConfiguration | ✅ appConfig | 容器 |
| `PrivacyConsentService` | ❌ 具体类 | PrivacyConsentService | ✅ privacyConsent | 容器 |
| `NotificationServiceProtocol` | ✅ | LiveNotificationService / Mock | ✅ notification | 容器 |
| `OCRServiceProtocol` | ✅ | OCRService (actor) | ❌ | 默认参数 `OCRService()` 在 ViewModel init（如 `LibraryEditViewModel:94`）|
| `CaptureDraftServiceProtocol` | ✅ | CaptureDraftService | ❌ | `.shared` 单例（`DashboardViewModel:57` / `ProfileListViewModel:45` / `CaptureRouter`）|
| `DeletionScheduler` | ❌ Observable class | DeletionScheduler | ❌ | `.shared` 单例（`LibraryViewModel:115`）|
| `ContentTaggingServiceProtocol` | ✅ | ContentTaggingService (actor) / Mock | ❌ | 暂未在 ViewModel 用 |
| `QuestionSplittingServiceProtocol` | ✅ | QuestionSplittingService (actor) / Mock | ❌ | 暂未在 ViewModel 用 |
| `ProEntitlementProvider` | ✅ | DefaultProEntitlementProvider (struct) | ❌ | 默认参数 `DefaultProEntitlementProvider()` 在 `DashboardAnalyticsViewModel:82` / `SmartPaperView:34` |
| `TelemetryGate` | ❌ enum 全局 | TelemetryGate (nonisolated enum) | ❌ | 类型层全局访问 |

**Architecture 表外的服务**（Capture/ 目录）：
- `OCRService` 在 architecture.md §Capture 已列，但**未进 ServiceContainer**
- `ImageStorage` 在 ProfileManager 内构造，不进 ServiceContainer（Profile 隔离合理，不属于本 finding）

**漏列总数**：6 个用户面 Service 绕过 DI（OCRService / CaptureDraftService / DeletionScheduler / ContentTaggingService / QuestionSplittingService / ProEntitlementProvider）+ 1 个全局枚举 `TelemetryGate`。

### 1.2 真生产违规位点（grep 证据）

```text
DashboardViewModel:57           draftService: CaptureDraftServiceProtocol = CaptureDraftService.shared
DashboardAnalyticsViewModel:82  proEntitlementProvider: any ProEntitlementProvider = DefaultProEntitlementProvider()
LibraryViewModel:115            private let deletionScheduler = DeletionScheduler.shared
LibraryEditViewModel:94         ocrService: OCRServiceProtocol = OCRService()
SmartPaperView:34               proEntitlementProvider: any ProEntitlementProvider = DefaultProEntitlementProvider()
ProfileListViewModel:45         draftService: CaptureDraftService = .shared
```

6 处默认参数 / `.shared` 直接访问 = 真违规。Test mock 无法替换这些服务（除非显式传入构造参数），违反 `architecture.md` §架构决策表「替换只需改 DependencyContainer」的承诺。

## 2. 7 项设计决策必答

### D1. 一刀切扩展 vs 分层组织

**选择**：**一刀切扩展**——全部 6 个用户面 Service 直接挂 ServiceContainer，**不**引入二级容器或职能分组。

**理由**：
- 当前 Service 总数 11 个（已挂 5 + 待挂 6），分组阈值未到（>20 才考虑）
- 分组会引入「服务归属哪个分组」的二义性（ProEntitlementProvider 是 Analytics 还是 Billing？）
- 一刀切结构与 architecture.md §SnapDrillCore.Service 表对齐，更易 grep 校验完整性

`TelemetryGate` 是 `nonisolated enum`，**不挂容器**——纯静态状态查询，无运行时依赖注入语义，不算 Service。

### D2. 全部走协议 vs 部分具体类型

**选择**：**保持现状混合策略**——可替换的走 Protocol（OCR / Notification / CaptureDraft / Tagging / Splitting / Pro / Analytics），无替代测试手段的具体类继续具体类型（PDFExport / AppConfig / PrivacyConsent / DeletionScheduler）。

**理由**：
- `DeletionScheduler` 是 `@Observable` 类，SwiftUI 直接持有引用更自然，强行 protocol 化破坏 observation 语义
- `PDFExportService` / `AppConfiguration` / `PrivacyConsentService` 已是具体类型，重构成本 vs 收益不划算
- ContentTaggingService / QuestionSplittingService 已有 protocol + actor 实现 + Mock，直接挂

### D3. 当前直接调用方处理

**选择**：**渐进迁移**——保留 `.shared` / `default param` 作为向后兼容入口，加 `@available(*, deprecated, message: "通过 @Environment(\\.services) 注入")`；新代码必须走 DI。

**理由**：
- 一次性全部改注入需要触动 6+ ViewModel + 多个 View，blast radius 大
- Deprecated 标注让编译警告渐进引导新代码走 DI，老代码到 PR 时顺手修
- 与 codex S-D4-002 fix 风格一致（cancelAll 完全移除是激进路线，本任务保留向后兼容更稳）

### D4. Mock 容器策略

**选择**：**全部新 Service 在 MockServiceContainer 提供 Mock 实例**——已有 Mock 的（CaptureDraftService / DeletionScheduler / OCRService / Tagging / Splitting / ProEntitlementProvider）直接接入；无 Mock 的（OCRService / CaptureDraftService）补 Mock 实现。

具体：
- `MockServiceContainer.captureDraft` = `CaptureDraftServiceMock`（需新建）或 in-memory CaptureDraftService 实例
- `MockServiceContainer.deletionScheduler` = 新 `DeletionSchedulerMock` 或不变 DeletionScheduler 但用 in-memory mode
- `MockServiceContainer.ocr` = `OCRServiceMock`（需新建）
- `MockServiceContainer.contentTagging` = `ContentTaggingServiceMock`（已有）
- `MockServiceContainer.questionSplitting` = `QuestionSplittingServiceMock`（已有）
- `MockServiceContainer.proEntitlement` = `MockProEntitlementProvider`（需新建，可配置 Pro/Free 状态）

### D5. Service 单例语义保证

**选择**：**容器持有 `let` 一次性初始化**（沿用现有 LiveServiceContainer 模式）。

```swift
public final class LiveServiceContainer: ServiceContainer {
    public let captureDraft: CaptureDraftServiceProtocol
    public let deletionScheduler: DeletionScheduler
    public let ocr: OCRServiceProtocol
    public let contentTagging: any ContentTaggingServiceProtocol
    public let questionSplitting: any QuestionSplittingServiceProtocol
    public let proEntitlement: any ProEntitlementProvider
    // ... 已有 5 个

    public init(...) {
        self.captureDraft = CaptureDraftService.shared  // 保留单例语义至迁移完成
        self.deletionScheduler = DeletionScheduler.shared
        self.ocr = OCRService()
        self.contentTagging = ContentTaggingService()
        self.questionSplitting = QuestionSplittingService()
        self.proEntitlement = DefaultProEntitlementProvider()
        // ...
    }
}
```

**理由**：与现有 5 个 Service 实例化模式完全一致，最低认知成本。Service 自身是否单例不由容器决定（CaptureDraftService 是单例 → 容器接它的 .shared；OCRService 是 actor 每次 init → 容器持自己的 instance）。

### D6. ADR 是否需要

**选择**：**不需要 ADR**——这是清理对齐既有承诺，不是新决策。

**理由**：
- architecture.md §架构决策表已声明「Protocol-based DI + @Environment 替换只需改 DependencyContainer」——本修复是兑现该承诺
- 没有引入新概念 / 新模式 / 新折衷
- 既有 ADR-004（文档体系深度清洁）/ ADR-005（语义层审计）已覆盖此类「实现 vs 文档对齐」类工作

但 architecture.md §模块职责 §DI 注入链路 必须同步更新（已在范围内）。

### D7. 测试覆盖最小集

新增 `ServiceContainerTests.swift` 扩展：

| 测试 | 验证 |
|---|---|
| `test_liveContainer_allServicesNotNil` | LiveServiceContainer 初始化后 12 个属性均非 nil |
| `test_mockContainer_allServicesNotNil` | MockServiceContainer 同 |
| `test_liveContainer_singletonSemantics` | 同一容器实例的 `captureDraft` 多次访问返回同实例 |
| `test_mockContainer_independentInstances` | 不同 MockServiceContainer 实例之间不共享状态（每个测试隔离）|
| `test_serviceContainer_protocolExhaustive` | （编译期）所有具体类型实现都包含全部协议属性——通过将 MockServiceContainer 用 ServiceContainer 协议类型变量持有验证 |

另外迁移 5 个真生产 ViewModel 后跑现有测试套件回归。

## 3. 修复方案 Diff

### 3.1 协议扩展 `ServiceContainer.swift`

```diff
 public protocol ServiceContainer: Sendable {
     var analytics: AnalyticsServiceProtocol { get }
     var pdfExport: PDFExportService { get }
     var appConfig: AppConfiguration { get }
     var privacyConsent: PrivacyConsentService { get }
     var notification: NotificationServiceProtocol { get }
+
+    /// OCR 识别服务（actor，端上 Vision 实现）
+    var ocr: OCRServiceProtocol { get }
+
+    /// 草稿持久化服务（采集页意外退出恢复）
+    var captureDraft: CaptureDraftServiceProtocol { get }
+
+    /// 删除调度服务（5 秒撤销窗口管理）
+    var deletionScheduler: DeletionScheduler { get }
+
+    /// 端上 AI 自动标注（Apple Foundation Models）
+    var contentTagging: any ContentTaggingServiceProtocol { get }
+
+    /// 一图多题智能拆题（阻塞 #626 真机验证）
+    var questionSplitting: any QuestionSplittingServiceProtocol { get }
+
+    /// Pro 订阅 entitlement 判定（阻塞 #479 StoreKit）
+    var proEntitlement: any ProEntitlementProvider { get }
 }
```

### 3.2 实现扩展 `LiveServiceContainer.swift`

```diff
 public final class LiveServiceContainer: ServiceContainer {
     public let analytics: AnalyticsServiceProtocol
     public let pdfExport: PDFExportService
     public let appConfig: AppConfiguration
     public let privacyConsent: PrivacyConsentService
     public let notification: NotificationServiceProtocol
+    public let ocr: OCRServiceProtocol
+    public let captureDraft: CaptureDraftServiceProtocol
+    public let deletionScheduler: DeletionScheduler
+    public let contentTagging: any ContentTaggingServiceProtocol
+    public let questionSplitting: any QuestionSplittingServiceProtocol
+    public let proEntitlement: any ProEntitlementProvider

     public init(
         analytics: AnalyticsServiceProtocol? = nil,
-        notification: NotificationServiceProtocol? = nil
+        notification: NotificationServiceProtocol? = nil,
+        ocr: OCRServiceProtocol? = nil,
+        captureDraft: CaptureDraftServiceProtocol? = nil,
+        deletionScheduler: DeletionScheduler? = nil,
+        contentTagging: (any ContentTaggingServiceProtocol)? = nil,
+        questionSplitting: (any QuestionSplittingServiceProtocol)? = nil,
+        proEntitlement: (any ProEntitlementProvider)? = nil
     ) {
         self.appConfig = AppConfiguration()
         self.pdfExport = PDFExportService()
         self.privacyConsent = PrivacyConsentService()
         self.analytics = analytics ?? AnalyticsServiceMock()
         self.notification = notification ?? LiveNotificationService()
+        self.ocr = ocr ?? OCRService()
+        self.captureDraft = captureDraft ?? CaptureDraftService.shared
+        self.deletionScheduler = deletionScheduler ?? DeletionScheduler.shared
+        self.contentTagging = contentTagging ?? ContentTaggingService()
+        self.questionSplitting = questionSplitting ?? QuestionSplittingService()
+        self.proEntitlement = proEntitlement ?? DefaultProEntitlementProvider()
     }
 }
```

### 3.3 Mock 容器扩展 `MockServiceContainer.swift`

`MockServiceContainer` 类似扩展，每个服务对应 Mock：

- `ocr` = OCRServiceMock（**需新建**，可配置 simulatedResult / simulatedError）
- `captureDraft` = CaptureDraftServiceMock（**需新建**，in-memory dict）
- `deletionScheduler` = DeletionScheduler（直接复用，nonisolated 全局状态测试中可重置）
- `contentTagging` = ContentTaggingServiceMock（已有）
- `questionSplitting` = QuestionSplittingServiceMock（已有）
- `proEntitlement` = MockProEntitlementProvider（**需新建**，可注入 isPro: Bool）

### 3.4 ViewModel / View 迁移示例（3 处代表性）

**示例 1：DashboardAnalyticsViewModel**

```diff
 final class DashboardAnalyticsViewModel {
-    private let proEntitlementProvider: any ProEntitlementProvider
+    private let proEntitlement: any ProEntitlementProvider
     // ...
-    init(
-        proEntitlementProvider: any ProEntitlementProvider = DefaultProEntitlementProvider()
-    ) {
-        self.proEntitlementProvider = proEntitlementProvider
+    init(proEntitlement: any ProEntitlementProvider) {
+        self.proEntitlement = proEntitlement
     }
 }
```

View 层创建处：

```diff
-DashboardAnalyticsViewModel()
+DashboardAnalyticsViewModel(proEntitlement: services.proEntitlement)
```

**示例 2：LibraryEditViewModel**

```diff
-init(ocrService: OCRServiceProtocol = OCRService()) {
-    self.ocrService = ocrService
+init(ocrService: OCRServiceProtocol) {
+    self.ocrService = ocrService
 }
```

**示例 3：DashboardViewModel**

```diff
-init(draftService: CaptureDraftServiceProtocol = CaptureDraftService.shared) {
-    self.draftService = draftService
+init(draftService: CaptureDraftServiceProtocol) {
+    self.draftService = draftService
 }
```

### 3.5 deprecated 标注保留过渡（兼容旧 init）

`CaptureDraftService.shared` 加：

```diff
+@available(*, deprecated, message: "通过 @Environment(\\.services).captureDraft 注入，避免静态单例耦合（S-D4-001）")
 public static let shared = CaptureDraftService()
```

`DeletionScheduler.shared` / `DefaultProEntitlementProvider` 同。

### 3.6 Architecture 文档同步

`docs/tech/architecture.md` §SnapDrillCore.Service 列表 + §DI 注入链路 段更新（已在 S-D1-006 / S-D1-014 / S-D1-015 等批量补全中部分预埋）。

## 4. 测试用例

```swift
@Suite("ServiceContainer 完整性")
struct ServiceContainerCompletenessTests {

    @Test("LiveServiceContainer 12 个属性全部非 nil")
    func liveContainer_allServicesPresent() {
        let container = LiveServiceContainer()
        #expect(container.analytics is AnalyticsServiceProtocol)
        #expect(container.pdfExport is PDFExportService)
        #expect(container.appConfig is AppConfiguration)
        #expect(container.privacyConsent is PrivacyConsentService)
        #expect(container.notification is NotificationServiceProtocol)
        #expect(container.ocr is OCRServiceProtocol)
        #expect(container.captureDraft is CaptureDraftServiceProtocol)
        // Observable class instance check
        _ = container.deletionScheduler
        _ = container.contentTagging
        _ = container.questionSplitting
        _ = container.proEntitlement
    }

    @Test("MockServiceContainer 同集结构")
    func mockContainer_allServicesPresent() {
        let container = MockServiceContainer()
        _ = container.ocr
        _ = container.captureDraft
        _ = container.deletionScheduler
        _ = container.contentTagging
        _ = container.questionSplitting
        _ = container.proEntitlement
    }

    @Test("容器单例缓存语义")
    func container_singletonSemantics() {
        let container = LiveServiceContainer()
        // 第二次访问返回相同实例
        let a1 = container.ocr
        let a2 = container.ocr
        // OCRService 是 actor，引用比较
        #expect((a1 as AnyObject) === (a2 as AnyObject))
    }

    @Test("Protocol Variance — Mock 容器可赋给 ServiceContainer 协议变量")
    func protocolVariance() {
        let _: ServiceContainer = MockServiceContainer()
    }
}

@Suite("迁移后 ViewModel 注入回归")
struct ViewModelMigrationRegressionTests {

    @Test("DashboardAnalyticsViewModel 接受任意 Pro 状态")
    func dashboardAnalytics_proInjection() {
        let mockPro = MockProEntitlementProvider(isPro: true)
        let vm = DashboardAnalyticsViewModel(proEntitlement: mockPro)
        // ... 后续断言 vm 行为
    }
}
```

## 5. 已知盲区（自检）

| 盲区 | 当前处理 | 重审触发条件 |
|---|---|---|
| `TelemetryGate` 是 nonisolated enum，未挂容器 | 视为静态全局状态，**不挂容器** | 若未来需要测试隔离 telemetry 状态 → 重审挂入 |
| `ZIPArchiver` / `BackupService` 在 SnapDrillData，跨 package 重构成本高 | 本任务范围只覆盖 SnapDrillCore.Service | Data 层 Service 重构开独立 finding |
| `ImageStorage` 在 ProfileManager 内创建（Profile 隔离合理）| 不挂全局容器 | Profile 切换语义改变时重审 |
| 渐进迁移留下 deprecated `.shared` 一段时间会触发警告噪音 | 通过 PR 顺手清理 + 全部清完后移除 deprecated 标注 | 1-2 个 PR cycle 后全清 |
| Mock 容器需要新建 3 个 Mock（OCRServiceMock / CaptureDraftServiceMock / MockProEntitlementProvider）| 范围内 | 实现 Mock 工作量约 1 小时 |
| 新增 Service 时是否会再次漏挂 | 加 `test_serviceContainer_protocolExhaustive` 编译期约束 | 未来若该测试不足以拦截 → 加 docaudit 子 check |
| `@Environment(\.services)` 的 ViewModel 不直接拿 — 由 View 层创建 ViewModel 时显式传入 | 现有模式延续 | 若引入 `@MainActor static let shared` 容器统一访问 → 重审 |

## 6. 不变性声明

- ✅ 仅修改 / 新增本文件 `docs/audits/S-D4-001-claude.md`
- ✅ 未触动任何 Service / Container / ViewModel 代码
- ✅ 未读 codex / antigravity 在各自 worktree 的产出
- ✅ 不直接 apply 到代码——apply 由 cross-fix-consensus 阶段统一做

## 7. 关联

- [任务定义书](S-D4-001-fix-task-definition.md)
- [worktree-audit-workflow](../standards/worktree-audit-workflow.md) Phase 11+ 标准
- [S-D7-001-fix-consensus](S-D7-001-fix-consensus.md) / [S-D4-002-fix-consensus](S-D4-002-fix-consensus.md) Phase 11 实战参考
- 相关 finding：S-D4-002（通知 ID Multi-Profile 已 RESOLVED，本修复**保持** NotificationServiceProtocol 注入方式）
