---
last_verified: 2026-05-19
layer: pattern
---
# SnapDrill 技术架构

> 面向新开发者的架构全景图。

---

## 架构概览

```
SnapDrill.app（薄壳，Composition Root）
    │
    ├── SnapDrillFeatures（5 个 Feature Target，UI + ViewModel）
    │   ├── FeatureCapture      采集
    │   ├── FeatureLibrary      题库
    │   ├── FeatureReview       复习（依赖 Library）
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
    ├── SnapDrillCore（核心服务 + Protocol + DI）
    │   └── 零外部依赖
    │
    └── SnapDrillInfrastructure（Firebase 隔离层）
        └── 外部依赖：Firebase SDK

SnapDrillShare（Share Extension）
    ├── 通过 App Groups 与主 App 共享数据
    ├── 接收分享图片 → 保存到共享容器 → URL Scheme 唤起主 App
    └── 不依赖 SnapDrillData（轻量，仅文件 I/O）
```

**依赖方向**：单向向下，禁止反向引用。Core 层零外部依赖。

---

## DI 注入链路

```
DependencyContainer.shared（App 启动时初始化）
├── services: ServiceContainer（协议）→ LiveServiceContainer（实现）
├── profileManager: ProfileManager（@Observable，持有 DataExecutor）
│   ├── executor: DataExecutor（actor 拥有 ModelContainer，消除 MainActor+XPC 死锁 #599）
│   ├── activeContainer: ModelContainer（通过 executor 访问，Profile 切换时重建）
│   ├── activeRepositories: RepositoryContainer（init(executor:) 构造）
│   │   ├── review: ReviewRepository
│   │   └── subject / source / grade / tag: 分类 Repository
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
`Notification.Name.reviewDataDidChange`（定义在 `SnapDrillCore/Support/ReviewDataNotification.swift`）。发布方包括 Repository（`SubjectRepository` / `SourceRepository` / `GradeRepository`）和部分 Feature 层写操作入口（`CaptureResultViewModel`、`LibraryEditViewModel`、`SettingsViewModel`、`DataSeeder`）。监听方：`DashboardViewModel`、`ReviewViewModel`、`DashboardAnalyticsViewModel`，通过 `for await` 订阅并刷新 UI。

**错误处理策略**：
- DB save/rollback：原子性保证，失败必须回滚
- 图片文件 I/O：best-effort，部分失败不回滚数据库（图片丢失不影响题目主记录）

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
| `*Model.swift` | SwiftData @Model 定义（ReviewItem, Subject, Source, Grade, Tag） |
| `*Repository.swift` | 数据访问层，封装 ModelContext（推荐 `init(executor:)`，保留 `init(modelContext:)` 向后兼容） |
| `DataExecutor` | actor 拥有 ModelContainer，`createOffMainActor()` 消除 MainActor+XPC 死锁（#599） |
| `RepositoryContainer` | Repository 聚合 + Environment 注入 |
| `BackupService` | .zip 备份/恢复（actor 隔离） |
| `BackupDTO` | 备份数据传输对象 |
| `ProfileManager` | 多 Profile / Vault 切换（独立数据库 + 图片目录 + per-profile UserDefaults），持有 DataExecutor |
| `ProfileMigration` | Profile 结构迁移（老版本升级） |
| `MigrationPlan` | SwiftData Schema 版本迁移 |
| `Persistence` | ModelContainer 工厂（PersistenceController 已废弃为兼容类型，生产代码走 DataExecutor） |
| `DataError` / `PersistenceError` | 错误类型定义 |
| `DataSeeder` | 初始数据填充（默认学科/来源） |
| `ReviewExportSnapshot` | 复习数据导出快照 |

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
| Share Extension | `SnapDrillShare` Extension target | 系统 ShareSheet 入口（待启用）|

**Smart Paper（智能组卷，ADR-001 Hybrid Pro 增值）**：
- 触发：`SnapDrillFeatureLibrary/SmartPaperView` + `SmartPaperViewModel`
- 选题策略：复用 `ReviewScheduler` + `SM2State`（基于 SM-2 数据驱动选题）
- 排版/导出：复用 `SnapDrillCore/Service/PDFExportService` 管线（不重新实现 PDF 引擎）
- Pro gating：通过 `ProEntitlementProvider` 接入 StoreKit（阻塞 #479/#486）

**ShareCard（题目分享卡片）**：
- 归属：`SnapDrillFeatureLibrary/ShareCardView`
- 渲染：SwiftUI `ImageRenderer`（iOS 16+ 标准 API），不依赖 PDFExport 管线
- 边界：仅渲染单题；不与 PDF 批量导出共享流水线（design §简洁，单一职责）

**1/2/4 题快速打印（PrintService）**：
- 入口：`SnapDrillFeatureLibrary/LibraryDetailView`（详情页固定 1 题/页）+ 多选模式 N 题
- 实现：System `UIPrintInteractionController` + 自定义 `UIPrintPageRenderer`（layoutN: 1/2/4 题/页）
- 归属：建议放 `SnapDrillCore/Service/PrintService.swift`（如代码层抽出独立类）；当前实现内联在 LibraryView 流程，将来抽取时按本归属落档

**高级统计（Pro 增值，Dashboard Hybrid 路径）**：
- 数据源：`SnapDrillData/RepositoryContainer` 各 Repository 聚合查询
- 聚合层：`SnapDrillFeatureDashboard/DashboardAnalyticsViewModel`
- 图表渲染：SwiftUI Charts 框架（iOS 16+）
- Pro gating：通过 `ProEntitlementProvider` 控制可见性（ADR-001 Hybrid，免费层只看基础指标）

**iCloud 同步（占位段，阻塞 #485）**：
- 当前实现：所有 `@Model` 默认 `cloudKitDatabase: .none`（关闭）
- 启用路径：StoreKit 落地（#479）→ 创建 CloudKit Container（#485）→ ProEntitlementProvider 判断 → Per-Profile 同步（与 BackupService 同语义边界）
- 触发文档：`docs/product/product-business.md` §iCloud 同步 / `docs/product/product-design.md` §iCloud 同步设计

### SnapDrillInfrastructure

Firebase SDK 隔离层（Analytics + Crashlytics，Remote Config 已移除）。Core 层通过 Protocol（AnalyticsServiceProtocol）与之解耦。替换 Firebase 只需修改此层 + DependencyContainer，不影响其他模块。

---

## Multi-Profile 实现

ProfileManager 采用 Vault 模式：
- 每个 Profile 拥有独立的 SwiftData ModelContainer + 图片存储目录
- 切换 Profile 时重建 ModelContainer 和 RepositoryContainer
- **切换保护**：`ProfileManager.switchProfile` 先检查 `AppActivityTracker.shared.switchBlockReason`，有进行中操作时拒绝切换并返回阻塞原因。`AppActivityTracker`（SnapDrillCore/Support）定义了 `begin/end` 活动跟踪 API 和 `canSwitchProfile` / `switchBlockReason` 查询 API。已接入：采集流程（CaptureViewModel / CaptureResultViewModel）、导出/打印、备份/恢复（SettingsViewModel）
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
| 5 个 SPM Package 而非 1 个 | 编译隔离 + 依赖方向强制 + 模块可独立测试 |
| Protocol-based DI + @Environment | 替换实现只需改 DependencyContainer，Feature 层不感知 |
| SwiftData 而非 Core Data | iOS 26+ 项目，原生 Swift 集成更好 |
| DataExecutor actor | actor 拥有 ModelContainer，`createOffMainActor()` 消除 MainActor+XPC 死锁（#599）；Repository 双 init（executor / modelContext）向后兼容 |
| Repository 封装 ModelContext | 避免 View/ViewModel 直接操作数据库 |
| ProfileManager Vault 模式 | 每个 Profile 独立数据库，参考 Obsidian，切换时重建 ModelContainer |
| Firebase 隔离到 Infrastructure | Core 层保持零外部依赖，可随时替换分析/崩溃报告方案 |
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
