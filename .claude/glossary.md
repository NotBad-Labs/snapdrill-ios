# SnapDrill 术语对照表（Glossary）

> **上游依赖**：`architecture.md`（包结构、数据流）、`principles.md`（设计哲学）
> **下游影响**：`infrastructure.md`（API 命名应与术语一致）
>
> 本文件定义项目中核心概念的含义和职责边界。
> API 签名见 `infrastructure.md`，架构决策理由见 `decisions/`。

---

## 包与模块

| 术语 | 含义 | 职责边界 |
|---|---|---|
| **SnapDrillCore** | 零依赖基础包 | SM-2 调度引擎、OCR 服务协议、图片存储、日志、通知名、协议定义。不依赖任何本地包 |
| **SnapDrillData** | 数据持久化包 | @Model 定义、Repository 实现、SwiftData 迁移计划、备份/恢复。依赖 Core |
| **SnapDrillUI** | 设计系统包 | 可复用 UI 组件（FlipView、TagInputView、ImageCropper 等）。依赖 Core，不依赖 Data |
| **SnapDrillFeatures** | 功能模块包 | 5 个独立 target（Capture/Library/Review/Dashboard/Settings），每个含 View + ViewModel + Router |
| **SnapDrillInfrastructure** | 基础设施隔离包 | Firebase 全部实现（Analytics/Crashlytics/RemoteConfig）。仅 App target 可 import |

## 架构概念

| 术语 | 含义 | 在本项目中的具体表现 |
|---|---|---|
| **@Model** | SwiftData 的持久化宏，标注在 class 上使其成为数据库实体 | 直接作为领域对象使用，无 Domain struct 映射层（[ADR-001](decisions/ADR-001-model-as-domain-object.md)） |
| **Repository** | 封装数据库读写操作的 @MainActor 类 | 使用具体类而非协议，测试通过 in-memory ModelContainer 替代（[ADR-002](decisions/ADR-002-repository-no-protocol.md)） |
| **ModelContext** | SwiftData 的数据库操作上下文（类似 CoreData 的 NSManagedObjectContext） | 由 PersistenceController 创建，通过 Repository 间接访问，View 层不直接接触 |
| **@Query** | SwiftUI 宏，声明式监听 SwiftData 数据变化并自动刷新 View | 适用于列表展示和简单统计；复杂业务逻辑、跨源聚合、状态机流程不使用（见 `principles.md`） |
| **DependencyContainer** | 组合根单例（@MainActor），构造所有服务和仓库实例 | 唯一被接受的单例，通过 @Environment 注入到 View 层（[ADR-004](decisions/ADR-004-dependency-injection-pattern.md)） |
| **FeatureRouter** | 功能模块的导航路由协议 | 每个 Feature 有独立 Router，持有 NavigationPath，管理页面跳转 |

## 协议与接口

| 协议 | 定义位置 | 职责 | 为什么存在 |
|---|---|---|---|
| **ServiceContainer** | Core/DI | 聚合所有服务的访问入口 | 跨包边界的 DI 抽象，下游通过协议访问服务而非具体实现 |
| **OCRServiceProtocol** | Core/Service | 文字识别能力抽象 | 跨包服务，测试需要 mock（无 in-memory 替代） |
| **CaptureDraftServiceProtocol** | Core/Service | 采集草稿保存/加载 | 跨包服务，测试需要 mock |
| **NotificationServiceProtocol** | Core/Service | 本地通知调度 | 跨包服务，测试需要 mock（系统通知无法在测试中真实触发） |
| **AnalyticsServiceProtocol** | Core/Service | 埋点事件追踪 | 跨包服务，生产用 Firebase，测试用 Mock |
| **CrashReportingProtocol** | Core/Service | 崩溃上报 | 同上 |
| **SubscriptionServiceProtocol** | Core/Service | 订阅状态查询 | 当前为 Mock（全功能免费），未来替换为 StoreKit 2 实现 |
| **RemoteConfigurable** | Core/Support | 远程配置读取 | Firebase Remote Config 抽象 |
| **PDFExportable** | Core/Service | PDF 导出数据适配 | 无 associated type 的轻量协议，允许异构集合 `[any PDFExportable]` |
| **FeatureRouter** | UI/Navigation | 功能模块导航 | 统一导航模式，每个 Feature 遵循相同的 push/pop/reset 接口 |

> 协议存在的判断标准详见 `principles.md`「包边界与依赖方向原则 → 协议的判断标准」

## 算法与引擎

| 术语 | 含义 |
|---|---|
| **SM-2** | SuperMemo 2 间隔重复算法（1987），根据用户自评调整复习间隔。选型理由见 [ADR-007](decisions/ADR-007-sm2-algorithm.md) |
| **SM2State** | SM-2 算法的状态值类型（easeFactor / interval / repetitions / nextReviewAt / lastReviewedAt） |
| **ReviewScheduler** | SM-2 调度器（struct），输入当前状态和评分，输出新状态。纯函数，无副作用 |
| **ReviewRating** | 用户复习评分枚举：Again(0) / Hard(2) / Good(3) / Easy(5)。UI 层只暴露 Again 和 Good |
| **Difficulty** | 题目难度枚举：1-5 星。用户手动设置，与 SM-2 调度无关 |

## 数据与持久化

| 术语 | 含义 |
|---|---|
| **ReviewItemModel** | 题目实体（@Model），核心数据对象，包含题目内容、图片、元数据、SM-2 状态 |
| **TagModel** | 用户自定义标签实体（@Model），与 ReviewItemModel 多对多关系 |
| **SubjectModel / SourceModel / GradeModel** | 系统分类实体（学科/来源/年级），用户在设置中管理 |
| **ReviewExportSnapshot** | 导出专用 Sendable struct，桥接 @Model → Transferable，6 个字段 |
| **BackupPayload** | 备份数据传输对象（Codable, Sendable），包含全量题目和分类的 DTO |
| **PersistenceController** | SwiftData 容器管理器，持有 ModelContainer 实例 |
| **RepositoryContainer** | 聚合所有 Repository 的容器，通过 @Environment 注入 |

## 通知

| 通知名 | 含义 | 技术债状态 |
|---|---|---|
| `.reviewDataDidChange` | 题目数据写操作后广播，驱动 View 刷新 | 渐进消解中（TD-3），随 @Query 引入自然替代 |
| `.switchToCaptureTab` / `.switchToLibraryTab` / `.switchToSettingsTab` | 跨模块 Tab 切换 | 正常使用 |
