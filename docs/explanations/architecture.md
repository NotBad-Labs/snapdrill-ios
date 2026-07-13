---
last_verified: 2026-07-14
layer: pattern
freshness:
  max_age_days: 180
  decay_trigger: [arch_change]
---
# SnapDrill 技术架构

> 面向新开发者的架构全景图。
>
> **产品重基线边界（2026-07-14）**：本文描述当前代码，不定义产品。Product Constitution v1 已选择一个可见资料库、Release 1 无 IAP，并把 Apple 私有同步 / Pro 降为未来假设；已 ratify 的 Release 1 Contract 合入 `develop` 后继续约束 Must / hidden 与数据结果。因此下文 Multi-Profile、per-profile 偏好、Pro gating 与 CloudKit 路径只用于刻画待重审实现。不得据此新增功能或反向覆盖 `vision.md` / Release 1 Contract。Draft #868 仍须等待 DATA-1 effective 与独立 Data Contract 后重审。

---

## 架构概览

```
SnapDrill.app（薄壳，Composition Root）
    │
    ├── SnapDrillFeatures（5 个 Feature Target，UI + ViewModel）
    │   ├── FeatureCapture      采集
    │   ├── FeatureLibrary      资料库
    │   ├── FeatureReview       回顾（依赖 Library）
    │   ├── FeatureDashboard    首页（依赖 Library）
    │   └── FeatureSettings     设置（依赖 Library）
    │
    ├── SnapDrillUI（公共 UI 组件 + 路由协议）
    │   ├── 内部依赖：SnapDrillCore
    │   └── 外部依赖：Mantis（图片裁剪）
    │
    ├── SnapDrillData（SwiftData Model + Repository + 备份）
    │   └── 外部依赖：ZIPFoundation
    │
    └── SnapDrillCore（核心服务 + Protocol + DI + MetricKit）
        └── 零第三方依赖

SnapDrillShare（Share Extension）
    ├── 通过 App Groups 与主 App 共享数据
    ├── 接收分享图片 → 保存到共享容器 → URL Scheme 唤起主 App
    └── 不依赖 SnapDrillData（轻量，仅文件 I/O）
```

**依赖方向**：单向向下，禁止反向引用。Core 层零外部依赖。

---

## 新增 Core service 规则（S-D4-001 共识）

1. 若服务跨 Feature 使用、持有状态、依赖系统 API/AI/外部 SDK、或测试需要替换 → 必须进入 `ServiceContainer`
2. Profile-scoped 服务走 `ProfileManager` / `RepositoryContainer`，不得放入全局 `ServiceContainer`（典型例外：`ImageStorage`）
3. 静态 facade（如 `TelemetryGate`）必须有架构豁免决策；Feature 层不得直接调用
4. `ServiceContainer` 当前 14 个属性：analytics/pdfExport/appConfig/privacyConsent/notification/ocr/captureDraft/contentTagging/questionSplitting/deletionScheduler/proEntitlement/activityTracker/reviewScheduler/metricService
5. 显式豁免清单（不挂容器）：`TelemetryGate`（nonisolated enum，全局静态状态）/ `ZIPArchiver`（Data 层，跨包循环依赖）/ `ImageStorage`（Profile-scoped）/ `OnboardingManager` / `DependencyContainer.shared`

## 解耦准则（最优解耦 · AI 协作）

目标是**最优解耦、非极致**——"高内聚低耦合"是一对张力的最优点（极致解耦碎片化、杀内聚 → ravioli）。判据：让"未来最可能的那类变更"成本最低（Parnas 信息隐藏：按易变设计决策分解；Ousterhout 深模块：窄接口、丰富实现）。

**该解耦（DO）**：不同变化率/原因的接缝、外部依赖边界（网络/存储/第三方 SDK）、已有 2+ 实现处、SPM package 边界（= feature 隔离 + 编译边界 + agent 工作隔离）。
**不该解耦（DON'T）**：单实现 protocol、pass-through 层、为"将来可能"的投机抽象（YAGNI / Rule of Three）、同生共死的 View + 其唯一 ViewModel。

