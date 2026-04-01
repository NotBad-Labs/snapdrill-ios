# SnapDrill 技术架构

> 面向新开发者的架构全景图。编码规范见 `.claude/rules/coding.md`，API 易错点见 `.claude/rules/api-pitfalls.md`。

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
| `\.services` | `ServiceContainer` | OCR、PDF、分析、通知等服务 |
| `\.repositories` | `RepositoryContainer` | 数据读写 |
| `\.profileManager` | `ProfileManager` | 多 Profile 切换 |
| `\.analyticsService` | `AnalyticsServiceProtocol` | 埋点 |
| `.modelContainer()` | `ModelContainer` | SwiftData |

---

## 数据流

```
View（纯渲染）
  │ @Environment(\.repositories)
  ▼
ViewModel（@Observable，持有状态）
  │ repositories.review.fetchFiltered(...)
  ▼
Repository（封装 ModelContext 操作）
  │ modelContext.fetch / insert / save
  ▼
SwiftData @Model（持久化）
```

**铁律**：
- View 不直接访问 Repository，必须通过 ViewModel
- ViewModel 不持有 ModelContext，通过 Repository 操作
- Repository 的 `insert()` 是纯内存操作，必须显式调 `saveContext()` 才持久化
- `saveContext()` 失败后必须 `rollbackContext()` 回滚内存脏状态

---

## 模块职责

### SnapDrillCore（零依赖核心层）

| 模块 | 职责 |
|---|---|
| `DI/` | ServiceContainer 协议 + Environment Key |
| `Service/` | OCR、PDF 导出、草稿、隐私授权、通知 |
| `Engine/` | SM-2 复习调度算法 |
| `Capture/` | ImageStorage 图片存储 |
| `Support/` | L10n、UserDefaults Key、AppConfiguration、SnapDrillLogger、TipKit |

### SnapDrillData

| 模块 | 职责 |
|---|---|
| `*Model.swift` | SwiftData @Model 定义（ReviewItem, Subject, Source, Grade, Tag） |
| `*Repository.swift` | 数据访问层，封装 ModelContext |
| `RepositoryContainer` | Repository 聚合 + Environment 注入 |
| `BackupService` | .snapdrill (ZIP) 备份/恢复 |
| `ProfileManager` | 多 Profile / Vault 切换（独立数据库 + 图片目录） |
| `MigrationPlan` | SwiftData Schema 版本迁移 |

### SnapDrillUI

| 模块 | 职责 |
|---|---|
| `Navigation.swift` | FeatureRouter 协议（push/pop/reset） |
| `OnboardingView` | 引导页 + OnboardingManager |
| 公共组件 | SnapDrillButton, TagInputView, FlipView, ImageCropperView 等 |

### SnapDrillFeatures

每个 Feature Target 包含：
- `*View.swift` — 纯渲染层
- `*ViewModel.swift` — 状态管理 + 业务逻辑
- `*Router.swift` — 导航状态（NavigationPath + Destination enum）

### SnapDrillInfrastructure

Firebase SDK 隔离层。Core 层通过 Protocol（AnalyticsServiceProtocol, RemoteConfigurable）与之解耦。替换 Firebase 只需修改此层 + DependencyContainer，不影响其他模块。

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
| defaultIsolation(MainActor) | Swift 6.3 全局 MainActor 隔离，减少并发标注噪音 |

---

## 测试架构

| 层 | 策略 | 运行方式 |
|---|---|---|
| Repository | in-memory ModelContainer | Xcode Simulator（`swift test` 不可用） |
| ViewModel | Mock Repository + Mock Service | Xcode Simulator |
| Service（纯逻辑） | 直接测试 | Xcode Simulator |
| View | 不测 | — |

**CI**：Mac mini 自托管 runner，`xcodebuild build-for-testing` + `xcodebuild test -scheme SnapDrillFeaturesTests`。
