# Code Review 指南 — NotBad 项目

本文档为团队统一的代码审查（Code Review）准则，面向 `NotBad`（K12 题库与错题本）项目。目标是保证架构清晰、领域表达准确、并发安全、性能可控、测试可靠、隐私合规、以及优秀的用户体验。

> **🎯 愿景**：打造符合 Apple Design Awards 标准的高质量教育应用，在创新、包容性、用户体验上追求卓越。

请在每次 PR 评审时参考下列 **15 个核心维度** 逐项核对，并在 PR 描述中简短列出已检查项。

---

## 目录

1. [命名与代码风格](#1-命名与代码风格-naming--code-style)
2. [架构与依赖](#2-架构与依赖-architecture--dependencies)
3. [SOLID 原则](#3-solid-原则)
4. [并发与安全](#4-并发与安全swift-6)
5. [领域驱动设计](#5-领域驱动设计ddd)
6. [性能与资源管理](#6-性能与资源管理)
7. [隐私与数据安全](#7-隐私与数据安全)
8. [无障碍与包容性](#8-无障碍与包容性)
9. [本地化与国际化](#9-本地化与国际化)
10. [SwiftUI 最佳实践](#10-swiftui-最佳实践)
11. [用户体验与交互](#11-用户体验与交互)
12. [错误处理与日志](#12-错误处理与日志)
13. [测试策略](#13-测试策略)
14. [文档与可维护性](#14-文档与可维护性)
15. [网络层规范](#15-网络层规范预留)

---

## 1. 命名与代码风格 (Naming & Code Style)

### 1.1 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 类型（Class/Struct/Enum） | UpperCamelCase | `ReviewItem`, `DashboardViewModel` |
| 变量/函数 | lowerCamelCase | `fetchItems()`, `isLoading` |
| 常量 | lowerCamelCase | `let maxRetryCount = 3` |
| 枚举成员 | lowerCamelCase | `.easy`, `.medium`, `.hard` |
| 协议 | 名词或 -able/-ible/-ing | `Sendable`, `ReviewItemDataProviding` |
| 文件名 | 与主类型一致 | `ReviewItem.swift` |
| 扩展文件 | 类型+功能 | `ReviewItem+Actions.swift` |

### 1.2 文件组织

**代码分段 (MARK)：**

```swift
// MARK: - Properties

// MARK: - Initialization

// MARK: - Public Methods

// MARK: - Private Methods

// MARK: - Protocol Conformance
```

**SwiftUI View 结构顺序：**

```swift
struct MyView: View {
    // 1. 环境变量
    @Environment(\.dismiss) private var dismiss
    
    // 2. 状态 (@State, @Binding)
    @State private var isLoading = false
    @Binding var selection: Item?
    
    // 3. 依赖/属性
    let items: [Item]
    var viewModel: MyViewModel
    
    // 4. Body
    var body: some View { ... }
    
    // 5. Subviews (computed properties)
    private var headerView: some View { ... }
    
    // 6. Methods
    private func handleTap() { ... }
}

// 7. Preview
#Preview {
    MyView(items: .preview)
}
```

### 1.3 协议遵循顺序

**口诀：`"Send Case Code Hash ID"`**

```swift
enum Difficulty: Int, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    case easy = 0
    case medium = 1
    case hard = 2
    
    nonisolated var id: Int { rawValue }
}
```

**顺序说明**：

1. `Sendable` — 并发安全（最重要）
2. `CaseIterable` — 枚举遍历
3. `Codable` — 序列化
4. `Hashable` — 哈希/集合
5. `Identifiable` — SwiftUI 列表

### 1.4 禁止事项

| ❌ 禁止 | ✅ 替代方案 | 原因 |
|--------|-----------|------|
| `try!` | `do-catch`, `try?` | 崩溃风险 |
| `force unwrap (!)` | `guard let`, `??`, `if let` | 崩溃风险 |
| `print()` | `Logger.xxx()` | 生产环境无法关闭 |
| 回调闭包 (Completion Handler) | `async/await` | Swift 6 并发模型 |
| 硬编码字符串 | `LocalizedStringKey` | 本地化 |
| 固定字号 `.system(size:)` | 语义字体 `.headline` | 无障碍 |
| 硬编码颜色 `Color.black` | 语义颜色 `Color.primary` | 深色模式 |

### 1.5 Design Tokens 规范

所有 UI 样式值必须使用 Design Tokens，禁止硬编码。

#### 间距 (Spacing)

```swift
// ✅ 使用 Design Tokens
VStack(spacing: DesignTokens.Spacing.md) { ... }
.padding(DesignTokens.Spacing.lg)

// ❌ 硬编码
VStack(spacing: 16) { ... }
.padding(24)
```

| Token | 值 | 用途 |
|-------|-----|------|
| `xxs` | 2pt | 最小间距 |
| `xs` | 4pt | 紧凑元素 |
| `sm` | 8pt | 小间距 |
| `md` | 16pt | 默认间距 |
| `lg` | 24pt | 大间距 |
| `xl` | 32pt | 区块间距 |
| `xxl` | 48pt | 页面边距 |

#### 图标尺寸 (IconSize)

```swift
// ✅ 使用 Design Tokens
Image(systemName: "star.fill")
    .frame(width: DesignTokens.IconSize.md.value, 
           height: DesignTokens.IconSize.md.value)

// ❌ 硬编码
Image(systemName: "star.fill")
    .frame(width: 40, height: 40)
```

| Token | 值 | 用途 |
|-------|-----|------|
| `xxs` | 16pt | 内联图标 |
| `xs` | 24pt | 列表图标 |
| `sm` | 32pt | 小图标 |
| `md` | 40pt | 默认图标 |
| `lg` | 48pt | 大图标 |
| `xl` | 56pt | 特大图标 |
| `xxl` | 64pt | 巨型图标 |

#### 颜色 (Colors)

```swift
// ✅ 语义颜色
Color.brand.primary
Color.semantic.success
Color.semantic.warning

// ❌ 硬编码颜色
Color.blue
Color(hex: "#007AFF")
```

| 分类 | 用途 | 示例 |
|------|------|------|
| `Color.brand.*` | 品牌色 | `.primary`, `.secondary` |
| `Color.semantic.*` | 语义色 | `.success`, `.warning`, `.error` |
| 值对象颜色 | 实体区分 | `MasteryLevel.color`, `Subject.color` |

> **⚠️ 无障碍原则**：颜色仅作辅助，不应是区分信息的唯一方式。必须配合图标或文字。

### 1.6 命名审查清单

- [ ] 类型名使用 UpperCamelCase
- [ ] 变量/函数使用 lowerCamelCase
- [ ] 布尔变量使用 `is`/`has`/`should` 前缀
- [ ] 文件名与主类型一致
- [ ] 代码使用 MARK 分段
- [ ] 协议遵循顺序正确
- [ ] 间距使用 `DesignTokens.Spacing.*`
- [ ] 图标尺寸使用 `DesignTokens.IconSize.*`
- [ ] 颜色使用语义颜色或 Design Tokens

---

## 2. 架构与依赖 (Architecture & Dependencies)

### 2.1 分层架构纯净性

| 层级 | 允许依赖 | 禁止依赖 |
|------|---------|---------|
| **Domain** | Swift 标准库、Foundation (部分) | SwiftUI, UIKit, SwiftData, L10n, 第三方框架 |
| **Data** | Domain, SwiftData, Foundation | SwiftUI, UIKit |
| **Infrastructure** | Domain, 第三方框架 | Presentation |
| **Presentation** | 所有层 | 直接访问 SwiftData Context |

**检查点**:

- [ ] Domain 层是否纯净（不包含 `import SwiftUI`/`UIKit`/`L10n`）
- [ ] 关键路径：`NotBad/Domain/` 目录下所有文件
- [ ] 违例举例：`import SwiftUI`、直接使用 `Color`、调用 `EducationSystemManager.shared`

### 2.2 依赖倒置原则 (DIP)

```swift
// ✅ 正确：依赖抽象
class LibraryViewModel {
    private let dataProvider: ReviewItemDataProviding  // 协议
}

// ❌ 错误：依赖具体实现
class LibraryViewModel {
    private let dataProvider: SwiftDataReviewItemProvider  // 具体类
}
```

### 2.3 单向数据流

```text
Repository → ViewModel → View
    ↑                      |
    └──────── Action ──────┘
```

- [ ] View 不直接修改 Repository 数据
- [ ] 状态变更通过 ViewModel 的 Action 方法

### 2.4 Use Cases 层（推荐）

当业务逻辑变得复杂时，建议引入 Use Cases（Application 层）来封装跨实体的业务操作：

```swift
// ✅ 推荐：Use Case 封装复杂业务逻辑
protocol StartReviewSessionUseCaseProtocol: Sendable {
    func execute(itemIds: [UUID]) async throws -> ReviewSession
}

@MainActor
final class StartReviewSessionUseCase: StartReviewSessionUseCaseProtocol {
    private let itemRepository: ReviewItemRepositoryProtocol
    private let sessionRepository: ReviewSessionRepositoryProtocol
    private let scheduler: ReviewSchedulerProtocol
    
    func execute(itemIds: [UUID]) async throws -> ReviewSession {
        // 1. 验证题目存在
        let items = try await itemRepository.fetch(ids: itemIds)
        guard !items.isEmpty else {
            throw NotBadError.notFound(id: itemIds.first ?? UUID())
        }
        
        // 2. 按算法排序
        let sortedItems = scheduler.prioritize(items)
        
        // 3. 创建复习会话
        let session = ReviewSession(items: sortedItems)
        try await sessionRepository.save(session)
        
        return session
    }
}

// ViewModel 调用 Use Case
@MainActor
@Observable
class ReviewViewModel {
    private let startReviewUseCase: StartReviewSessionUseCaseProtocol
    
    func startReview() async {
        do {
            session = try await startReviewUseCase.execute(itemIds: selectedIds)
        } catch {
            toast = .error(error.localizedDescription)
        }
    }
}
```

**Use Cases 适用场景**：
- 跨多个 Repository 的操作
- 需要事务保证的业务流程
- 复杂的业务规则验证
- 需要复用的业务逻辑

**Use Cases 存放位置**：
```
NotBad/
├── Domain/
│   ├── UseCases/              # Use Cases 接口
│   │   ├── Review/
│   │   │   ├── StartReviewSessionUseCaseProtocol.swift
│   │   │   └── RecordReviewResultUseCaseProtocol.swift
│   │   └── Library/
│   │       └── ImportItemsUseCaseProtocol.swift
├── Application/               # Use Cases 实现（可选，也可放在 Data 层）
│   └── UseCases/
│       └── StartReviewSessionUseCase.swift
```

### 2.5 依赖注入最佳实践

当前项目使用简单的 Singleton 容器，建议逐步演进为更成熟的 DI 模式：

#### 当前方案（可接受）

```swift
// Infrastructure/DI/Dependencies.swift
@MainActor
final class Dependencies {
    static let shared = Dependencies()
    
    lazy var reviewItemRepository: ReviewItemRepositoryProtocol = {
        SwiftDataReviewItemRepository(modelContext: modelContext)
    }()
}
```

#### 推荐演进方向

**方案 A：Environment 注入（SwiftUI 原生）**

```swift
// 定义 Environment Key
private struct ReviewItemRepositoryKey: EnvironmentKey {
    static let defaultValue: ReviewItemRepositoryProtocol = MockReviewItemRepository()
}

extension EnvironmentValues {
    var reviewItemRepository: ReviewItemRepositoryProtocol {
        get { self[ReviewItemRepositoryKey.self] }
        set { self[ReviewItemRepositoryKey.self] = newValue }
    }
}

// 使用
struct LibraryView: View {
    @Environment(\.reviewItemRepository) var repository
}

// 注入
ContentView()
    .environment(\.reviewItemRepository, SwiftDataReviewItemRepository())
```

**方案 B：Factory 模式（推荐用于复杂场景）**

```swift
protocol DependencyFactory: Sendable {
    func makeReviewItemRepository() -> ReviewItemRepositoryProtocol
    func makeReviewSessionUseCase() -> StartReviewSessionUseCaseProtocol
}

@MainActor
final class ProductionDependencyFactory: DependencyFactory {
    private let modelContext: ModelContext
    
    func makeReviewItemRepository() -> ReviewItemRepositoryProtocol {
        SwiftDataReviewItemRepository(modelContext: modelContext)
    }
}

final class TestDependencyFactory: DependencyFactory {
    func makeReviewItemRepository() -> ReviewItemRepositoryProtocol {
        MockReviewItemRepository()
    }
}
```

**DI 审查清单**：
- [ ] ViewModel 不直接创建 Repository
- [ ] 依赖通过构造器或 Environment 注入
- [ ] 测试可以轻松替换依赖为 Mock
- [ ] 避免过度使用 `shared` 单例

---

## 3. SOLID 原则

### 3.1 单一职责原则 (SRP)

| 类型 | 建议行数上限 | 拆分信号 |
|------|-------------|---------|
| ViewModel | 300-600 行 | 包含多个不相关的 `@Published` 属性 |
| View | 200-400 行 | 嵌套超过 3 层的 ViewBuilder |
| Service | 200-300 行 | 方法超过 10 个 |

**拆分策略**：
```swift
// Before: 臃肿的 LibraryViewModel
class LibraryViewModel {
    func filter() { ... }
    func sort() { ... }
    func calculateStats() { ... }
}

// After: 职责分离
class LibraryViewModel {
    private let filterService: FilterService
    private let sortService: SortService
    private let statsService: StatisticsService
}
```

### 3.2 开闭原则 (OCP)

- [ ] 新功能通过新增类型扩展，而非修改现有核心代码
- [ ] 使用策略模式处理多种算法（如不同的复习算法）

### 3.3 里氏替换原则 (LSP)

- [ ] 子类可以完全替换父类使用
- [ ] Protocol 的默认实现不破坏语义

### 3.4 接口隔离原则 (ISP)

- [ ] Protocol 不包含实现者不需要的方法
- [ ] 大协议拆分为小协议（如 `Readable`, `Writable`）

### 3.5 依赖倒置原则 (DIP)

- [ ] 高层模块依赖抽象
- [ ] 依赖注入通过构造器或 `@Environment`

---

## 4. 并发与安全（Swift 6）

### 4.1 Actor 隔离

```swift
// ✅ UI 相关类型标注 @MainActor
@MainActor
@Observable
class LibraryViewModel {
    var items: [ReviewItem] = []
}

// ✅ 后台处理使用独立 Actor
actor ImageProcessor {
    func compress(_ image: Data) async -> Data { ... }
}
```

### 4.2 Sendable 合规

| 类型 | 是否需要 Sendable |
|------|------------------|
| 值对象 (Value Objects) | ✅ 必须 |
| 错误类型 | ✅ 必须 |
| Entity (class) | ⚠️ 视情况 |
| ViewModel | ❌ 不需要（@MainActor 隔离） |

### 4.3 结构化并发

```swift
// ✅ 正确：长耗时任务在后台
func processImage(_ data: Data) async throws -> ProcessedImage {
    try await Task.detached(priority: .userInitiated) {
        try Task.checkCancellation()  // 支持取消
        return try ImageProcessor.process(data)
    }.value
}

// ❌ 错误：阻塞主线程
@MainActor
func processImage(_ data: Data) -> ProcessedImage {
    ImageProcessor.process(data)  // 同步调用，阻塞 UI
}
```

### 4.4 并发审查清单

- [ ] `@Observable`/`@Published` 类型标注 `@MainActor`
- [ ] 跨 Actor 传递的类型实现 `Sendable`
- [ ] 长耗时任务（OCR、压缩）在后台执行
- [ ] `Task` 支持取消（`Task.checkCancellation()`）
- [ ] 避免 `Task { @MainActor in }` 嵌套过深

---

## 5. 领域驱动设计（DDD）

### 5.1 统一语言 (Ubiquitous Language)

| ✅ 正确术语 | ❌ 避免使用 | 定义 |
|------------|------------|------|
| `ReviewItem` | `WrongQuestion`, `ErrorItem` | 需要复习的题目 |
| `ReviewSession` | `StudySession` | 一次复习过程 |
| `MasteryLevel` | `Proficiency` | 掌握程度 |

> 📖 完整术语表参见 `docs/GLOSSARY.md`

### 5.2 充血模型 vs 贫血模型

```swift
// ✅ 充血模型：业务逻辑在实体内
struct ReviewItem {
    mutating func recordReview(result: ReviewResult) {
        self.reviewCount += 1
        self.lastReviewDate = Date()
        self.updateMasteryLevel(based: result)
    }
    
    mutating func resetProgress() {
        self.masteryLevel = .notStarted
        self.reviewCount = 0
    }
}

// ❌ 贫血模型：实体只是数据容器
struct ReviewItem {
    var reviewCount: Int
    var lastReviewDate: Date?
}

class ReviewService {
    func recordReview(item: inout ReviewItem, result: ReviewResult) { ... }
}
```

### 5.3 值对象不可变性

```swift
// ✅ 值对象应为不可变
struct TimeRange: Hashable, Sendable {
    let start: Date
    let end: Date
}

// ❌ 避免可变值对象
struct TimeRange {
    var start: Date  // 可变
    var end: Date
}
```

### 5.4 SwiftData 值对象集成

SwiftData 不直接支持自定义值对象，需使用 `rawValue` 转换模式：

```swift
@Model
final class ReviewItem {
    // 存储层 (Private/Raw)
    private var difficultyRaw: Int = 3  // 默认中等难度
    private var subjectRaw: String = ""
    
    // 领域层 (Public/Value Object)
    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .level3 }
        set { difficultyRaw = newValue.rawValue }
    }
    
    var subject: Subject {
        get { Subject(rawValue: subjectRaw) ?? .other }
        set { subjectRaw = newValue.rawValue }
    }
}
```

### 5.5 值对象必需属性

每个值对象都应提供以下属性：

| 属性 | 类型 | 用途 | 必需 |
|------|------|------|------|
| `displayName` | `String` | UI 显示（本地化） | ✅ |
| `shortLabel` | `String` | 简短标签 | ✅ |
| `icon` | `String` | SF Symbol 名称 | ✅ |
| `id` | Hashable | 唯一标识 | ✅ |
| `color` | `Color` | 主题色 | ⚠️ 可选 |

> **⚠️ 无障碍原则**：不应仅依赖颜色传达信息。`displayName`、`icon`、文字描述应足以表达含义。
> 
> `color` 仅在图表等需要视觉区分的场景可选使用，且应配合文字/图标辅助。

### 5.6 值对象命名规范

**优先使用语义命名**而非数字命名：

```swift
// ✅ 语义命名 - 代码自文档化
enum Difficulty {
    case basic    // 送分题
    case easy     // 简单
    case medium   // 中等
    case hard     // 困难
    case extreme  // 压轴
}

// ❌ 数字命名 - 可读性差
enum Difficulty {
    case level1, level2, level3, level4, level5
}
```

**语义命名优势**：
- `item.difficulty == .hard` 比 `item.difficulty == .level4` 更清晰
- 符合 Swift API Design Guidelines 的表达性原则
- 代码评审时无需查阅文档即可理解含义

### 5.7 值对象完整示例

```swift
enum Difficulty: Int, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    case basic = 0    // ⭐ 送分题
    case easy = 1     // ⭐⭐ 简单题
    case medium = 2   // ⭐⭐⭐ 中等题
    case hard = 3     // ⭐⭐⭐⭐ 困难题
    case extreme = 4  // ⭐⭐⭐⭐⭐ 压轴题
    
    nonisolated var id: Int { rawValue }
    
    /// 星级评分（1-5）
    nonisolated var stars: Int { rawValue + 1 }
    
    /// 难度系数（0.0-1.0），用于算法计算
    nonisolated var coefficient: Double {
        Double(rawValue) / Double(Self.allCases.count - 1)
    }
    
    nonisolated var displayName: String {
        String(localized: localizationKey)
    }
    
    private var localizationKey: String.LocalizationValue {
        switch self {
        case .basic: "difficulty_basic"
        case .easy: "difficulty_easy"
        case .medium: "difficulty_medium"
        case .hard: "difficulty_hard"
        case .extreme: "difficulty_extreme"
        }
    }
    
    nonisolated var shortLabel: String {
        String(localized: shortLabelKey)
    }
    
    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .basic: "difficulty_basic_short"
        case .easy: "difficulty_easy_short"
        case .medium: "difficulty_medium_short"
        case .hard: "difficulty_hard_short"
        case .extreme: "difficulty_extreme_short"
        }
    }
    
    nonisolated var icon: String {
        switch self {
        case .basic: return "gift"
        case .easy: return "star"
        case .medium: return "star.leadinghalf.filled"
        case .hard: return "star.fill"
        case .extreme: return "flame.fill"
        }
    }
}

// Note: color 属性在 Presentation 层定义，保持 Domain 纯净
// 参见 Presentation/Common/Styles/ValueObjects+UI.swift
```

---

## 6. 性能与资源管理

### 6.1 性能基线指标

| 指标 | 目标值 | 测量方法 |
|------|-------|---------|
| 冷启动时间 | < 1.5s | Instruments: App Launch |
| 热启动时间 | < 0.5s | Instruments: App Launch |
| 内存占用 (空闲) | < 50MB | Instruments: Allocations |
| 内存占用 (列表滚动) | < 150MB | Instruments: Allocations |
| 电池影响 | < 5% CPU (空闲) | Instruments: Energy Log |
| 列表滚动帧率 | 60 FPS | Instruments: Core Animation |

### 6.2 数据库查询优化

```swift
// ✅ 正确：数据库层过滤
func fetchItems(subject: Subject) -> [ReviewItem] {
    let predicate = #Predicate<ReviewItem> { $0.subject == subject }
    return try modelContext.fetch(FetchDescriptor(predicate: predicate))
}

// ❌ 错误：内存过滤
func fetchItems(subject: Subject) -> [ReviewItem] {
    let all = try modelContext.fetch(FetchDescriptor<ReviewItem>())
    return all.filter { $0.subject == subject }  // 加载全部数据后过滤
}
```

### 6.3 图片与大文件处理

```swift
// ✅ 使用外部存储
@Model
class ReviewItem {
    @Attribute(.externalStorage)
    var imageData: Data?  // 大文件自动存储在外部
}

// ✅ 异步缩略图加载
AsyncImage(url: thumbnailURL) { image in
    image.resizable()
} placeholder: {
    ProgressView()
}
```

### 6.4 性能审查清单

- [ ] 列表使用 `LazyVStack`/`LazyVGrid`
- [ ] 图片使用缩略图 + 异步加载
- [ ] 数据库查询使用 `#Predicate` 而非内存过滤
- [ ] 大文件标注 `@Attribute(.externalStorage)`
- [ ] 避免在 `body` 中进行计算密集操作
- [ ] 使用 `@Query` 时指定 `fetchLimit`

### 6.5 SwiftData 数据迁移策略

随着应用迭代，数据模型会发生变化。必须制定清晰的迁移策略。

#### 迁移类型

| 类型 | 描述 | SwiftData 支持 |
|------|------|---------------|
| **轻量迁移** | 添加可选属性、重命名 | ✅ 自动 |
| **自定义迁移** | 复杂数据转换 | ⚠️ 需要 `SchemaMigrationPlan` |
| **破坏性迁移** | 删除属性、类型变化 | ⚠️ 可能丢失数据 |

#### 迁移规范

```swift
// 1. 定义版本化 Schema
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [ReviewItemV1.self]
    }
    
    @Model
    final class ReviewItemV1 {
        var title: String
        var createdAt: Date
    }
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [ReviewItem.self]  // 当前版本
    }
}

// 2. 定义迁移计划
enum ReviewItemMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    ) { context in
        // 自定义迁移逻辑
        let items = try context.fetch(FetchDescriptor<SchemaV1.ReviewItemV1>())
        for item in items {
            // 数据转换
        }
        try context.save()
    }
}

// 3. 应用迁移计划
let container = try ModelContainer(
    for: ReviewItem.self,
    migrationPlan: ReviewItemMigrationPlan.self
)
```

#### 迁移审查清单

- [ ] 新增属性有默认值或可选
- [ ] 删除属性前确认数据已迁移
- [ ] 复杂迁移有 `SchemaMigrationPlan`
- [ ] 迁移代码有单元测试
- [ ] 迁移在 TestFlight 验证过
- [ ] 回滚方案已准备

---

## 7. 隐私与数据安全

### 7.1 App Store 隐私标签合规

| 数据类型 | 收集情况 | 用途 | 关联用户 |
|---------|---------|------|---------|
| 照片/图片 | ✅ 收集 | App 功能 | ❌ 否 |
| 使用数据 | ✅ 收集 | 分析 | ❌ 否 |
| 崩溃数据 | ✅ 收集 | 分析 | ❌ 否 |
| 标识符 | ❌ 不收集 | - | - |
| 位置 | ❌ 不收集 | - | - |

### 7.2 数据最小化原则

```swift
// ✅ 只请求必要权限
PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
    // 仅在用户选择照片时请求
}

// ❌ 避免：启动时请求所有权限
func applicationDidFinishLaunching() {
    requestAllPermissions()  // 不推荐
}
```

### 7.3 敏感数据处理

```swift
// ✅ 敏感数据存储在 Keychain
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "user_token",
    kSecValueData as String: tokenData
]
SecItemAdd(query as CFDictionary, nil)

// ❌ 避免：敏感数据存 UserDefaults
UserDefaults.standard.set(token, forKey: "user_token")
```

### 7.4 儿童隐私保护 (COPPA)

由于 NotBad 面向 K12 学生，需特别注意：

- [ ] 不收集 13 岁以下用户的个人信息
- [ ] 不包含第三方广告 SDK
- [ ] 不包含社交分享到外部平台
- [ ] 家长控制功能（如适用）

### 7.5 隐私审查清单

- [ ] 隐私标签与实际数据收集一致
- [ ] 权限请求在需要时触发，附带说明
- [ ] 用户数据不上传到未经授权的服务器
- [ ] 敏感信息使用 Keychain 存储
- [ ] 支持数据导出和删除（GDPR/儿童隐私）
- [ ] 图片 EXIF 数据按需清理
- [ ] 符合 COPPA 儿童隐私要求

---

## 8. 无障碍与包容性 (Accessibility & Inclusivity)

### 8.1 VoiceOver 支持

```swift
// ✅ 完整的无障碍标注
Button(action: startReview) {
    Image(systemName: "play.fill")
}
.accessibilityLabel("开始复习")
.accessibilityHint("双击开始今天的复习任务")
.accessibilityIdentifier("start_review_button")

// ❌ 缺少无障碍信息
Button(action: startReview) {
    Image(systemName: "play.fill")
}
```

### 8.2 Dynamic Type 支持

```swift
// ✅ 支持动态字体
Text("复习题目")
    .font(.body)  // 使用语义化字体

// ✅ 限制最大字体（防止布局破坏）
Text("标题")
    .font(.title)
    .dynamicTypeSize(...DynamicTypeSize.accessibility2)

// ❌ 固定字体大小
Text("复习题目")
    .font(.system(size: 16))  // 不响应系统字体设置
```

### 8.3 颜色与对比度

```swift
// ✅ 支持高对比度模式
@Environment(\.colorSchemeContrast) var contrast

var cardBackground: Color {
    contrast == .increased ? .black : .gray
}

// ✅ 不仅依赖颜色传达信息
HStack {
    Circle()
        .fill(item.isCompleted ? .green : .red)
    Text(item.isCompleted ? "已完成" : "未完成")  // 文字辅助
}
```

### 8.4 动画与运动

```swift
// ✅ 尊重减少动画设置
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation? {
    reduceMotion ? nil : .spring()
}

// ✅ 条件动画
withAnimation(reduceMotion ? nil : .easeInOut) {
    showDetail.toggle()
}
```

### 8.5 Switch Control 与 Full Keyboard Access

```swift
// ✅ 确保所有控件可聚焦
.focusable()

// ✅ 自定义焦点顺序
.accessibilitySortPriority(1)
```

### 8.6 无障碍审查清单

- [ ] 所有交互元素有 `accessibilityLabel`
- [ ] 图片有描述性 `accessibilityLabel`
- [ ] 支持 Dynamic Type（测试 Accessibility Size）
- [ ] 颜色对比度符合 WCAG AA 标准 (4.5:1)
- [ ] 不仅依赖颜色区分状态
- [ ] 尊重 `accessibilityReduceMotion`
- [ ] 尊重 `accessibilityReduceTransparency`
- [ ] 自定义控件可通过 VoiceOver 操作
- [ ] 支持 Switch Control / Full Keyboard Access
- [ ] UI 测试包含 VoiceOver 验证

---

## 9. 本地化与国际化 (Localization & i18n)

### 9.1 字符串本地化

```swift
// ✅ 使用 String Catalog (Xcode 15+)
Text("review_count \(count)")  // Localizable.xcstrings 中定义

// ✅ 带参数的本地化
Text("items_count", tableName: "Localizable", 
     bundle: .main, 
     comment: "Number of items")

// ❌ 硬编码字符串
Text("共 \(count) 道题目")
```

### 9.2 日期与数字格式

```swift
// ✅ 使用系统格式化器
Text(date, format: .dateTime.day().month())
Text(number, format: .number)

// ❌ 硬编码格式
Text("\(month)月\(day)日")
```

### 9.3 复数与性别

```swift
// ✅ 使用 stringsdict 处理复数
// Localizable.xcstrings 中定义:
// "item_count" = {
//   "one" = "%d item";
//   "other" = "%d items";
// };

Text("item_count \(count)")
```

### 9.4 布局适配

```swift
// ✅ 使用自适应布局
HStack {
    Text("标签")
    Spacer()
    Text(value)
}

// ✅ 支持 RTL 语言
.environment(\.layoutDirection, .rightToLeft)  // 测试用

// ❌ 固定宽度（不同语言长度不同）
Text("Label")
    .frame(width: 100)
```

### 9.5 本地化审查清单

- [ ] 所有用户可见文字使用 `LocalizedStringKey`
- [ ] 日期/数字使用系统格式化器
- [ ] 复数使用 stringsdict 规则
- [ ] 布局支持不同文字长度
- [ ] 已测试 RTL 语言布局
- [ ] 图片不包含文字（或有本地化版本）
- [ ] `Localizable.xcstrings` 更新且同步
- [ ] 支持的语言列表：简体中文、英文

---

## 10. SwiftUI 最佳实践

### 10.1 状态管理

```swift
// ✅ 正确使用状态属性包装器
struct ReviewView: View {
    @State private var isExpanded = false      // View 私有状态
    @Binding var selectedItem: ReviewItem?     // 父子双向绑定
    @Environment(\.dismiss) var dismiss        // 环境值
    
    var viewModel: ReviewViewModel             // @Observable 对象直接引用
}

// ❌ 错误用法
struct ReviewView: View {
    @State var viewModel = ReviewViewModel()   // ViewModel 不应是 @State
    @ObservedObject var item: ReviewItem       // 应使用 @Bindable 或 Binding
}
```

### 10.2 视图拆分

```swift
// ✅ 提取子视图
struct LibraryView: View {
    var body: some View {
        List {
            ForEach(items) { item in
                ReviewItemRow(item: item)  // 独立组件
            }
        }
    }
}

struct ReviewItemRow: View {
    let item: ReviewItem
    var body: some View { ... }
}

// ❌ 避免：深度嵌套的 ViewBuilder
var body: some View {
    VStack {
        HStack {
            VStack {
                HStack { ... }  // 嵌套过深
            }
        }
    }
}
```

### 10.3 性能优化

```swift
// ✅ 使用 Equatable 优化
struct ReviewItemRow: View, Equatable {
    let item: ReviewItem
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.item.id == rhs.item.id && lhs.item.title == rhs.item.title
    }
}

// ✅ 避免在 body 中创建对象
struct MyView: View {
    private let formatter = DateFormatter()  // 提取到属性
    
    var body: some View {
        Text(formatter.string(from: date))
    }
}
```

### 10.4 导航与生命周期

```swift
// ✅ 使用 NavigationStack (iOS 16+)
NavigationStack(path: $path) {
    LibraryView()
        .navigationDestination(for: ReviewItem.self) { item in
            ReviewDetailView(item: item)
        }
}

// ✅ 正确使用 task 修饰符
.task {
    await viewModel.loadData()
}
.task(id: selectedItem) {
    await viewModel.loadDetails(for: selectedItem)
}
```

### 10.5 SwiftUI 审查清单

- [ ] ViewModel 使用 `@Observable` 而非 `ObservableObject`
- [ ] View 私有状态使用 `@State`
- [ ] 父子通信使用 `@Binding` 或回调
- [ ] 视图嵌套不超过 3-4 层
- [ ] 复杂视图拆分为独立组件
- [ ] 列表使用 `LazyVStack`/`List`
- [ ] 条件渲染使用 `if` 而非 `.opacity(0)`
- [ ] 使用 `NavigationStack` 而非 `NavigationView`

---

## 11. 用户体验与交互 (UX & Interaction)

### 11.1 状态处理 (State Handling)

每个数据驱动的视图必须处理以下状态：

```swift
struct LibraryView: View {
    @State var viewModel: LibraryViewModel
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                LoadingView()
            case .empty:
                EmptyStateView(
                    title: "暂无题目",
                    message: "点击 + 添加你的第一道错题",
                    action: addItem
                )
            case .error(let error):
                ErrorStateView(error: error, retry: viewModel.reload)
            case .loaded(let items):
                ItemListView(items: items)
            }
        }
    }
}
```

### 11.2 反馈与响应

```swift
// ✅ 操作反馈
Button("删除") {
    hapticFeedback.notificationOccurred(.warning)
    showDeleteConfirmation = true
}

// ✅ 加载状态
Button("保存") {
    isSaving = true
}
.disabled(isSaving)
.overlay {
    if isSaving { ProgressView() }
}
```

### 11.3 手势与动画

```swift
// ✅ 有意义的动画
.animation(.spring(response: 0.3), value: isExpanded)

// ✅ 手势反馈
.gesture(
    LongPressGesture()
        .onChanged { _ in
            hapticFeedback.impactOccurred(intensity: 0.5)
        }
)

// ❌ 过度动画
.animation(.default, value: UUID())  // 每次都触发
```

### 11.4 错误处理与恢复

```swift
// ✅ 友好的错误提示
.alert("保存失败", isPresented: $showError) {
    Button("重试") { Task { await save() } }
    Button("取消", role: .cancel) { }
} message: {
    Text("无法保存题目，请检查网络连接后重试。")
}

// ✅ 自动恢复
.task {
    do {
        try await loadData()
    } catch {
        // 自动重试一次
        try? await Task.sleep(for: .seconds(2))
        try? await loadData()
    }
}
```

### 11.5 UX 审查清单

- [ ] 列表有空状态视图
- [ ] 网络请求有加载指示器
- [ ] 错误有友好提示和重试选项
- [ ] 破坏性操作有确认弹窗
- [ ] 操作有触觉反馈
- [ ] 动画时长合理（0.2-0.4s）
- [ ] 支持下拉刷新（如适用）
- [ ] 长列表有滚动指示器
- [ ] 支持 Undo（如适用）

---

## 12. 错误处理与日志

### 12.1 统一错误类型

所有业务错误使用 `NotBadError` 枚举，确保类型安全和本地化。

#### 分层错误体系

| 层级 | 错误类型 | 职责 | 示例 |
|------|---------|------|------|
| **Domain** | `DomainError` | 业务规则违反 | 验证失败、状态不一致 |
| **Data** | `RepositoryError` | 数据操作失败 | 保存失败、查询失败 |
| **Infrastructure** | `InfrastructureError` | 外部服务错误 | OCR 失败、文件系统错误 |
| **Presentation** | 转换为用户提示 | 显示友好信息 | Toast、Alert |

```swift
// Domain 层错误（纯业务逻辑）
enum DomainError: Error, Sendable {
    case validationFailed(field: String, reason: String)
    case invalidStateTransition(from: String, to: String)
    case businessRuleViolation(rule: String)
}

// Data 层错误（数据操作）
enum RepositoryError: Error, Sendable {
    case saveFailed(underlying: Error)
    case fetchFailed(underlying: Error)
    case notFound(id: UUID)
    case duplicateEntry(identifier: String)
}

// Infrastructure 层错误（外部服务）
enum InfrastructureError: Error, Sendable {
    case ocrFailed(reason: String)
    case fileSystemError(path: String, underlying: Error)
    case permissionDenied(resource: String)
}

// 统一应用错误（面向用户）
enum NotBadError: LocalizedError, Sendable {
    case saveFailed(reason: String)
    case notFound(id: UUID)
    case validationFailed(field: String, reason: String)
    case networkError(underlying: Error)
    case permissionDenied(type: String)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let reason): 
            return String(localized: "保存失败: \(reason)")
        case .notFound(let id): 
            return String(localized: "未找到项目: \(id)")
        case .validationFailed(let field, let reason): 
            return String(localized: "\(field) 验证失败: \(reason)")
        case .networkError: 
            return String(localized: "网络连接失败")
        case .permissionDenied(let type): 
            return String(localized: "\(type) 权限被拒绝")
        }
    }
}
```

### 12.2 错误传播链

```
Repository (throws) → ViewModel (catch) → View (display)
```

```swift
// Repository: 抛出错误
func save(_ item: ReviewItem) throws {
    guard item.isValid else {
        throw NotBadError.validationFailed(field: "title", reason: "不能为空")
    }
    try modelContext.save()
}

// ViewModel: 捕获并转换为 UI 状态
@MainActor
func save() {
    do {
        try repository.save(item)
        toast = .success("保存成功")
    } catch let error as NotBadError {
        toast = .error(error.localizedDescription)
        Logger.error("Save failed", error: error)
    } catch {
        toast = .error("未知错误")
        Logger.error("Unexpected error", error: error)
    }
}
```

### 12.3 Toast 提示类型

| 类型 | 用途 | 示例 |
|------|------|------|
| `.success` | 操作成功 | 保存成功、删除成功 |
| `.error` | 操作失败 | 保存失败、网络错误 |
| `.warning` | 警告提示 | 数据未保存、权限受限 |
| `.info` | 信息提示 | 提示用户操作 |

### 12.4 日志规范

使用 `Logger` 工具统一输出，支持分类和多级日志。**禁止使用 `print()`**。

#### Logger 分类

| 分类 | 用途 | 示例 |
|------|------|------|
| `.ui` | UI 层日志 | 视图生命周期、用户交互 |
| `.data` | 数据层日志 | 数据库操作、缓存 |
| `.review` | 复习业务日志 | 复习流程、算法计算 |
| `.ai` | AI 服务日志 | OCR、AI 分析 |

```swift
// ✅ 使用分类 Logger
import OSLog

private let logger = Logger.ui  // 或 .data, .review, .ai

func loadData() {
    logger.debug("Loading library items")
    logger.info("Loaded \(items.count) items")
    logger.warning("Cache miss, fetching from database")
    logger.error("Failed to load items: \(error)")
}

// ❌ 禁止使用 print
print("Loading items...")  // 🚨 禁止
```

#### 日志级别

| 级别 | 方法 | 生产环境 | 用途 |
|------|------|---------|------|
| **Debug** | `logger.debug()` | ❌ 禁用 | 调试信息、变量值 |
| **Info** | `logger.info()` | ❌ 禁用 | 业务流程、用户操作 |
| **Warning** | `logger.warning()` | ✅ 保留 | 潜在问题、降级处理 |
| **Error** | `logger.error()` | ✅ 保留 | 异常错误、崩溃前兆 |

#### Logger 定义位置

```swift
// Infrastructure/Utils/Logger+Categories.swift
import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.notbad"
    
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let data = Logger(subsystem: subsystem, category: "Data")
    static let review = Logger(subsystem: subsystem, category: "Review")
    static let ai = Logger(subsystem: subsystem, category: "AI")
}
```

### 12.5 日志隐私保护

**🚨 绝对禁止记录：**
- 用户内容（错题文本、图片数据）
- 个人身份信息（姓名、学校）
- 完整的 UUID（使用脱敏）

```swift
// ✅ 正确：只记录元数据
Logger.error("Save failed", error: error, context: [
    "itemId": Logger.mask(item.id),  // 脱敏处理
    "imageSize": "\(data.count)",    // 只记录大小
    "subject": item.subject.rawValue // 枚举值
])

// ❌ 错误：记录用户内容
Logger.error("Save failed: \(item.title)")  // 泄露用户内容
```

### 12.6 错误处理审查清单

- [ ] 使用 `NotBadError` 统一错误类型
- [ ] Repository 层抛出错误，ViewModel 层捕获
- [ ] 用户看到友好的本地化错误提示
- [ ] 错误日志包含上下文但不含隐私数据
- [ ] 使用 `Logger` 而非 `print()`
- [ ] 生产环境只保留 Warning/Error 级别

---

## 13. 测试策略

### 13.1 测试金字塔

```
        /\
       /  \      E2E Tests (NotBadUITests)
      /----\     少量，覆盖关键用户流程
     /      \
    /--------\   Integration Tests
   /          \  数据层 + ViewModel 集成
  /------------\ 
 / Unit Tests   \  大量，覆盖业务逻辑
/________________\
```

### 13.2 F.I.R.S.T. 原则

| 原则 | 检查点 | 项目实践 |
|------|--------|----------|
| **Fast** | 单测 < 100ms | 使用 `MockOCRService`、内存数据库 |
| **Independent** | 无测试间依赖 | `setUp` 重置状态 |
| **Repeatable** | 任何环境通过 | 固定 Reference Date |
| **Self-Validating** | 无人工检查 | 使用 `#expect`/`XCTAssert` |
| **Timely** | 及时覆盖 | PR 必须包含测试 |

### 13.3 测试代码结构 (AAA)

```swift
@Test
func recordReview_updatesProgress() async throws {
    // Arrange
    var item = ReviewItem(title: "测试题目")
    
    // Act
    item.recordReview(result: .correct)
    
    // Assert
    #expect(item.reviewCount == 1)
    #expect(item.masteryLevel == .learning)
}
```

### 13.4 UI 测试 Page Object

```swift
// ✅ Page Object 封装
struct DashboardPage {
    let app: XCUIApplication
    
    var startReviewButton: XCUIElement {
        app.buttons["start_review_button"]
    }
    
    var statsCards: XCUIElement {
        app.otherElements["stats_cards"]
    }
    
    func tapStartReview() {
        startReviewButton.tap()
    }
    
    func waitForLoad() {
        _ = statsCards.waitForExistence(timeout: 5)
    }
}

// 使用
func testStartReview() {
    let dashboard = DashboardPage(app: app)
    dashboard.waitForLoad()
    dashboard.tapStartReview()
}
```

### 13.5 稳定性与抗脆性

```swift
// ✅ 正确：使用 waitForExistence
let button = app.buttons["submit_button"]
XCTAssertTrue(button.waitForExistence(timeout: 5))
button.tap()

// ❌ 错误：硬等待
sleep(2)  // 🚨 绝对禁止
app.buttons["submit_button"].tap()
```

### 13.6 测试覆盖重点

| 模块 | 覆盖重点 | 测试类型 |
|------|---------|---------|
| Domain 实体 | 业务逻辑、边界条件 | 单元测试 |
| ViewModel | 状态变化、错误处理 | 单元测试 |
| Repository | CRUD 操作、查询 | 集成测试 |
| OCR/图片处理 | Mock 延迟、错误 | 单元测试 |
| 关键用户流程 | 添加题目、复习 | UI 测试 |
| 数据迁移 | 模型版本升级 | 集成测试 |

### 13.7 测试审查清单

- [ ] 新功能有对应单元测试
- [ ] 测试使用 AAA 结构
- [ ] Mock 服务支持错误场景
- [ ] UI 测试使用 `waitForExistence` 而非 `sleep`
- [ ] 使用 `accessibilityIdentifier` 定位元素
- [ ] 断言失败信息清晰
- [ ] 测试命名遵循 `methodName_condition_expectedResult`
- [ ] 测试文件位置与主项目结构对应
- [ ] Mock 对象放在 `Mocks/` 目录
- [ ] 使用 Swift Testing (`@Test`) 而非 XCTest（新测试）

---

## 14. 文档与可维护性

### 14.1 代码注释规范

```swift
/// 记录一次复习结果并更新掌握程度
///
/// 根据复习结果调整掌握等级：
/// - 正确：提升一级（最高 `.mastered`）
/// - 错误：降至 `.needsReview`
///
/// - Parameter result: 复习结果（正确/错误）
/// - Note: 此方法会自动更新 `lastReviewDate`
/// - SeeAlso: ``resetProgress()``
mutating func recordReview(result: ReviewResult) {
    // 实现...
}
```

### 14.2 TODO 与 FIXME 规范

```swift
// TODO: [Feature] 支持批量导入 - Issue #123
// FIXME: [Performance] 大列表滚动卡顿 - 需要虚拟化
// HACK: [Workaround] iOS 17 导航栏 bug，等待系统修复
// NOTE: 此处逻辑与 Android 端保持一致
```

### 14.3 Git Commit 规范

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type 类型**:

| Type | 说明 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `refactor` | 重构（无功能变化） |
| `perf` | 性能优化 |
| `test` | 测试相关 |
| `docs` | 文档更新 |
| `chore` | 构建/工具变更 |
| `style` | 代码格式（不影响逻辑） |
| `ci` | CI/CD 配置 |

**Scope 范围**:

| Scope | 说明 |
|-------|------|
| `domain` | Domain 层 |
| `data` | Data 层 |
| `ui` | Presentation 层 |
| `infra` | Infrastructure |
| `test` | 测试代码 |
| `widget` | Widget 扩展 |

**示例**:
```
feat(domain): 添加间隔复习算法

实现基于 SM-2 的间隔复习算法，根据用户答题结果
动态调整复习间隔。

- 添加 SpacedRepetitionService
- 更新 ReviewItem.nextReviewDate 计算逻辑
- 添加相关单元测试

Closes #42
```

### 14.4 文档审查清单

- [ ] 公共 API 有文档注释
- [ ] 复杂算法有解释说明
- [ ] TODO/FIXME 关联 Issue 编号
- [ ] 术语使用与 GLOSSARY.md 一致
- [ ] README 保持更新
- [ ] CHANGELOG 记录重要变更
- [ ] Commit Message 符合规范

---

## 📋 Pull Request 审查清单

在提交 PR 前，请确保以下各项已检查：

### 架构与代码质量
- [ ] Domain 层无 UI/L10n 依赖
- [ ] 遵循 SOLID 原则
- [ ] 并发安全（`@MainActor`/`Sendable`）
- [ ] 数据库查询优化（使用 `#Predicate`）
- [ ] 长耗时任务后台执行

### 用户体验
- [ ] 处理加载/空/错误状态
- [ ] 支持 Dynamic Type
- [ ] 包含无障碍标注
- [ ] 动画尊重 Reduce Motion
- [ ] 触觉反馈合理

### 隐私与安全
- [ ] 权限请求合理
- [ ] 敏感数据安全存储
- [ ] 隐私标签一致
- [ ] 符合 COPPA（如涉及儿童）

### 本地化
- [ ] 无硬编码字符串
- [ ] 日期/数字使用系统格式化器
- [ ] 布局适配不同语言

### 测试
- [ ] 新功能有单元测试
- [ ] 关键流程有集成测试
- [ ] 测试无 `sleep()` 硬等待

### 文档
- [ ] 公共 API 有注释
- [ ] 术语符合 GLOSSARY.md
- [ ] Commit Message 规范

---

## 📝 PR 评论模板

### 架构问题
> ⚠️ **Architecture**: `Domain/ValueObjects/Subject.swift` 第 15 行使用了 `Color`，请将 UI 相关属性迁移到 `Presentation/Extensions/Subject+UI.swift`。
> 
> 参考：[架构与依赖 §1.1](#11-分层架构纯净性)

### 并发问题
> 🔄 **Concurrency**: 此处在后台执行图像处理，但未检查取消状态。建议添加 `try Task.checkCancellation()` 以支持用户取消。
>
> 参考：[并发与安全 §3.3](#33-结构化并发)

### 性能问题
> ⚡ **Performance**: `fetchItems().filter { ... }` 在内存中过滤数据，数据量大时会影响性能。请改用 `#Predicate` 在数据库层过滤。
>
> 参考：[性能与资源管理 §5.2](#52-数据库查询优化)

### 无障碍问题
> ♿ **Accessibility**: 此按钮缺少 `accessibilityLabel`，VoiceOver 用户无法理解其功能。建议添加描述性标签。
>
> 参考：[无障碍与包容性 §7.1](#71-voiceover-支持)

### 测试问题
> 🧪 **Testing**: UI 测试使用了 `sleep(2)`，可能导致 CI 不稳定。请改用 `waitForExistence(timeout:)`。
>
> 参考：[测试策略 §11.5](#115-稳定性与抗脆性)

### 本地化问题
> 🌍 **Localization**: 发现硬编码字符串 `"共 \(count) 道题目"`，请使用 `LocalizedStringKey` 并添加到 `Localizable.xcstrings`。
>
> 参考：[本地化与国际化 §8.1](#81-字符串本地化)

### 隐私问题
> 🔒 **Privacy**: 此处将用户 token 存储在 UserDefaults，建议改用 Keychain 以提高安全性。
>
> 参考：[隐私与数据安全 §6.3](#63-敏感数据处理)

---

## 15. 网络层规范（预留）

> 📌 **注意**：NotBad 当前为纯本地应用，本章节为未来云同步/AI 服务预留规范。

### 15.1 网络架构原则

```
View → ViewModel → UseCase → Repository → NetworkService → API
                                              ↓
                                         URLSession
```

**核心原则**：
- Repository 抽象网络调用，上层无感知
- 网络请求统一使用 `async/await`
- 错误类型化，支持重试策略
- 请求/响应日志化（脱敏）

### 15.2 API 客户端规范

```swift
// ✅ 推荐：协议抽象
protocol APIClientProtocol: Sendable {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

// Endpoint 定义
struct Endpoint: Sendable {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]
    let body: Data?
    let timeout: TimeInterval
}

// 实现
actor APIClient: APIClientProtocol {
    private let session: URLSession
    private let baseURL: URL
    private let authProvider: AuthProviderProtocol
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headers
        request.httpBody = endpoint.body
        
        // 添加认证
        try await authProvider.authorize(&request)
        
        // 执行请求
        let (data, response) = try await session.data(for: request)
        
        // 验证响应
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard 200..<300 ~= httpResponse.statusCode else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        // 解码
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

### 15.3 网络错误处理

```swift
enum NetworkError: Error, Sendable {
    case noConnection
    case timeout
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingFailed(underlying: Error)
    case unauthorized
    case serverError(message: String)
    
    var isRetryable: Bool {
        switch self {
        case .noConnection, .timeout, .serverError:
            return true
        default:
            return false
        }
    }
}

// 重试策略
struct RetryPolicy: Sendable {
    let maxAttempts: Int
    let delay: Duration
    let backoffMultiplier: Double
    
    static let `default` = RetryPolicy(
        maxAttempts: 3,
        delay: .seconds(1),
        backoffMultiplier: 2.0
    )
}
```

### 15.4 离线优先策略

```swift
// Repository 支持离线优先
protocol SyncableRepositoryProtocol {
    func fetch() async throws -> [Item]           // 优先本地，后台同步
    func save(_ item: Item) async throws          // 保存本地，排队上传
    func sync() async throws                      // 手动同步
    var syncStatus: SyncStatus { get }            // 同步状态
}

enum SyncStatus: Sendable {
    case synced
    case pendingUpload(count: Int)
    case syncing
    case error(NetworkError)
}
```

### 15.5 网络审查清单（未来）

- [ ] API 请求使用 `async/await`
- [ ] 请求超时设置合理（默认 30s）
- [ ] 支持请求取消
- [ ] 错误类型化且支持重试
- [ ] 敏感数据传输加密
- [ ] 认证 Token 安全存储（Keychain）
- [ ] 离线场景优雅降级
- [ ] 网络日志不包含敏感信息

---

## 附录

### A. 快速导航

| 文档 | 路径 | 说明 |
|------|------|------|
| 📖 术语表 | [`docs/GLOSSARY.md`](./GLOSSARY.md) | 项目统一术语定义 |
| 🏪 商店信息 | [`docs/APP_STORE_LISTING.md`](./APP_STORE_LISTING.md) | App Store 描述 |
| 📋 发布清单 | [`RELEASE_CHECKLIST.md`](../RELEASE_CHECKLIST.md) | 发布前检查项 |

### B. 参考资源

**Apple 官方文档**
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Accessibility Programming Guide](https://developer.apple.com/accessibility/)
- [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)

**WWDC 推荐 Sessions**
- [Design for everyone](https://developer.apple.com/videos/play/wwdc2023/10034/) (WWDC23)
- [Meet Swift Testing](https://developer.apple.com/videos/play/wwdc2024/10179/) (WWDC24)
- [Swift concurrency: Update a sample app](https://developer.apple.com/videos/play/wwdc2021/10194/) (WWDC21)
- [Demystify SwiftUI performance](https://developer.apple.com/videos/play/wwdc2023/10160/) (WWDC23)
- [What's new in privacy](https://developer.apple.com/videos/play/wwdc2023/10053/) (WWDC23)

### C. 常见 Xcode 警告处理

| 警告 | 原因 | 解决方案 |
|------|------|---------|
| `Sending 'X' risks causing data races` | 跨 Actor 传递非 Sendable 类型 | 添加 `Sendable` 合规或使用 `@unchecked Sendable` |
| `Non-sendable type 'X' passed in call` | 同上 | 使用值类型或 Actor 隔离 |
| `Main actor-isolated property cannot be mutated from Sendable closure` | 在后台闭包中修改 UI 状态 | 使用 `await MainActor.run { }` |
| `String interpolation should not be used for localization` | 字符串未本地化 | 使用 `LocalizedStringKey` |

### D. Apple Design Awards 评判维度

本指南的设计参考了 Apple Design Awards 的评判标准：

| 维度 | 指南覆盖章节 |
|------|-------------|
| **创新 (Innovation)** | 架构设计、DDD |
| **愉悦与趣味 (Delight and Fun)** | UX 与交互 |
| **交互 (Interaction)** | SwiftUI 最佳实践、UX |
| **社会影响 (Social Impact)** | 隐私、儿童保护 |
| **视觉与图形 (Visuals and Graphics)** | SwiftUI、动画 |
| **包容性 (Inclusivity)** | 无障碍、本地化 |

---

## 版本历史

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|---------|------|
| 1.0 | 2025-12-05 | 初始版本：7 个核心维度 | Team |
| 2.0 | 2025-12-05 | 扩展至 12 个维度 | Team |
| | | - 新增隐私与数据安全（含 COPPA） | |
| | | - 新增无障碍与包容性（含 Switch Control） | |
| | | - 新增本地化与国际化 | |
| | | - 新增 SwiftUI 最佳实践 | |
| | | - 新增 UX 交互（含错误恢复） | |
| | | - 新增 Git Commit 规范 | |
| | | - 添加 PR 评论模板 | |
| | | - 添加 Apple Design Awards 参考 | |
| 3.0 | 2025-12-05 | 扩展至 14 个维度，合并 CODING_STANDARDS | Team |
| | | - 新增命名与代码风格（含 MARK 分段） | |
| | | - 新增错误处理与日志（含 Logger 规范） | |
| | | - 新增 SwiftData 值对象集成模式 | |
| | | - 新增协议遵循顺序口诀 | |
| | | - 新增禁止事项表格 | |
| | | - 删除 CODING_STANDARDS.md（已合并） | |
| 3.1 | 2025-12-05 | 值对象规范优化 | Team |
| | | - 采用语义命名（basic/easy/medium/hard/extreme） | |
| | | - 新增 §5.6 值对象命名规范 | |
| | | - color 属性移至 Presentation 层 | |
| | | - 示例代码与实际实现保持一致 | |
| 3.2 | 2025-12-05 | 完善 Design Tokens 与测试规范 | Team |
| | | - 新增 §1.5 Design Tokens 规范（Spacing、IconSize、Colors） | |
| | | - 更新 §2.1 分层架构（含目录结构说明） | |
| | | - 更新 §12.4 Logger 规范（分类日志） | |
| | | - Infrastructure 层明确禁止 SwiftUI 依赖 | |
| 3.3 | 2025-12-05 | 文档清理 | Team |
| | | - 删除 PROJECT_STRUCTURE.md、TECHNICAL_DEBT.md | |
| | | - 修复测试章节编号（§13.7） | |
| | | - 更新快速导航链接 | |
| 4.0 | 2025-12-05 | 企业级架构增强，扩展至 15 个维度 | Team |
| | | - 新增 §2.4 Use Cases 层规范（Application 层） | |
| | | - 新增 §2.5 依赖注入最佳实践（Environment/Factory） | |
| | | - 增强 §12.1 分层错误体系（Domain/Data/Infrastructure） | |
| | | - 新增 §6.5 SwiftData 数据迁移策略 | |
| | | - 新增 §15 网络层规范（预留云同步/AI 服务） | |

---

> 💡 **持续改进**：本指南随项目发展持续更新。如有建议，请创建 Issue 或在 PR 中讨论。
>
> 🏆 **目标**：通过严格的代码审查流程，打造符合 Apple Design Awards 标准的优质教育应用。