**AI/多 agent 协作的位移**（实证：MAST, NeurIPS 2025——多 agent 失败 41.8% 是规格/设计问题，显式契约是恢复成功率第一杠杆）：最优点向**显式契约**移动（类型/文档/spec/物理 package 边界），**不向更多抽象层**移动；AI 廉价量产抽象 → 须比纯人类**更严**执行 YAGNI。机制：AI 归零了抽象的"生产成本"，但没归零"契约/理解/误改成本"（Hyrum's Law：公开缝=永久契约）。

**操作法则**：
- **agent 度量痛点、不提议抽象**：让 agent 在当前结构下试实现变更，看它要的 diff/上下文多大；有痛点→开缝，无痛点→YAGNI。
- **触发器驱动重构**：同类变更连续 2 次碰 5+ 文件 = 边界画错才重构；共享抽象开始加第 2 个 bool 参数 = inline 回重复（Metz：错误抽象比重复贵）。
- **缝要么做完**：半截解耦最危险（如 KI-01——S-D4-001 半截迁移在缝里留洞、导出期 Profile 切换保护失效）；一次做透 + 配跨边界集成测试守缝，或别开。
- **编排者（人 + 主力 agent）= 架构守门**；外部评审 agent 查"YAGNI 违规 + 单实现 protocol + 隐式契约"，而非盲目鼓励解耦。

## DI 注入链路

```
DependencyContainer.shared（App 启动时初始化）
├── services: ServiceContainer（协议）→ LiveServiceContainer（实现）
├── profileManager: ProfileManager（@Observable，持有 DataExecutor）
│   ├── executor: DataExecutor（actor 拥有 ModelContainer，消除 MainActor+XPC 死锁 #599）
│   ├── activeContainer: ModelContainer（通过 executor 访问，Profile 切换时重建）
│   ├── activeRepositories: RepositoryContainer（init(executor:) 构造）
│   │   ├── review: ArchiveRepository
│   │   ├── dimension: CategoryDimensionRepository（内置 key: category / source / level / tag）
│   │   └── categoryValue: CategoryValueRepository（各维度下的值）
│   └── activeImageStorage: ImageStorage
├── router: AppRouter（构造器注入到 AppRootView）
│   └── 5 个 FeatureRouter（DashboardRouter, LibraryRouter, ...）
└── ActivityTracker: AppActivityTracker（Profile 切换保护）
```

**Environment 注入点**（SnapDrillApp.body）：

| Key | 类型 | 用途 |
|---|---|---|
| `\.services` | `ServiceContainer` | PDF 导出、通知、隐私授权、Analytics |
| `\.repositories` | `RepositoryContainer` | 数据读写 |
| `\.profileManager` | `ProfileManager` | 多 Profile 切换 |
| `\.analyticsService` | `AnalyticsServiceProtocol` | 埋点 |
| `.modelContainer()` | `ModelContainer` | SwiftData |

**Remote Config 链路**：
DependencyContainer → AppConfiguration → FeatureFlags（Remote Config 已移除，FeatureFlags 仅读 UserDefaults）

---

## 数据流

```
View（渲染层 + 依赖装配）
  │ 通过 @Environment 注入 repositories / services；router 通过构造器注入（AppRootView）
  ▼
ViewModel（@Observable，持有状态与业务流程）
  │ 通过 Repository 执行查询、保存、通知监听
  ▼
Repository（封装 ModelContext 操作，通过 DataExecutor 访问）
  │ modelContext.fetch / insert / save / rollback
  ▼
DataExecutor（actor，拥有 ModelContainer，createOffMainActor() 消除死锁）
  │
  ▼
SwiftData @Model（持久化）
```

**铁律**：
- View 不直接持有 `ModelContext`，也不在 View 层编写持久化业务规则
- 当前代码允许部分 View 通过 `@Environment(\.repositories)` 获取 `RepositoryContainer`，用于依赖装配、构造 ViewModel、NavigationDestination / Sheet 注入，以及少量轻量数据动作
- 复杂状态编排、保存流程、错误恢复与通知监听仍应放在 ViewModel
- Repository 的 `insert()` 是纯内存操作，必须显式调 `saveContext()` 才持久化
- `saveContext()` 失败后必须 `rollbackContext()` 回滚内存脏状态

