# SnapDrill 基础设施清单（API 权威参考）

> **使用规则**：修改任何代码前，先在此文件确认 API 真实存在。
> 不在此文件中的 API 必须先读源文件确认，或新建后再写入此文件。
> **不得凭名称推测方法存在**。

最后更新：2026-03-04（新增 SnapDrillInfrastructure 包，Firebase 实现迁出 Core）

---

## SnapDrillCore

### 通知（Notification）

```swift
// 文件：Support/ReviewDataNotification.swift
public extension Notification.Name {
    /// 题目数据写操作后 post
    static let reviewDataDidChange = Notification.Name("com.snapdrill.reviewDataDidChange")
    /// Tab 切换（2026-03-04，禁止使用裸字符串 NSNotification.Name("SwitchTo*Tab")）
    static let switchToCaptureTab  = Notification.Name("com.snapdrill.switchToCaptureTab")
    static let switchToLibraryTab  = Notification.Name("com.snapdrill.switchToLibraryTab")
    static let switchToSettingsTab = Notification.Name("com.snapdrill.switchToSettingsTab")
}

// 发送方式（唯一正确写法）：
NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
NotificationCenter.default.post(name: .switchToCaptureTab, object: nil)

// 监听方式（SwiftUI）：
.onReceive(NotificationCenter.default.publisher(for: .switchToCaptureTab)) { _ in ... }
```

### 日志

```swift
// 文件：Logger/SnapDrillLogger.swift
public struct SnapDrillLogger {
    public static let generic: Logger
    public static let ui: Logger
    public static let data: Logger
    public static let network: Logger
    public static let engine: Logger
    public static let capture: Logger
}
// 使用：SnapDrillLogger.generic.error("...")
// 禁止：print(...)
```

### SM-2 调度引擎

```swift
// ReviewScheduler（struct）
public struct ReviewScheduler {
    public init()
    public func scheduleNextReview(state: SM2State, rating: ReviewRating) -> SM2State
    public func intervalDescription(for rating: ReviewRating, from state: SM2State) -> String
}

// SM2State（struct，值类型，调度后返回新值，不原地修改）
public struct SM2State {
    public var easeFactor: Double
    public var interval: Int
    public var repetitions: Int
    public var nextReviewAt: Date?
    public var lastReviewedAt: Date?
    public init(easeFactor: Double = 2.5, interval: Int = 0, repetitions: Int = 0,
                nextReviewAt: Date? = nil, lastReviewedAt: Date? = nil)
}

// ReviewRating（enum）
public enum ReviewRating: Int {
    case again = 0
    case hard  = 2
    case good  = 3
    case easy  = 5
}

// Difficulty（enum, CaseIterable, Identifiable, Hashable）
public enum Difficulty: Int {
    case one = 1, two = 2, three = 3, four = 4, five = 5
    var id: Int { rawValue }
    var starCount: Int { rawValue }
}
```

### 协议

```swift
// PDFExportable（protocol）
public protocol PDFExportable {
    var content: String? { get }
    var imagePath: String? { get }
}

// NotificationServiceProtocol（@MainActor）
public protocol NotificationServiceProtocol {
    func requestPermission() async -> Bool
    func scheduleDaily(at hour: Int, minute: Int) async throws
    func cancelAll()
}

// ServiceContainer（protocol, @MainActor）
public protocol ServiceContainer {
    var analytics: AnalyticsServiceProtocol { get }
    var crashReporting: CrashReportingProtocol { get }
    var performanceMonitor: PerformanceMonitor { get }
    var networkMonitor: NetworkMonitor { get }
    var pdfExport: PDFExportService { get }
    var appConfig: AppConfiguration { get }
    var privacyConsent: PrivacyConsentService { get }
    var subscription: SubscriptionServiceProtocol { get }
    var notification: NotificationServiceProtocol { get }
}
```

### 其他核心类型

