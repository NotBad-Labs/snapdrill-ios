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
```

**依赖方向**：单向向下，禁止反向引用。Core 层零外部依赖。

---

## DI 注入链路

```
DependencyContainer.shared（App 启动时初始化）
├── services: ServiceContainer（协议）→ LiveServiceContainer（实现）
├── profileManager: ProfileManager
│   └── activeRepositories: RepositoryContainer
│       ├── review: ReviewRepository
│       ├── subject / source / grade / tag: 分类 Repository
│       └── activeContainer: ModelContainer（SwiftData）
└── router: AppRouter
    └── 5 个 FeatureRouter（DashboardRouter, LibraryRouter, ...）
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
DependencyContainer → FirebaseRemoteConfigService → AppConfiguration → FeatureFlags（含 isEmergencyKillSwitchActive）

---

## 数据流

```
View（渲染层 + 依赖装配）
  │ 通过 @Environment 注入 repositories / services / router
  ▼
ViewModel（@Observable，持有状态与业务流程）
  │ 通过 Repository 执行查询、保存、通知监听
  ▼
Repository（封装 ModelContext 操作）
  │ modelContext.fetch / insert / save / rollback
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
`Notification.Name.reviewDataDidChange`（定义在 `SnapDrillCore/Support/ReviewDataNotification.swift`）。发布方包括 Repository（`SubjectRepository` / `SourceRepository` / `GradeRepository`）和部分 Feature 层写操作入口（`CaptureResultViewModel`、`LibraryEditViewModel`、`SettingsViewModel`、`DataSeeder`）。监听方主要是 `DashboardViewModel` 与 `ReviewViewModel`，通过 `for await` 订阅并刷新 UI。

**错误处理策略**：
- DB save/rollback：原子性保证，失败必须回滚
- 图片文件 I/O：best-effort，部分失败不回滚数据库（图片丢失不影响题目主记录）

---

## 模块职责

### SnapDrillCore（零依赖核心层）

| 目录 | 职责 |
|---|---|
| `DI/` | ServiceContainer 协议 + LiveServiceContainer + MockServiceContainer + Environment Key |
| `Service/` | Protocol 定义（OCRServiceProtocol、PDFExportable、NotificationServiceProtocol、AnalyticsServiceProtocol） |
| `Capture/` | OCRService（实现）、ImageStorage（图片存储） |
| `Engine/` | SM-2 复习调度算法（ReviewScheduler） |
| `Support/` | L10n、UserDefaultsKeys、AppConfiguration、SnapDrillLogger、ReviewDataNotification、CaptureDraftService |

### SnapDrillData

| 模块 | 职责 |
|---|---|
| `*Model.swift` | SwiftData @Model 定义（ReviewItem, Subject, Source, Grade, Tag） |
| `*Repository.swift` | 数据访问层，封装 ModelContext |
| `RepositoryContainer` | Repository 聚合 + Environment 注入 |
| `BackupService` | .snapdrill (ZIP) 备份/恢复 |
| `BackupDTO` | 备份数据传输对象 |
| `ProfileManager` | 多 Profile / Vault 切换（独立数据库 + 图片目录 + per-profile UserDefaults） |
| `ProfileMigration` | Profile 结构迁移（老版本升级） |
| `MigrationPlan` | SwiftData Schema 版本迁移 |
| `Persistence` | ModelContainer 工厂 |
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

### SnapDrillInfrastructure

Firebase SDK 隔离层。Core 层通过 Protocol（AnalyticsServiceProtocol, RemoteConfigurable）与之解耦。替换 Firebase 只需修改此层 + DependencyContainer，不影响其他模块。

---

## Multi-Profile 实现

ProfileManager 采用 Vault 模式：
- 每个 Profile 拥有独立的 SwiftData ModelContainer + 图片存储目录
- 切换 Profile 时重建 ModelContainer 和 RepositoryContainer
- **Per-Profile UserDefaults 隔离**：字段配置（开启的系统字段）、自动推断历史、复习目标等通过 `perProfileKeys` / `savePreferences` / `loadPreferences` 管理
- **全局状态**：TipKit tooltip、Onboarding 完成、VoiceOver 设置不随 Profile 切换

---

## Soft Delete + Undo 实现

LibraryViewModel 管理 5 秒撤销窗口：
- `softDeleteItems()` — 标记删除，从列表移除，启动 5 秒 Timer
- `undoDelete()` — 恢复标记，取消 Timer
- `commitDeletion()` — Timer 到期后永久删除（Repository 级别）
- 批量删除复用同一套机制

---

## 关键设计决策

| 决策 | 理由 |
|---|---|
| 5 个 SPM Package 而非 1 个 | 编译隔离 + 依赖方向强制 + 模块可独立测试 |
| Protocol-based DI + @Environment | 替换实现只需改 DependencyContainer，Feature 层不感知 |
| SwiftData 而非 Core Data | iOS 26+ 项目，原生 Swift 集成更好 |
| Repository 封装 ModelContext | 避免 View/ViewModel 直接操作数据库 |
| ProfileManager Vault 模式 | 每个 Profile 独立数据库，参考 Obsidian，切换时重建 ModelContainer |
| Firebase 隔离到 Infrastructure | Core 层保持零外部依赖，可随时替换分析/崩溃报告方案 |
| defaultIsolation(MainActor) | 基于 swift-tools-version 6.2，统一使用 `.defaultIsolation(MainActor.self)` 减少并发标注噪音 |

---

## 测试架构

| 层 | 策略 | 运行方式 |
|---|---|---|
| Repository | in-memory ModelContainer | Xcode Simulator |
| ViewModel | Mock Repository + Mock Service | Xcode Simulator |
| Service（纯逻辑） | 直接测试 | Xcode Simulator |
| View | 不测 | — |

`swift test` 不可用（SPM 包仅声明 iOS 平台），必须通过 Xcode Simulator 运行。