**跨模块刷新机制**：
`Notification.Name.reviewDataDidChange`（定义在 `SnapDrillCore/Support/ReviewDataNotification.swift`）。发布方包括 Repository 层（`ArchiveRepository`、`CategoryDimensionRepository`、`CategoryValueRepository` 等）和部分 Feature 层写操作入口（`CaptureResultViewModel`、`LibraryEditViewModel`、`SettingsViewModel`、`DataSeeder`）。监听方：`DashboardViewModel`、`ReviewViewModel`、`DashboardAnalyticsViewModel`，通过 `for await` 订阅并刷新 UI。

**错误处理策略**：
- DB save/rollback：原子性保证，失败必须回滚。
- 当前实现的部分图片文件 I/O 仍采用 best-effort，这是待修复偏差，不是 Release 1 结果契约。C2-Image 要求已保存资料保有可读的 App-managed 内容真相；采集保存不得在必需图片不可读时报告成功。DATA-1 要求正式完整备份 all-or-nothing，salvage 必须作为单独路径明确标识。

---

## 模块职责

### SnapDrillCore（零依赖核心层）

| 目录 | 职责 |
|---|---|
| `DI/` | ServiceContainer 协议 + LiveServiceContainer + MockServiceContainer + Environment Key |
| `Service/` | Protocol 定义 + 实现（OCRServiceProtocol、PDFExportService、NotificationServiceProtocol、AnalyticsServiceProtocol、CaptureDraftService、PrivacyConsentService、DeletionScheduler、ContentTaggingService、QuestionSplittingService、ProEntitlementProvider、TelemetryGate）|
| `Capture/` | OCRService（实现）、ImageStorage（图片存储 + EXIF 剥离 GPS/位置信息）|

**端上 AI 服务**（属于 `Service/`，列出便于检索）：
- `ContentTaggingService` — Apple Foundation Models 框架自动标注（iOS 26+）
- `QuestionSplittingService` — 一图多题智能拆题（阻塞 #626 真机验证）
| `Engine/` | SM-2 复习调度算法（ReviewScheduler、SM2State、ReviewRating） |
| `Support/` | L10n、UserDefaultsKeys、AppConfiguration、ReviewDataNotification、SnapDrillTips |
| 根目录 | SnapDrillLogger（基于 os.Logger 的结构化日志） |

### SnapDrillData

| 模块 | 职责 |
|---|---|
| `*Model.swift` | SwiftData @Model 定义（ArchiveItemModel、CategoryDimensionModel、CategoryValueModel） |
| `*Repository.swift` | 数据访问层，封装 ModelContext（推荐 `init(executor:)`，保留 `init(modelContext:)` 向后兼容） |
| `DataExecutor` | actor 拥有 ModelContainer，`createOffMainActor()` 消除 MainActor+XPC 死锁（#599） |
| `RepositoryContainer` | Repository 聚合 + Environment 注入 |
| `BackupService` | .zip 备份/恢复（actor 隔离） |
| `BackupDTO` | 备份数据传输对象 |
| `ProfileManager` | 多 Profile / Vault 切换（独立数据库 + 图片目录 + per-profile UserDefaults），持有 DataExecutor |
| `ProfileMigration` | Profile 结构迁移（老版本升级） |
| `MigrationPlan` | SwiftData Schema 版本迁移 |
| `DataError` / `PersistenceError` | 错误类型定义 |
| `DataSeeder` | 初始数据填充（默认分类/来源） |
| `ArchiveExportSnapshot` | 复习数据导出快照 |

### SnapDrillUI

| 模块 | 职责 |
|---|---|
| `Navigation.swift` | FeatureRouter 协议（push/pop/reset） |
| `OnboardingView` | 引导页 + OnboardingManager |
| `ImageCropperView` | 图片裁剪（依赖 Mantis） |
| 公共组件 | SnapDrillButton, TagInputView, FlipView 等 |