```swift
// ImageStorage（struct）— 文件路径：Capture/ImageStorage.swift
public struct ImageStorage {
    public init()
    public func saveImage(_ image: UIImage) async throws -> String
    public func loadImage(path: String) -> UIImage?
    public func deleteImage(path: String) async throws  // async 2026-03-06，Apple 文档要求文件 I/O 异步；文件不存在时静默跳过
}

// PDFExportService（final class）— 文件路径：Capture/PDFExportService.swift
public final class PDFExportService {
    public static let shared: PDFExportService
    public func createPDF(from items: [any PDFExportable],
                          imageProvider: @Sendable @escaping (String) -> UIImage?) async throws -> Data
}

// CaptureDraftService（@MainActor final class，单例）— 文件路径：Service/CaptureDraftService.swift
// #if canImport(UIKit) 保护（UIImage 依赖，macOS swift test 不可用）
@MainActor
public final class CaptureDraftService: CaptureDraftServiceProtocol {
    public static let shared: CaptureDraftService
    public var hasDraft: Bool { get }
    public func saveDraft(image: UIImage, content: String)
    public func loadDraft() -> CaptureDraftService.Draft?
    public func clearDraft()

    public struct Draft {
        public let image: UIImage
        public let content: String
        public let date: Date
    }
}

// CaptureDraftServiceProtocol — 文件路径：Service/CaptureDraftServiceProtocol.swift
@MainActor
public protocol CaptureDraftServiceProtocol {
    var hasDraft: Bool { get }
    func saveDraft(image: UIImage, content: String)
    func loadDraft() -> CaptureDraftService.Draft?
    func clearDraft()
}

// OCRServiceProtocol — 文件路径：Service/OCRServiceProtocol.swift
public protocol OCRServiceProtocol: Sendable {
    func recognizeText(from cgImage: CGImage) async throws -> String
}
```

---

## SnapDrillData

### ReviewItemModel（@Model）

```swift
// 全部存储属性
public var id: UUID
public var content: String?
public var imagePath: String?
public var createdAt: Date
public var lastReviewedAt: Date?
public var nextReviewAt: Date?
public var subjectRawValue: String   // 直接存学科字符串
public var sourceRawValue: String    // 直接存来源字符串
public var tags: [TagModel]?
public var answerText: String?
public var answerImagePath: String?
public var difficulty: Int           // Difficulty.rawValue
public var grade: String
public var easeFactor: Double
public var interval: Int
public var repetitions: Int

// 计算属性
public var subject: String { get set }  // 等价于 subjectRawValue
public var source: String { get set }   // 等价于 sourceRawValue
public var difficultyValue: Difficulty { get set }

// 方法
public func toExportSnapshot() -> ReviewExportSnapshot

// 主 init（所有参数均有默认值）
public init(id: UUID = UUID(), content: String? = nil, imagePath: String? = nil,
            createdAt: Date = Date(), lastReviewedAt: Date? = nil, nextReviewAt: Date? = nil,
            subject: String = "其他", source: String = "其他", tags: [TagModel]? = [],
            answerText: String? = nil, answerImagePath: String? = nil,
            difficulty: Int = 1, grade: String = "", easeFactor: Double = 2.5,
            interval: Int = 0, repetitions: Int = 0)
```

### ReviewRepository（@MainActor final class）

