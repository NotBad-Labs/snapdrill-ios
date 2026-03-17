# SnapDrill 基础设施清单（API 权威参考）

> **使用规则**：修改任何代码前，必须先确认 API 真实存在，禁止凭名称推测。
> 检查顺序（三选一）：
> 1. 查本文件（所有公开接口的权威清单）
> 2. 用 `Grep` 搜索现有调用方式（找真实用法）
> 3. 用 `Read` 读源文件确认签名
>
> 新增 API 时：写完后同步更新本文件。

最后更新：2026-03-13（删除 ~1,200 行投机性基础设施代码，ServiceContainer 9→5 属性）

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

// Difficulty（enum, CaseIterable, Sendable, Codable, Identifiable, Hashable）
public enum Difficulty: Int, CaseIterable, Sendable, Codable, Identifiable, Hashable {
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

// OCRServiceProtocol
public protocol OCRServiceProtocol {
    func recognizeText(from cgImage: CGImage) async throws -> String
}

// AnalyticsServiceProtocol（@MainActor, Sendable）
@MainActor
public protocol AnalyticsServiceProtocol: Sendable {
    func track(_ event: AnalyticsEvent, parameters: [String: String])
    func trackScreen(_ screenName: String, parameters: [String: String])
    func startSession()
    func endSession()
    func setUserProperty(_ value: String, forKey key: String)
    func trackRetention(daysSinceInstall: Int)
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
    var pdfExport: PDFExportService { get }
    var appConfig: AppConfiguration { get }
    var privacyConsent: PrivacyConsentService { get }
    var notification: NotificationServiceProtocol { get }
}
```

### 应用配置

```swift
// RemoteConfigurable（@MainActor protocol，路径：Support/AppConfiguration.swift）
@MainActor
public protocol RemoteConfigurable {
    func fetchAndActivate() async throws
    func bool(forKey key: String) -> Bool
    func string(forKey key: String) -> String?
    func double(forKey key: String) -> Double?
}

// AppConfiguration（@MainActor final class，路径：Support/AppConfiguration.swift）
@MainActor
public final class AppConfiguration {
    public static let shared: AppConfiguration
    public init()

    // App Info
    public var appVersion: String { get }
    public var buildNumber: String { get }
    public var bundleIdentifier: String { get }
    public var fullVersion: String { get }

    // Environment
    public var environment: Environment { get }
    public var isProduction: Bool { get }
    public func resetToDefaults()

    public enum Environment {
        case development, staging, production
        public static var current: Environment { get }
    }