### SnapDrillFeatures

每个 Feature Target 包含：
- `*View.swift` — 纯渲染层
- `*ViewModel.swift` — 状态管理 + 业务逻辑
- `*Router.swift` — 导航状态（NavigationPath + Destination enum）

**数据导入/导出归属**：
- `SnapDrillFeatureSettings/CSVParser.swift` — RFC 4180 CSV 解析（enum 纯函数，与 ViewModel 状态分离）
- `SnapDrillFeatureSettings/DataExporter.swift` — JSON / CSV 导出（含 `=+-@` 前缀防注入）
- `SettingsViewModel.swift` — CSV 导入流程编排（解析 + 字段映射 + 写入 repository）
- 导入流程触发归属：`SnapDrillFeatureSettings`（用户从设置页发起）；解析 / 转换无状态层归属：`CSVParser`

**采集方式归属**（`SnapDrillFeatureCapture`）：

| 方式 | 文件 | 备注 |
|---|---|---|
| 摄像头 | `SmartCameraView` / `SmartCameraViewController` / `CameraSessionManager` | AVFoundation |
| 文档扫描 | `DocumentScannerView` | `VisionKit.VNDocumentCameraViewController` |
| Photos 导入 | `CaptureView` PhotosPicker | PhotosUI |
| PDF 导入 | `PDFPagePickerView` | PDFKit 选页 → 渲染为 UIImage |
| 剪贴板（手动）| `CaptureMethodCard` 手动入口 → ManualEdit | 纯文本/粘贴图片，OCR 文字直接输入 |
| 手动 | `CaptureResultView` 纯文本路径 | 不依赖 OCR，允许无图保存（Image is Truth 例外）|
| Share Extension | `SnapDrillShare` Extension target | 系统 ShareSheet 入口（已实现并启用，SnapDrillShare.appex 已 embed 进主 app）|

**SmartPaper（当前遗留实现；候选，商业分层未定）**：
- 触发：`SnapDrillFeatureLibrary/SmartPaperView` + `SmartPaperViewModel`
- 选题策略：复用 `ReviewScheduler` + `SM2State`（基于 SM-2 数据驱动选题）
- 排版/导出：复用 `SnapDrillCore/Service/PDFExportService` 管线（不重新实现 PDF 引擎）
- 旧 gating：代码通过 `ProEntitlementProvider` 表达不可达分支；B6-A 后不得据此扩展 StoreKit 或公开升级路径

**ShareCard（资料分享卡片）**：
- 归属：`SnapDrillFeatureLibrary/ShareCardView`
- 渲染：SwiftUI `ImageRenderer`（iOS 16+ 标准 API），不依赖 PDFExport 管线
- 边界：仅渲染单条资料；不与 PDF 批量导出共享流水线（design §简洁，单一职责）

**当前 1/2/4 条快速打印（PrintService）**：
- 入口：`SnapDrillFeatureLibrary/LibraryDetailView`（详情页固定 1 条/页）+ 多选模式 N 条
- 契约：Core 的 `PDFExportService` 只生成 PDF `Data`；UIKit presentation adapter 放在 `SnapDrillUI`，由 Feature View 调用
- 打印与分享是两个一等入口，不把 `UIView` / `UIPrintInteractionController` 固化进 Core。完整裁决见 `docs/ui-redesign/flagship-cross-layer-contracts.md`

**高级统计（当前遗留候选实现，商业分层未定）**：
- 数据源：`SnapDrillData/RepositoryContainer` 各 Repository 聚合查询
- 聚合层：`SnapDrillFeatureDashboard/DashboardAnalyticsViewModel`
- 图表渲染：SwiftUI Charts 框架（iOS 16+）
- 旧 gating：通过 `ProEntitlementProvider` 控制不可达分支；Release 1 用户可见面必须隐藏 teaser / upsell

**Apple 私有同步（关闭的候选占位）**：
- 当前实现：所有 `@Model` 默认 `cloudKitDatabase: .none`（关闭）
- 重入路径：未裁决；旧 #479 / #485 和 Per-Profile 设计不能自行授权实现
- 候选边界：`business-model.md` 与 `../features/backlog/feat-icloud-sync.md`