```swift
public init(modelContext: ModelContext)

// 计数
public func totalItemCount() throws -> Int
public func totalCount() throws -> Int          // 同上，别名
public func fetchDueCount() throws -> Int
public func fetchTodayCount() throws -> Int
public func fetchTodayReviewedCount() throws -> Int
public func countBySubject(name: String) throws -> Int
public func countBySource(name: String) throws -> Int
public func countByGrade(name: String) throws -> Int

// 查询（返回 @Model）
public func fetchDueModels() throws -> [ReviewItemModel]
public func fetchModel(by id: UUID) throws -> ReviewItemModel?
public func fetchModels(by ids: Set<UUID>) throws -> [ReviewItemModel]
public func fetchAllModels() throws -> [ReviewItemModel]
public func fetchFilteredModels(searchText: String, subjects: Set<String>,
                                tags: Set<String>, limit: Int, offset: Int) throws -> [ReviewItemModel]

// 写入
public func insertAndSave(_ model: ReviewItemModel) throws
public func saveContext() throws
public func rollbackContext()          // saveContext 失败时调用，回滚所有未持久化变更
public func delete(id: UUID) async throws  // async 2026-03-06，内部含文件 I/O
public func deleteAll() throws

// 级联更新
public func updateSubjectUsage(from oldName: String, to newName: String) throws
public func updateSourceUsage(from oldName: String, to newName: String) throws
public func updateGradeUsage(from oldName: String, to newName: String) throws
```

### SubjectRepository / SourceRepository / GradeRepository（@MainActor final class，结构相同）

```swift
public init(modelContext: ModelContext)
public func fetchAllModels() throws -> [SubjectModel / SourceModel / GradeModel]
public func fetchModel(byName name: String) throws -> SubjectModel? / SourceModel? / GradeModel?
public func insertAndSave(_ model: SubjectModel / ...) throws
public func saveContext() throws
public func delete(id: UUID) throws
public func deleteAll() throws
public func totalCount() throws -> Int
public func seedDefaultsIfNeeded()
```

### TagRepository（@MainActor final class）

```swift
public init(modelContext: ModelContext)
public func fetchAllModels() throws -> [TagModel]
public func fetchOrCreateModel(name: String, colorHex: String) throws -> TagModel
public func delete(id: UUID) throws
public func deleteAll() throws
```

### RepositoryContainer（@MainActor final class）

```swift
public let review: ReviewRepository
public let subject: SubjectRepository
public let source: SourceRepository
public let tag: TagRepository
public let grade: GradeRepository

public init(modelContext: ModelContext = PersistenceController.shared.container.mainContext)
public func deleteAllData() async throws  // async 2026-03-06，内部含文件 I/O
public func deleteAllTaxonomy() throws
```

### ReviewExportSnapshot（struct，Sendable，Identifiable，PDFExportable）

```swift
public let id: UUID
public let content: String?
public let imagePath: String?
public let subject: String
public let source: String
public let createdAt: Date
// 通过 ReviewItemModel.toExportSnapshot() 创建，不直接 init
```

### DataSeeder（@MainActor final class）

```swift
public init(modelContext: ModelContext)
public func seedReviewItems(count: Int) throws -> TimeInterval
// 注意：count 参数控制生成数量，但实际使用内部 mockData 集合
// 完成后自动 post: NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
public func clearAll() throws
// 完成后自动 post: NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
```

---

## SnapDrillUI（公开组件）

```swift
// SnapDrillButton
struct SnapDrillButton: View {
    init(title: String, action: @escaping () -> Void)
}

// FlipView（泛型）
struct FlipView<Front: View, Back: View>: View {
    init(isFlipped: Bool,
         @ViewBuilder front: @escaping () -> Front,
         @ViewBuilder back: @escaping () -> Back)
}

// TagInputView
struct TagInputView: View {
    init(tags: Binding<[String]>, text: Binding<String>, suggestions: [String] = [])
}

// ImageCropperView（iOS only，UIViewControllerRepresentable）
public struct ImageCropperView: UIViewControllerRepresentable {
    public init(originalImage: UIImage, onCrop: @escaping (UIImage) -> Void,
                onCancel: @escaping () -> Void)
}

// Routable（protocol，所有 Router 遵循）
public protocol Routable: AnyObject, Observable {
    associatedtype Destination: Hashable
    var path: NavigationPath { get set }
    func push(_ destination: Destination)
    func pop()
    func popToRoot()
}

// TabItem（enum）
public enum TabItem: Hashable, CaseIterable {
    case dashboard, library, capture, review, settings
    var title: String { get }
    var iconName: String { get }
}
```

