# Swift 6.2 / iOS 26 最佳实践标准

> 本文档整理了 Apple 官方推荐的 Swift 6.2 和 iOS 26 开发最佳实践，适用于 NotBad 项目及其他 iOS 应用开发。

## 目录

- [一、并发安全标准](#一并发安全标准-concurrency-safety)
- [二、协议遵循标准](#二协议遵循标准-protocol-conformance)
- [三、文档标准](#三文档标准-documentation)
- [四、代码组织标准](#四代码组织标准-code-organization)
- [五、值对象设计标准](#五值对象设计标准-value-object-design)
- [六、SwiftUI 标准](#六swiftui-标准)
- [七、SwiftData 标准](#七swiftdata-标准)
- [八、测试标准](#八测试标准-testing)
- [九、架构标准](#九架构标准-architecture)
- [十、性能标准](#十性能标准-performance)
- [十一、错误处理标准](#十一错误处理标准-error-handling)
- [十二、资源管理标准](#十二资源管理标准-resource-management)
- [十三、设计系统标准](#十三设计系统标准-design-system) ⭐ 新增
- [十四、调试与发布标准](#十四调试与发布标准-debug--release) ⭐ 新增
- [十五、无障碍标准](#十五无障碍标准-accessibility) ⭐ 新增
- [十六、本地化标准](#十六本地化标准-localization) ⭐ 新增
- [速查表](#速查表)

---

## 一、并发安全标准 (Concurrency Safety)

Swift 6 引入了严格的并发检查，确保代码在多线程环境下的安全性。

### 1. Sendable 遵循

所有值对象必须遵循 `Sendable` 协议，确保可安全跨并发域传递。

```swift
// ✅ 正确
struct Difficulty: Sendable, CaseIterable, Codable, Hashable, Identifiable {
    // ...
}

// ❌ 错误 - 缺少 Sendable
struct Difficulty: CaseIterable, Codable, Hashable, Identifiable {
    // ...
}
```

### 2. nonisolated 计算属性

值类型的计算属性标记 `nonisolated`，明确表示不需要 actor 隔离。

```swift
struct KnowledgePoints: Sendable {
    let items: [String]
    
    // ✅ 正确
    nonisolated var count: Int { items.count }
    nonisolated var isEmpty: Bool { items.isEmpty }
    
    // ❌ 错误 - 缺少 nonisolated 可能导致并发警告
    var count: Int { items.count }
}
```

### 3. @MainActor 标注

UI 相关类型（ViewModel、View）使用 `@MainActor` 确保主线程执行。

```swift
// ✅ 正确
@MainActor
@Observable
final class DashboardViewModel {
    var items: [ReviewItem] = []
    
    func loadData() {
        // 自动在主线程执行
    }
}
```

### 4. Actor 隔离

需要状态隔离的类型使用 `actor` 而非 `class`。

```swift
// ✅ 适用于需要线程安全的共享状态
actor DataCache {
    private var cache: [String: Data] = [:]
    
    func get(_ key: String) -> Data? {
        cache[key]
    }
    
    func set(_ key: String, data: Data) {
        cache[key] = data
    }
}
```

### 5. async/await 优先

异步操作优先使用 `async/await` 而非回调或 Combine。

```swift
// ✅ 正确 - 使用 async/await
func fetchItems() async throws -> [ReviewItem] {
    let data = try await networkService.fetch()
    return try decoder.decode([ReviewItem].self, from: data)
}

// ❌ 避免 - 回调地狱
func fetchItems(completion: @escaping (Result<[ReviewItem], Error>) -> Void) {
    networkService.fetch { result in
        // ...
    }
}
```

### 6. Task 结构化并发

使用 `Task`、`TaskGroup` 进行结构化并发管理。

```swift
// ✅ 正确 - 结构化并发
func loadAllData() async {
    async let items = fetchItems()
    async let stats = fetchStatistics()
    
    let (itemsResult, statsResult) = await (items, stats)
    // 处理结果
}
```

---

## 二、协议遵循标准 (Protocol Conformance)

### 7. 统一协议顺序

遵循固定的协议声明顺序，便于代码审查和维护。

```
Sendable → CaseIterable → Codable → Hashable → Identifiable
```

**记忆口诀**：`"Send Case Code Hash ID"`

```swift
// ✅ 正确顺序
enum Difficulty: Int, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    case easy = 0
    case medium = 1
    case hard = 2
    
    nonisolated var id: Int { rawValue }
}
```

### 8. Equatable 自动合成

优先使用编译器自动合成，避免手动实现。

```swift
// ✅ 正确 - 编译器自动合成
struct Point: Equatable {
    let x: Double
    let y: Double
    // 编译器自动生成 == 实现
}

// ❌ 避免 - 除非有特殊需求
struct Point: Equatable {
    let x: Double
    let y: Double
    
    static func == (lhs: Point, rhs: Point) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y  // 不必要的手动实现
    }
}
```

### 9. Comparable 实现

需要排序的类型实现 `Comparable`。

```swift
extension Difficulty: Comparable {
    nonisolated static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// 使用
let sorted = difficulties.sorted()  // 自动按 rawValue 排序
```

### 10. CustomStringConvertible

提供有意义的调试描述。

```swift
extension ReviewItem: CustomStringConvertible {
    var description: String {
        "ReviewItem(\(displayTitle), \(subject.displayName), \(mastery.displayName))"
    }
}
```

---

## 三、文档标准 (Documentation)

### 11. DocC 格式注释

使用 `///` 和 DocC 标记语法。

```swift
/// 题目难度等级（5级制）
///
/// 表示题目的难度等级，从基础到压轴共5个级别。
/// 用于帮助学生识别题目难度，合理分配复习时间。
///
/// ## 难度等级
/// - ``basic``: 送分题 - 基础概念直接应用
/// - ``easy``: 简单题 - 常规题型
/// - ``medium``: 中等题 - 需要分析思考
/// - ``hard``: 困难题 - 综合性强
/// - ``extreme``: 压轴题 - 极具挑战性
enum Difficulty: Int, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    // ...
}
```

### 12. 代码示例

文档中包含可执行的代码示例。

```swift
/// 创建知识点集合
///
/// ## 使用示例
///
/// ```swift
/// // 从数组创建
/// let points: KnowledgePoints = ["函数", "导数", "极限"]
///
/// // 添加知识点（返回新实例）
/// let newPoints = points.adding("积分")
///
/// // 从字符串创建
/// let fromString = KnowledgePoints(from: "函数, 导数, 极限")
/// ```
struct KnowledgePoints {
    // ...
}
```

### 13. 参数和返回值说明

使用 `- Parameter:` 和 `- Returns:` 标记。

```swift
/// 根据复习历史计算间隔
///
/// - Parameters:
///   - reviewCount: 已完成的复习次数
///   - mastery: 当前掌握程度
/// - Returns: 计算后的复习间隔实例
nonisolated static func calculate(
    reviewCount: Int,
    mastery: MasteryLevel
) -> ReviewInterval {
    // ...
}
```

### 14. 符号链接

使用双反引号链接相关符号。

```swift
/// 掌握程度
///
/// 影响 ``ReviewInterval`` 的计算：
/// - 掌握程度越高，间隔越长
/// - 参见 ``MasteryLevel/stabilityFactor``
let mastery: MasteryLevel
```

### 15. Note/Important/Warning

使用标记突出重要信息。

```swift
/// 删除所有错题
///
/// - Warning: 此操作不可逆
/// - Note: 建议在删除前进行备份
/// - Important: 需要用户二次确认
func deleteAll() throws {
    // ...
}
```

---

## 四、代码组织标准 (Code Organization)

### 16. MARK 分组

使用 `// MARK: -` 分隔代码段。

```swift
// MARK: - Properties

let id: UUID
let title: String

// MARK: - Initialization

init(id: UUID = UUID(), title: String) {
    self.id = id
    self.title = title
}

// MARK: - Public Methods

func update(title: String) { }

// MARK: - Private Methods

private func validate() { }
```

### 17. 扩展分离

按职责将功能分离到不同 `extension`。

```swift
// MARK: - Difficulty Core

enum Difficulty: Int, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    case basic, easy, medium, hard, extreme
}

// MARK: - Difficulty Display Properties

extension Difficulty {
    nonisolated var displayName: String { ... }
    nonisolated var icon: String { ... }
    nonisolated var color: Color { ... }
}

// MARK: - Difficulty Calculation Properties

extension Difficulty {
    nonisolated var coefficient: Double { ... }
    nonisolated var reviewPriority: Int { ... }
}

// MARK: - Difficulty Comparable

extension Difficulty: Comparable {
    nonisolated static func < (lhs: Difficulty, rhs: Difficulty) -> Bool { ... }
}
```

### 18. 文件命名

文件名与主类型名一致。

```
✅ Difficulty.swift      → enum Difficulty
✅ ReviewItem.swift      → class ReviewItem
✅ KnowledgePoints.swift → struct KnowledgePoints

❌ DifficultyEnum.swift
❌ ReviewItemModel.swift
```

### 19. 访问控制

合理使用访问控制修饰符。

```swift
// 对外公开的 API
public struct KnowledgePoints {
    // 只读属性
    public let items: [String]
    
    // 内部使用
    internal func validate() { }
    
    // 私有实现
    private func normalize(_ point: String) -> String { }
}
```

---

## 五、值对象设计标准 (Value Object Design)

### 20. 不可变性

值对象属性使用 `let`，修改返回新实例。

```swift
struct KnowledgePoints: Sendable {
    // ✅ 不可变
    let items: [String]
    
    // ✅ 修改返回新实例
    nonisolated func adding(_ point: String) -> KnowledgePoints {
        KnowledgePoints(items + [point])
    }
    
    // ❌ 错误 - 可变状态
    // var items: [String]
    // mutating func add(_ point: String) { items.append(point) }
}
```

### 21. 工厂方法

提供便捷的静态工厂方法。

```swift
extension ReviewInterval {
    /// 首次复习间隔
    nonisolated static func firstReview(mastery: MasteryLevel) -> ReviewInterval {
        ReviewInterval(reviewCount: 0, mastery: mastery, baseDate: Date())
    }
    
    /// 从上次复习创建下次间隔
    nonisolated static func next(from previous: ReviewInterval, newMastery: MasteryLevel) -> ReviewInterval {
        ReviewInterval(
            reviewCount: previous.reviewCount + 1,
            mastery: newMastery,
            baseDate: Date()
        )
    }
}
```

### 22. 空值常量

提供 `.empty` 或 `.default` 静态常量。

```swift
struct KnowledgePoints {
    let items: [String]
    
    /// 空知识点集合
    static let empty = KnowledgePoints([])
}

struct ReviewStatistics {
    // ...
    
    /// 空统计数据
    static let empty = ReviewStatistics(
        totalCount: 0,
        masteredCount: 0,
        // ...
    )
}
```

### 23. rawValue 存储

复杂类型通过 `rawValue` 形式与持久化层交互。

```swift
// SwiftData 模型
@Model
final class ReviewItem {
    // 存储原始值
    var subjectRaw: String
    var difficultyRaw: Int
    
    // 类型安全访问器
    var subject: Subject {
        get { Subject(rawValue: subjectRaw) ?? .other }
        set { subjectRaw = newValue.rawValue }
    }
    
    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .medium }
        set { difficultyRaw = newValue.rawValue }
    }
}
```

---

## 六、SwiftUI 标准

### 24. @Observable 宏

使用 `@Observable` 宏（非 `ObservableObject` 协议）实现状态观察。

```swift
// ✅ 推荐 - @Observable 宏
@MainActor
@Observable
final class DashboardViewModel {
    var items: [ReviewItem] = []      // 自动追踪变化
    var isLoading = false             // 无需 @Published
}

// ❌ 已淘汰 - ObservableObject 协议
class DashboardViewModel: ObservableObject {
    @Published var items: [ReviewItem] = []
    @Published var isLoading = false
}
```

**`@Observable` 优势：**
- 更精细的属性级别追踪（非整体对象）
- 更少的内存开销和更高的性能
- 无需 `@Published`，代码更简洁
- 与 Swift 6 并发模型完美配合

### 25. View 组合

拆分大型 View 为小组件。

```swift
struct LibraryView: View {
    var body: some View {
        NavigationStack {
            VStack {
                FilterBar()      // 抽取为独立组件
                ItemList()       // 抽取为独立组件
            }
        }
    }
}

// 独立组件
private struct FilterBar: View {
    var body: some View { /* ... */ }
}

private struct ItemList: View {
    var body: some View { /* ... */ }
}
```

### 26. 环境对象

使用 `@Environment` 传递跨层依赖。

```swift
// 定义环境键
struct RepositoryKey: EnvironmentKey {
    static let defaultValue: ReviewItemRepositoryProtocol = ReviewItemRepository()
}

extension EnvironmentValues {
    var repository: ReviewItemRepositoryProtocol {
        get { self[RepositoryKey.self] }
        set { self[RepositoryKey.self] = newValue }
    }
}

// 使用
struct ContentView: View {
    @Environment(\.repository) private var repository
}
```

### 27. Preview Provider

为组件提供预览。

```swift
#Preview("默认状态") {
    MasteryBadge(level: .partial)
}

#Preview("已掌握") {
    MasteryBadge(level: .mastered)
}

#Preview("深色模式") {
    MasteryBadge(level: .none)
        .preferredColorScheme(.dark)
}
```

---

## 七、SwiftData 标准

### 28. @Model 宏

使用 `@Model` 定义持久化实体。

```swift
@Model
final class ReviewItem {
    var id: UUID
    var title: String
    var createdAt: Date
    
    @Attribute(.externalStorage)
    var imageData: Data?
    
    init(id: UUID = UUID(), title: String) {
        self.id = id
        self.title = title
        self.createdAt = Date()
    }
}
```

### 29. 值对象桥接

通过 rawValue 存储枚举和值对象。

```swift
@Model
final class ReviewItem {
    // 存储层 - 原始类型
    var subjectRaw: String
    var gradeRaw: String
    var difficultyRaw: Int
    
    // 业务层 - 值对象访问器
    var subject: Subject {
        get { Subject(rawValue: subjectRaw) ?? .other }
        set { subjectRaw = newValue.rawValue }
    }
}
```

### 30. 访问器模式

提供类型安全的计算属性访问器。

```swift
extension ReviewItem {
    /// 学科（类型安全访问）
    var subject: Subject {
        get { Subject(rawValue: subjectRaw) ?? .other }
        set {
            subjectRaw = newValue.rawValue
            markAsUpdated()
        }
    }
    
    private func markAsUpdated() {
        updatedAt = Date()
    }
}
```

### 31. Repository 模式

使用仓库模式封装数据访问。

```swift
@MainActor
protocol ReviewItemRepositoryProtocol: AnyObject, Sendable {
    func fetchAll() -> [ReviewItem]
    func fetch(subject: Subject?, mastery: MasteryLevel?) -> [ReviewItem]
    func save(_ item: ReviewItem) throws
    func delete(_ item: ReviewItem) throws
}

@MainActor
final class ReviewItemRepository: ReviewItemRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchAll() -> [ReviewItem] {
        let descriptor = FetchDescriptor<ReviewItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
```

---

## 八、测试标准 (Testing)

### 32. Swift Testing 框架

使用 `@Test`、`@Suite`、`#expect` 替代 XCTest。

```swift
import Testing
@testable import NotBad

@Suite("Difficulty 测试")
struct DifficultyTests {
    
    @Test("难度等级数量正确")
    func difficultyCount() {
        #expect(Difficulty.allCases.count == 5)
    }
    
    @Test("系数范围正确", arguments: Difficulty.allCases)
    func coefficientRange(difficulty: Difficulty) {
        #expect(difficulty.coefficient >= 0.0)
        #expect(difficulty.coefficient <= 1.0)
    }
}
```

### 33. 中文测试名

测试名使用中文便于理解。

```swift
@Test("空知识点集合 isEmpty 返回 true")
func emptyKnowledgePointsIsEmpty() {
    let points = KnowledgePoints.empty
    #expect(points.isEmpty)
}

@Test("添加知识点返回新实例")
func addingReturnsNewInstance() {
    let original: KnowledgePoints = ["函数"]
    let modified = original.adding("导数")
    
    #expect(original.count == 1)
    #expect(modified.count == 2)
}
```

### 34. 边界测试

测试空值、极值、无效输入。

```swift
@Suite("边界条件测试")
struct BoundaryTests {
    
    @Test("空字符串知识点被过滤")
    func emptyStringFiltered() {
        let points = KnowledgePoints(["", "  ", "函数"])
        #expect(points.count == 1)
    }
    
    @Test("负数复习次数处理")
    func negativeReviewCount() {
        let interval = ReviewInterval.calculate(reviewCount: -1, mastery: .none)
        #expect(interval.intervalDays >= 1)
    }
    
    @Test("nil 学科筛选返回全部")
    func nilSubjectFilter() {
        let result = repository.fetch(subject: nil, mastery: nil)
        #expect(result.count == allItems.count)
    }
}
```

### 35. Mock 依赖

使用协议和依赖注入便于 Mock。

```swift
// 协议定义
protocol ReviewItemRepositoryProtocol {
    func fetchAll() -> [ReviewItem]
}

// Mock 实现
final class MockRepository: ReviewItemRepositoryProtocol {
    var mockItems: [ReviewItem] = []
    
    func fetchAll() -> [ReviewItem] {
        mockItems
    }
}

// 测试中使用
@Test("ViewModel 加载数据")
func viewModelLoadsData() {
    let mock = MockRepository()
    mock.mockItems = [ReviewItem(title: "测试题")]
    
    let viewModel = DashboardViewModel(repository: mock)
    viewModel.loadData()
    
    #expect(viewModel.items.count == 1)
}
```

---

## 九、架构标准 (Architecture)

### 36. 依赖倒置

上层模块依赖抽象协议，而非具体实现。

```swift
// ✅ 正确 - 依赖抽象
class ReviewViewModel {
    private let repository: ReviewItemRepositoryProtocol  // 协议
    
    init(repository: ReviewItemRepositoryProtocol) {
        self.repository = repository
    }
}

// ❌ 错误 - 依赖具体实现
class ReviewViewModel {
    private let repository: ReviewItemRepository  // 具体类
}
```

### 37. 单一职责

每个类型只负责一个职责。

```swift
// ✅ 正确 - 职责分离
struct ReviewStatistics { }      // 只负责统计数据
struct ReviewInterval { }        // 只负责间隔计算
class ReviewItemRepository { }   // 只负责数据访问
class ReviewViewModel { }        // 只负责视图逻辑

// ❌ 错误 - 职责混合
class ReviewManager {
    func calculateStatistics() { }
    func calculateInterval() { }
    func saveToDatabase() { }
    func updateUI() { }
}
```

### 38. MVVM 模式

View ↔ ViewModel ↔ Model 分层。

```
┌─────────────────────────────────────────────────────────┐
│                        View                             │
│  ReviewView.swift, DashboardView.swift                  │
│  - 只负责 UI 渲染                                        │
│  - 绑定 ViewModel 状态                                   │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│                     ViewModel                           │
│  ReviewViewModel.swift, DashboardViewModel.swift        │
│  - 处理业务逻辑                                          │
│  - 管理状态                                              │
│  - 调用 Repository                                       │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│                       Model                             │
│  ReviewItem.swift, Subject.swift                        │
│  - 数据实体                                              │
│  - 值对象                                                │
└─────────────────────────────────────────────────────────┘
```

### 39. Clean Architecture

分层：Domain → Data → Presentation。

```
NotBad/
├── Domain/                    # 领域层 - 核心业务逻辑
│   ├── Entities/              # 实体
│   │   └── ReviewItem.swift
│   ├── ValueObjects/          # 值对象
│   │   ├── Difficulty.swift
│   │   └── Subject.swift
│   └── Protocols/             # 协议定义
│       └── ReviewItemRepositoryProtocol.swift
│
├── Data/                      # 数据层 - 数据访问
│   └── Repository/
│       └── ReviewItemRepository.swift
│
└── Presentation/              # 展示层 - UI
    ├── Features/
    │   ├── Dashboard/
    │   │   ├── DashboardView.swift
    │   │   └── DashboardViewModel.swift
    │   └── Review/
    │       ├── ReviewView.swift
    │       └── ReviewViewModel.swift
    └── Common/
        └── Components/
            └── MasteryBadge.swift
```

---

## 十、性能标准 (Performance)

### 40. @Attribute(.externalStorage)

大数据使用外部存储。

```swift
@Model
final class ReviewItem {
    // ✅ 图片数据使用外部存储
    @Attribute(.externalStorage)
    var imageData: Data?
    
    // ❌ 大数据直接存储会影响性能
    // var imageData: Data?
}
```

### 41. 惰性加载

大集合使用 `lazy` 避免立即计算。

```swift
struct LibraryViewModel {
    let allItems: [ReviewItem]
    
    // ✅ 惰性计算
    lazy var mathItems: [ReviewItem] = {
        allItems.filter { $0.subject == .math }
    }()
    
    // ✅ 或使用计算属性 + 缓存
    private var _mathItemsCache: [ReviewItem]?
    var mathItems: [ReviewItem] {
        if let cached = _mathItemsCache { return cached }
        let result = allItems.filter { $0.subject == .math }
        _mathItemsCache = result
        return result
    }
}
```

### 42. 缓存策略

频繁访问的计算结果适当缓存。

```swift
@Observable
final class DashboardViewModel {
    private var _statisticsCache: ReviewStatistics?
    private var _lastCacheTime: Date?
    
    var statistics: ReviewStatistics {
        // 5秒内使用缓存
        if let cache = _statisticsCache,
           let time = _lastCacheTime,
           Date().timeIntervalSince(time) < 5 {
            return cache
        }
        
        let stats = calculateStatistics()
        _statisticsCache = stats
        _lastCacheTime = Date()
        return stats
    }
}
```

---

## 十一、错误处理标准 (Error Handling)

### 43. 统一错误定义

使用枚举定义领域错误，遵循 `LocalizedError`，确保错误信息对用户友好。

```swift
enum AppError: LocalizedError, Equatable {
    case network(String)
    case database(String)
    case validation(String)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .network(let msg): return "网络连接异常: \(msg)"
        case .database(let msg): return "数据存储失败: \(msg)"
        case .validation(let msg): return "数据校验未通过: \(msg)"
        case .unknown(let error): return "未知错误: \(error.localizedDescription)"
        }
    }
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        lhs.errorDescription == rhs.errorDescription
    }
}
```

### 44. 错误传播与处理

ViewModel 层负责捕获错误并转换为 UI 状态，避免将 `do-catch` 散落在 View 中。

```swift
@MainActor
@Observable
final class ReviewViewModel {
    var error: AppError?
    var showError = false
    
    func save() async {
        do {
            try await repository.save(currentItem)
        } catch let appError as AppError {
            self.error = appError
            self.showError = true
        } catch {
            self.error = .unknown(error)
            self.showError = true
        }
    }
}
```

---

## 十二、资源管理标准 (Resource Management)

### 45. 图片优化策略

错题本应用涉及大量图片，必须在采集端进行压缩。

```swift
extension UIImage {
    /// 优化错题图片（HEIC 格式，限制分辨率）
    nonisolated func optimizedForStorage() -> Data? {
        // 1. 调整尺寸（限制最大边长 2048）
        // let resized = self.downsampling(...) 
        
        // 2. 优先使用 HEIC (iOS 11+)
        // 压缩质量 0.7 在体积和画质间取得平衡
        if let heicData = self.heicData(compressionQuality: 0.7) {
            return heicData
        }
        
        // 3. 降级使用 JPEG
        return self.jpegData(compressionQuality: 0.7)
    }
}
```

### 46. 缓存清理机制

建立自动清理机制，防止应用体积无限膨胀。

```swift
actor CacheManager {
    /// 清理过期临时文件
    func cleanExpiredCache(expirationDays: Int = 7) {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        
        // 获取过期时间阈值
        guard let threshold = Calendar.current.date(
            byAdding: .day, 
            value: -expirationDays, 
            to: Date()
        ) else { return }
        
        // 遍历并删除过期文件
        // ... implementation
    }
}
```

---

## 十三、设计系统标准 (Design System)

建立统一的设计系统，消除硬编码样式，提升一致性和可维护性。

### 47. 设计令牌 (Design Tokens)

将所有设计值抽象为令牌，禁止在视图中硬编码数值。

```swift
// ✅ 正确 - 使用设计令牌
enum DesignTokens {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let full: CGFloat = 9999
    }
    
    enum Animation {
        static let quick: Double = 0.2
        static let normal: Double = 0.3
        static let slow: Double = 0.5
    }
}

// ✅ 在视图中使用
.padding(DesignTokens.Spacing.md)
.cornerRadius(DesignTokens.CornerRadius.medium)

// ❌ 错误 - 硬编码数值
.padding(16)
.cornerRadius(12)
```

### 48. 品牌色系 (Brand Colors)

通过 Asset Catalog + 扩展提供语义化颜色。

```swift
// Assets.xcassets/Colors/ 结构：
// ├── BrandPrimary.colorset/   (橙色 #FF9500)
// ├── BrandSecondary.colorset/ (蓝色 #007AFF)
// ├── BrandSuccess.colorset/   (绿色 #34C759)
// ├── BrandWarning.colorset/   (黄色 #FFCC00)
// └── BrandError.colorset/     (红色 #FF3B30)

// 扩展提供便捷访问
extension Color {
    enum brand {
        static let primary = Color("BrandPrimary")
        static let secondary = Color("BrandSecondary")
        static let success = Color("BrandSuccess")
        static let warning = Color("BrandWarning")
        static let error = Color("BrandError")
    }
}

// ✅ 使用语义化颜色
Text("成功").foregroundStyle(Color.brand.success)

// ❌ 避免硬编码颜色
Text("成功").foregroundStyle(Color(red: 0.2, green: 0.78, blue: 0.35))
```

### 49. 统一按钮样式

定义可复用的 ButtonStyle，确保交互一致性。

```swift
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(Color.brand.primary)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primaryAction: PrimaryButtonStyle { PrimaryButtonStyle() }
}

// ✅ 使用
Button("保存") { save() }
    .buttonStyle(.primaryAction)
```

### 50. 卡片样式系统

统一卡片视觉风格。

```swift
struct StandardCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(DesignTokens.Spacing.md)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
    }
}

extension View {
    func cardStyle(_ style: CardStyleType = .standard) -> some View {
        modifier(StandardCardStyle())
    }
}

// ✅ 使用
VStack { ... }
    .cardStyle()
```

---

## 十四、调试与发布标准 (Debug & Release)

### 51. 条件编译调试日志

所有调试日志必须包裹在 `#if DEBUG` 中，避免发布版本泄露信息。

```swift
// ✅ 正确 - 条件编译
func saveItem(_ item: ReviewItem) {
    #if DEBUG
    print("📝 [Repository] Saving item: \(item.id)")
    #endif
    
    modelContext.insert(item)
    try? modelContext.save()
    
    #if DEBUG
    print("✅ [Repository] Save completed")
    #endif
}

// ❌ 错误 - 无条件 print
func saveItem(_ item: ReviewItem) {
    print("Saving item: \(item.id)")  // 发布版本会泄露
    modelContext.insert(item)
}
```

### 52. 调试日志规范

使用 emoji 前缀区分日志类型，便于过滤。

```swift
#if DEBUG
// 信息日志
print("📚 [LibraryView] Loaded \(items.count) items")

// 成功日志
print("✅ [Repository] Save completed")

// 警告日志
print("⚠️ [ViewModel] Cache expired, refreshing...")

// 错误日志
print("❌ [Network] Request failed: \(error)")

// 调试日志
print("🔍 [Debug] Current state: \(state)")
#endif
```

### 53. 敏感信息保护

永远不要在日志中打印敏感信息。

```swift
// ❌ 错误 - 暴露敏感信息
print("User token: \(userToken)")
print("Image data: \(imageData)")

// ✅ 正确 - 只打印元数据
#if DEBUG
print("🔐 [Auth] Token received, length: \(userToken.count)")
print("🖼️ [Image] Data size: \(imageData.count) bytes")
#endif
```

---

## 十五、无障碍标准 (Accessibility)

遵循 Apple Human Interface Guidelines (HIG) 无障碍设计原则。

### 54. VoiceOver 标签

为所有交互元素提供有意义的无障碍标签。

```swift
Button(action: save) {
    Image(systemName: "checkmark")
}
.accessibilityLabel("保存")
.accessibilityHint("保存当前编辑的错题")

// 复合元素
HStack {
    Image(systemName: "star.fill")
    Text("困难")
}
.accessibilityElement(children: .combine)
.accessibilityLabel("难度：困难")
```

### 55. 动态字体支持

支持用户自定义字体大小。

```swift
// ✅ 使用系统动态字体
Text("标题")
    .font(.headline)  // 自动响应动态字体

// ✅ 自定义字体也要支持
Text("内容")
    .font(.system(size: 16, weight: .regular, design: .rounded))
    .dynamicTypeSize(...DynamicTypeSize.accessibility3)  // 限制最大尺寸
```

### 56. 减少动画适配

尊重用户的"减少动画"设置。

```swift
struct AnimatedView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        Image(systemName: "star")
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(
                reduceMotion ? nil : .linear(duration: 2).repeatForever(autoreverses: false),
                value: isAnimating
            )
    }
}
```

### 57. 触觉反馈

为重要操作提供触觉反馈。

```swift
// 定义触觉管理器
@MainActor
final class HapticManager {
    static let shared = HapticManager()
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

// 使用
Button("删除") {
    HapticManager.shared.notification(.warning)
    delete()
}
```

---

## 十六、本地化标准 (Localization)

### 58. 集中管理本地化键

将所有 UI 文案集中在本地化键文件中。

```swift
enum L10n {
    enum Common {
        static let ok = String(localized: "common_ok", defaultValue: "确定")
        static let cancel = String(localized: "common_cancel", defaultValue: "取消")
        static let save = String(localized: "common_save", defaultValue: "保存")
    }
    
    enum Dashboard {
        static let title = String(localized: "dashboard_title", defaultValue: "首页")
        static let pendingReview = String(localized: "dashboard_pending", defaultValue: "待复习")
    }
}

// ✅ 使用
Text(L10n.Dashboard.title)

// ❌ 避免硬编码
Text("首页")
```

### 59. 格式化字符串

数字、日期等使用格式化方法。

```swift
extension L10n {
    static func itemCount(_ count: Int) -> String {
        "\(count) 道"
    }
    
    static func percentage(_ value: Double) -> String {
        "\(Int(value * 100))%"
    }
}

// 使用
Text(L10n.itemCount(items.count))
Text(L10n.percentage(masteryRate))
```

---

## 速查表

### 🔐 并发安全三件套

```swift
// 1. 值对象 → Sendable
struct MyValue: Sendable { }

// 2. 计算属性 → nonisolated
nonisolated var computed: Int { rawValue }

// 3. ViewModel → @MainActor + @Observable
@MainActor
@Observable
final class MyViewModel { }
```

### 📚 协议遵循顺序

```
"Send Case Code Hash ID"

Sendable → CaseIterable → Codable → Hashable → Identifiable
```

```swift
enum MyEnum: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    case a, b, c
    nonisolated var id: String { rawValue }
}
```

### 📝 文档三要素

```swift
/// 简短描述
///
/// 详细说明
///
/// ## 使用示例
/// ```swift
/// let example = MyType()
/// ```
///
/// - Parameter name: 参数说明
/// - Returns: 返回值说明
/// - Note: 备注信息
```

### 🏗️ 代码组织四原则

```swift
// MARK: - Properties       // 1. MARK 分组
extension MyType { }        // 2. 扩展分职责
// MyType.swift             // 3. 文件名 = 类型名
private func helper() { }   // 4. 最小化访问权限
```

### 🧪 测试四要求

```swift
import Testing

@Suite("中文套件名")           // 1. Swift Testing
struct MyTests {
    @Test("中文测试名")        // 2. 中文命名
    func testBoundary() {     // 3. 边界条件
        let mock = MockDep()  // 4. Mock 依赖
        #expect(result == expected)
    }
}
```

### 🎨 设计系统四层次

```swift
// 1. 设计令牌 - 基础数值
DesignTokens.Spacing.md       // 16pt
DesignTokens.CornerRadius.medium  // 12pt

// 2. 品牌色系 - 语义颜色
Color.brand.primary           // 橙色
Color.brand.success           // 绿色

// 3. 组件样式 - 可复用修饰器
.buttonStyle(.primaryAction)
.cardStyle(.elevated)

// 4. 主题适配 - 深色模式自动
// Asset Catalog 配置 Any/Dark
```

### 🔒 调试日志三原则

```swift
// 1. 条件编译
#if DEBUG
print("...")
#endif

// 2. emoji 分类
// 📚 信息  ✅ 成功  ⚠️ 警告  ❌ 错误  🔍 调试

// 3. 不暴露敏感信息
// ❌ print(token)
// ✅ print("Token length: \(token.count)")
```

### ♿ 无障碍三要素

```swift
// 1. VoiceOver 标签
.accessibilityLabel("保存")
.accessibilityHint("保存当前错题")

// 2. 动态字体
.font(.headline)  // 系统字体自动适配

// 3. 减少动画适配
@Environment(\.accessibilityReduceMotion) var reduceMotion
```

---

## 审计检查清单

开发完成后，使用此清单进行代码审计：

### 并发安全 ✓
- [ ] 所有值对象遵循 `Sendable`
- [ ] 计算属性标记 `nonisolated`
- [ ] ViewModel 使用 `@MainActor` + `@Observable`
- [ ] 异步操作使用 `async/await`

### 代码质量 ✓
- [ ] 协议顺序：Send Case Code Hash ID
- [ ] 使用 DocC 格式注释
- [ ] MARK 分组清晰
- [ ] 访问控制合理

### 设计系统 ✓
- [ ] 无硬编码数值（间距、圆角、颜色）
- [ ] 使用 DesignTokens 令牌
- [ ] 使用 Color.brand 品牌色
- [ ] 统一按钮/卡片样式

### 调试与发布 ✓
- [ ] 所有 print 包裹 `#if DEBUG`
- [ ] 无敏感信息泄露
- [ ] 使用 emoji 分类日志

### 无障碍 ✓
- [ ] 交互元素有 accessibilityLabel
- [ ] 支持动态字体
- [ ] 适配减少动画设置
- [ ] 提供触觉反馈

### 测试 ✓
- [ ] 使用 Swift Testing 框架
- [ ] 中文测试名
- [ ] 覆盖边界条件
- [ ] Mock 外部依赖

---

## 参考资源

- [Swift 官方文档](https://docs.swift.org/swift-book/)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Swift Evolution](https://github.com/apple/swift-evolution)
- [WWDC 2024 - Swift 6](https://developer.apple.com/wwdc24/)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Accessibility Programming Guide](https://developer.apple.com/accessibility/)

---

## 更新日志

### 2025-11-26
- ⭐ **新增** 十三、设计系统标准 (Design Tokens, Brand Colors, Button/Card Styles)
- ⭐ **新增** 十四、调试与发布标准 (#if DEBUG, 日志规范, 敏感信息保护)
- ⭐ **新增** 十五、无障碍标准 (VoiceOver, 动态字体, 减少动画, 触觉反馈)
- ⭐ **新增** 十六、本地化标准 (L10n 键管理, 格式化字符串)
- ⭐ **新增** 审计检查清单
- ⭐ **新增** 速查表：设计系统四层次、调试日志三原则、无障碍三要素

---

*最后更新：2025年11月26日*
*适用版本：Swift 6.2.1 / iOS 26.1 / Xcode 26.1.1*