    @MainActor
    public struct FeatureFlags {
        public static func registerRemoteProvider(_ provider: any RemoteConfigurable)
        public static var crashReportingEnabled: Bool { get set }  // 默认 false
        public static var analyticsEnabled: Bool { get set }
        public static var isEmergencyKillSwitchActive: Bool { get }  // 远程 kill-switch，只读
    }
}

// PrivacyConsentService（@MainActor final class，路径：Service/PrivacyConsentService.swift）
// #if canImport(AppTrackingTransparency)
@MainActor
public final class PrivacyConsentService {
    public static let shared: PrivacyConsentService
    public init()
    public var trackingStatus: ATTrackingManager.AuthorizationStatus { get }
    public var isTrackingAuthorized: Bool { get }
    public func requestTrackingAuthorization() async -> ATTrackingManager.AuthorizationStatus
    public var shouldShowPrePrompt: Bool { get }  // 首次未决策时为 true
}
```

### DI 容器实现

```swift
// LiveServiceContainer（@MainActor final class，路径：DI/LiveServiceContainer.swift）
@MainActor
public final class LiveServiceContainer: ServiceContainer {
    public init(
        analytics: AnalyticsServiceProtocol? = nil,   // nil → AnalyticsServiceMock()
        notification: NotificationServiceProtocol? = nil  // nil → LiveNotificationService()
    )
    // 内部自动创建：AppConfiguration(), PDFExportService(), PrivacyConsentService()
}

// MockServiceContainer（@MainActor final class，路径：DI/MockServiceContainer.swift）
@MainActor
public final class MockServiceContainer: ServiceContainer {
    public init()
    // 全部 Mock 实现，适用于单元测试和 SwiftUI Preview
}
```

### 枚举与辅助类型

```swift
// AnalyticsEvent（enum）
public enum AnalyticsEvent: String {
    case appLaunched, reviewItemCreated, reviewItemCompleted
    case reviewSessionStarted, reviewSessionCompleted
    case screenViewed
    case sessionStarted, sessionEnded
    case cameraOpened, captureSaved, ocrPerformed, pdfExported, dataExported
    case errorOccurred
}

// OCRError（enum, Error）
public enum OCRError: Error {
    case invalidImage
}

// ImageStorageError（enum, Error）
public enum ImageStorageError: Error {
    case invalidImageData
}
```

### 服务实现（Core 包）

```swift
// OCRService（actor，遵循 OCRServiceProtocol）
public actor OCRService: OCRServiceProtocol {
    public init()
    public func recognizeText(from cgImage: CGImage) async throws -> String
}

```

### 其他核心类型

```swift
// ImageStorage（struct）
public struct ImageStorage {
    public init()
    public func saveImage(_ image: UIImage) async throws -> String
    public func loadImage(path: String) -> UIImage?
    public func deleteImage(path: String) async throws  // async 2026-03-06，Apple 文档要求文件 I/O 异步；文件不存在时静默跳过
}

// PDFExportService（final class，路径：Service/PDFExportService.swift）
public final class PDFExportService {
    public static let shared: PDFExportService
    public func createPDF(from items: [any PDFExportable],
                          imageProvider: @Sendable @escaping (String) -> UIImage?) async throws -> Data
}

// CaptureDraftServiceProtocol（@MainActor protocol，路径：Service/CaptureDraftServiceProtocol.swift）
// #if canImport(UIKit)
@MainActor
public protocol CaptureDraftServiceProtocol {
    var hasDraft: Bool { get }
    func saveDraft(image: UIImage, content: String) async
    func loadDraft() -> CaptureDraftService.Draft?
    func clearDraft()
}

// CaptureDraftService（@MainActor final class，路径：Service/CaptureDraftService.swift）
// #if canImport(UIKit)
@MainActor
public final class CaptureDraftService: CaptureDraftServiceProtocol {
    public static let shared: CaptureDraftService
    public var hasDraft: Bool { get }
    public func saveDraft(image: UIImage, content: String) async
    public func loadDraft() -> Draft?
    public func clearDraft()