---

## SnapDrillFeatures（Environment 与 ViewModel）

### @Environment 键

```swift
// 唯一的依赖注入入口（RepositoryContainer+Environment.swift）
@Environment(\.repositories) var repositories: RepositoryContainer

// Services 通过 ServiceContainer 协议注入（具体 key 见 ServiceContainer+Environment.swift）
@Environment(\.services) var services: any ServiceContainer
```

### ViewModel init 签名（完整）

```swift
// ReviewViewModel
init(repository: ReviewRepository)

// LibraryViewModel
public init(repositories: RepositoryContainer)

// DashboardViewModel
public init(repositories: RepositoryContainer,
            draftService: CaptureDraftServiceProtocol = CaptureDraftService.shared)

// CaptureViewModel
public init(ocrService: OCRServiceProtocol = OCRService())

// CaptureResultViewModel
public init(content: String, image: UIImage?, repositories: RepositoryContainer,
            ocrService: OCRServiceProtocol, analyticsService: AnalyticsServiceProtocol,
            imageStorage: ImageStorage = ImageStorage(), router: CaptureRouter)

// LibraryEditViewModel
public init(item: ReviewItemModel, repositories: RepositoryContainer)

// SettingsViewModel
public init(repositories: RepositoryContainer)
```

### BentoCard（Dashboard 内部组件）

```swift
// action 为 nil 时为纯展示模式（不包裹 Button）
struct BentoCard: View {
    init(title: String, subtitle: String, icon: String,
         gradient: LinearGradient, action: (() -> Void)? = nil)
}
```

---

## SnapDrillInfrastructure（Firebase 实现，2026-03-04 新建）

> **重要**：仅 `SnapDrill/App` 目标直接 import 此包（通过 DependencyContainer）。
> 任何其他包（Core / Data / UI / Features）禁止 import SnapDrillInfrastructure。

### FirebaseBootstrap

```swift
public enum FirebaseBootstrap {
    public static func configure()  // 调用 FirebaseApp.configure()
}
```

### FirebaseAnalyticsService（@MainActor final class，遵循 AnalyticsServiceProtocol）

```swift
public init()
public func markConfigured()
public func track(event: AnalyticsEvent)
public func setUserProperty(_ value: String, forName name: String)
```

### FirebaseRemoteConfigService（@MainActor final class，遵循 RemoteConfigProtocol）

```swift
public init()
public func fetchAndActivate() async throws
public func bool(forKey key: String) -> Bool
public func string(forKey key: String) -> String?
public func double(forKey key: String) -> Double?
```

### CrashReportingService（@MainActor final class，遵循 CrashReportingProtocol）

```swift
public static let shared: CrashReportingService
public init()                                              // public（跨模块可访问）
public func markConfigured()
public func setEnabled(_ enabled: Bool)
public func recordError(_ error: Error, context: [String: String])
public func log(_ message: String, level: LogLevel)
public func setUserIdentifier(_ identifier: String)
public func setCustomValue(_ value: String, forKey key: String)
public func leaveBreadcrumb(_ message: String, metadata: [String: String])
```

---

## 常见错误防范

| 错误写法 | 正确写法 |
|---|---|
| `ReviewDataNotification.post()` | `NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)` |
| `repository.save(model)` | `repository.insertAndSave(model)` 或 `repository.saveContext()` |
| `repository.fetch(id:)` | `repository.fetchModel(by: id)` |
| `SnapDrillLogger.log("...")` | `SnapDrillLogger.generic.error("...")` |
| `ReviewItemModel.save()` | `@Model` 无 save()，通过 Repository 保存 |
| `SM2State.update(...)` | SM2State 是值类型，`scheduler.scheduleNextReview()` 返回新值 |