## Multi-Profile 实现

ProfileManager 采用 Vault 模式：
- 每个 Profile 拥有独立的 SwiftData ModelContainer + 图片存储目录
- 切换 Profile 时重建 ModelContainer 和 RepositoryContainer
- **切换保护**：`ProfileManager.switchProfile` 先检查 `AppActivityTracker.shared.switchBlockReason`，有进行中操作时拒绝切换并返回阻塞原因。`AppActivityTracker`（SnapDrillCore/Support）定义了 `begin/end` 活动跟踪 API 和 `canSwitchProfile` / `switchBlockReason` 查询 API。目标态为采集、导出/打印、备份/恢复全部接入；当前实现以 feature spec 的缺口记录为准：采集已接入，导出预览/备份恢复仍需核对实例一致性（`feat-profile.md` KI-01 / GAP-R4），快速打印尚未接入 `.printing` tracker（`feat-export.md` GAP-R4）。
- **Per-Profile UserDefaults 隔离**：字段配置（开启的系统字段）、自动推断历史、复习目标等由 `ProfileManager` 内部通过 `perProfileKeys` 等机制管理（`savePreferences`/`loadPreferences` 为内部实现），切换 Profile 时自动保存/加载
- **全局状态**：Onboarding 完成、VoiceOver 设置不随 Profile 切换
- **Profile 级 TipKit**：ReviewSwipeTip / FieldConfigTip 通过 ProfileTipState 管理，按 Profile 隔离（#532 已修复）；设备级 Tip 基础设施保留 TipKit

---

## Soft Delete + Undo 实现

DeletionScheduler（App 级 Service，SnapDrillCore）管理 5 秒撤销窗口：
- `scheduleDeletion(ids:executor:)` — 注册待删除 ID 集合 + 删除执行器，启动 5 秒倒计时
- `undoDeletion()` — 恢复标记，取消倒计时
- `commitImmediately()` — 立即执行删除（如 App 进入后台）

LibraryViewModel 是调用方：
- `softDeleteItems()` — 调用 DeletionScheduler.scheduleDeletion，从列表临时移除
- 批量删除复用同一套机制

---

## 关键设计决策

| 决策 | 理由 |
|---|---|
| 4 个 SPM Package 而非 1 个 | 编译隔离 + 依赖方向强制 + 模块可独立测试；Features package 内含 5 个 feature target |
| Protocol-based DI + @Environment | 全部 Core service 经 `ServiceContainer` 注入（14 个属性）。Feature 层禁止直接 `.shared` 或默认 concrete init 获取服务 |
| SwiftData 而非 Core Data | iOS 26+ 项目，原生 Swift 集成更好 |
| DataExecutor actor | actor 拥有 ModelContainer，`createOffMainActor()` 消除 MainActor+XPC 死锁（#599）；Repository 双 init（executor / modelContext）向后兼容 |
| Repository 封装 ModelContext | 避免 View/ViewModel 直接操作数据库 |
| ProfileManager Vault 模式 | 每个 Profile 独立数据库，参考 Obsidian，切换时重建 ModelContainer |
| 零后端行为采集 | Firebase 与 Infrastructure 已删除；生产使用 NoOp analytics，端侧诊断使用 MetricKit（ADR-005） |
| defaultIsolation(MainActor) | xcconfig `SWIFT_VERSION = 6.3` + `-default-isolation MainActor`，统一使用 `.defaultIsolation(MainActor.self)` 减少并发标注噪音 |

---

## 测试架构

| 层 | 策略 | 运行方式 |
|---|---|---|
| Repository | in-memory ModelContainer | Xcode Simulator |
| ViewModel | Mock Repository + Mock Service | Xcode Simulator |
| Service（纯逻辑） | 直接测试 | Xcode Simulator |
| View | Smoke test only | — |

`swift test` 不可用（SPM 包仅声明 iOS 平台），必须通过 Xcode Simulator 运行。