    public struct Draft {
        public let image: UIImage
        public let content: String
        public let date: Date
    }
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
public var lastReviewedAt: Date       // 默认 .distantPast（Schema V2 起非可选）
public var nextReviewAt: Date         // 默认 .distantPast（Schema V2 起非可选）
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
public var isScheduled: Bool { get }   // nextReviewAt != .distantPast

// 方法
public func toExportSnapshot() -> ReviewExportSnapshot

// 主 init（所有参数均有默认值）
public init(id: UUID = UUID(), content: String? = nil, imagePath: String? = nil,
            createdAt: Date = Date(), lastReviewedAt: Date = .distantPast, nextReviewAt: Date = .distantPast,
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
                                tags: Set<String>,
                                sortDescriptors: [SortDescriptor<ReviewItemModel>] = [SortDescriptor(\ReviewItemModel.createdAt, order: .reverse)],
                                limit: Int, offset: Int) throws -> [ReviewItemModel]

// 写入
public func insert(_ model: ReviewItemModel)       // 纯内存插入，不 save；调用方统一 saveContext()
public func insertAndSave(_ model: ReviewItemModel) throws
public func saveContext() throws
public func rollbackContext()          // saveContext 失败时调用，回滚所有未持久化变更
public func delete(id: UUID) async throws  // async 2026-03-06，内部含文件 I/O
public func collectAllImagePaths() throws -> [String]  // 收集所有题目图片路径，供删除前清理
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
public func insert(_ model: SubjectModel / ...)       // 纯内存插入，不 save
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
public func saveContext() throws
public func delete(id: UUID) throws
public func deleteAll() throws
// 注意：TagRepository 没有 totalCount()，与 Subject/Source/Grade Repository 不同
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
public func collectBackupPayload() throws -> BackupPayload  // 收集全量数据为 Sendable DTO
public func restoreFromPayload(_ payload: BackupPayload) async throws  // 全量替换恢复
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

### BackupService（actor）

```swift
public actor BackupService {
    public typealias ProgressHandler = @Sendable (Int, Int) -> Void
    public init()
    public func createBackup(payload: BackupPayload, manifest: BackupManifest,
                             imageBasePath: URL, onProgress: ProgressHandler? = nil) throws -> URL
    public func readManifest(from backupURL: URL) throws -> BackupManifest
    public func extractPayload(from backupURL: URL) throws -> BackupPayload
    public func restoreImages(from backupURL: URL, to imageBasePath: URL,
                              onProgress: ProgressHandler? = nil) throws
}
```

### BackupManifest / BackupPayload / BackupDTO（Codable, Sendable）

```swift
// BackupManifest — 备份文件元数据清单
public struct BackupManifest: Codable, Sendable {
    public let schemaVersion: Int
    public let createdAt: Date
    public let appVersion: String
    public let itemCount: Int
    public static let currentSchemaVersion = 1
}

// BackupPayload — data.json 顶层结构
public struct BackupPayload: Codable, Sendable {
    public let reviewItems: [ReviewItemBackupDTO]
    public let subjects: [SubjectBackupDTO]
    public let sources: [SourceBackupDTO]
    public let grades: [GradeBackupDTO]
    public let tags: [TagBackupDTO]
}

// 各 DTO：ReviewItemBackupDTO, SubjectBackupDTO, SourceBackupDTO, GradeBackupDTO, TagBackupDTO
// 与对应 @Model 字段一一映射，TagModel 关系用 tagNames: [String] 表达
```

### BackupError（LocalizedError）

```swift
public enum BackupError: LocalizedError {
    case archiveCreationFailed
    case invalidArchive
    case missingManifest
    case missingDataFile
    case schemaVersionTooNew(fileVersion: Int, appVersion: Int)
    case insufficientDiskSpace
}
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

// FeatureRouter（@MainActor protocol，所有 Router 遵循）
@MainActor
public protocol FeatureRouter: AnyObject, Observable {
    associatedtype Destination: Hashable
    var path: NavigationPath { get set }
    func push(_ destination: Destination)
    func pop()
    func reset()
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
public func save()                         // 触发保存并存储 Task 句柄（由 View 调用）
public func saveResult() async             // 保存正式题目（内部实现）
public func generateDraftIfNeeded() async  // 保存预览草稿（async，测试可直接 await）
public func saveDraftOnDisappear()         // 触发草稿保存并存储 Task 句柄（由 View 的 onDisappear 调用）

// LibraryEditViewModel
public init(item: ReviewItemModel, repositories: RepositoryContainer,
            imageStorage: ImageStorage = ImageStorage(), ocrService: OCRServiceProtocol = OCRService())

// SettingsViewModel
public init(repositories: RepositoryContainer)
public func clearAllData() async
public func createBackup() async              // 创建 .snapdrill 备份文件，结果存入 backupFileURL
public func restoreFromBackup(fileURL: URL) async  // 全量恢复（含恢复前自动备份）
// Observable 属性：backupProgress, isBackupInProgress, backupStatusMessage, backupError, backupFileURL
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
public static let shared: FirebaseAnalyticsService
public init()
public func markConfigured()
public func track(_ event: AnalyticsEvent, parameters: [String: String])
public func trackScreen(_ screenName: String, parameters: [String: String])
public func startSession()
public func endSession()
public func setUserProperty(_ value: String, forKey key: String)
public func trackRetention(daysSinceInstall: Int)
```

### FirebaseRemoteConfigService（@MainActor final class，遵循 RemoteConfigurable）

```swift
public init()
public func fetchAndActivate() async throws
public func bool(forKey key: String) -> Bool
public func string(forKey key: String) -> String?
public func double(forKey key: String) -> Double?
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
