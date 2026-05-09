---
last_verified: 2026-04-17
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [code_change]
---
# SnapDrill 内部 API 参考
> 各 Package 的公开接口。架构全景见 architecture.md。

## SnapDrillCore — Protocol 定义

### `NotificationServiceProtocol`
```swift
public protocol NotificationServiceProtocol: Sendable {
    func requestPermission() async -> Bool
    func scheduleDaily(at hour: Int, minute: Int) async throws
    func cancelAll()
}
```

### `CaptureDraftServiceProtocol`
```swift
public protocol CaptureDraftServiceProtocol {
    var hasDraft: Bool { get }
    func saveDraft(image: UIImage?, content: String, subject: String?) async
    func loadDraft() -> CaptureDraftService.Draft?
    func clearDraft()
}
```

### `AnalyticsServiceProtocol`
```swift
public protocol AnalyticsServiceProtocol: Sendable {
    func track(_ event: AnalyticsEvent, parameters: [String: String])
    func trackScreen(_ screenName: String, parameters: [String: String])
    func startSession()
    func endSession()
    func setUserProperty(_ value: String, forKey key: String)
    func trackRetention(daysSinceInstall: Int)
}
```

### `ContentTaggingServiceProtocol`
```swift
public protocol ContentTaggingServiceProtocol: Sendable {
    /// 从题目文本推断学科和难度（端侧 AI，FoundationModels）
    /// 设备不支持 Apple Intelligence 时返回 nil
    func suggestTags(for text: String) async -> ContentTagSuggestion?
}

nonisolated public struct ContentTagSuggestion: Sendable, Equatable {
    public let subject: String
    public let difficulty: Int   // 1-5
    public init(subject: String, difficulty: Int)
}
```

### `QuestionSplittingServiceProtocol`（PoC，Issue #626）
```swift
public protocol QuestionSplittingServiceProtocol: Sendable {
    /// 从整页 OCR 文本提取独立题目列表（端侧 AI，FoundationModels）
    /// 空文本、设备不支持或推断失败时返回空数组
    func split(documentText text: String) async -> [ExtractedQuestionItem]
}

nonisolated public struct ExtractedQuestionItem: Sendable, Equatable {
    public let text: String      // 题目完整文本（含题号）
    public let ordinal: Int      // 题目序号（1-based）
    public init(text: String, ordinal: Int)
}
```
**PoC 状态**：代码骨架已实现，准确率评估待 10 份真实试卷真机验证（Go 条件 ≥ 80%）。

### `OCRServiceProtocol`
```swift
public protocol OCRServiceProtocol: Sendable {
    /// 单题/单段文字识别（VNRecognizeTextRequest）
    /// 适合裁剪后的单题图片
    func recognizeText(from cgImage: CGImage) async throws -> String

    /// 整页文档结构化识别（RecognizeDocumentsRequest，iOS 26+）
    /// 适合整页扫描件或 PDF 页面，不适合裁剪后的单题图片
    func recognizeDocument(from cgImage: CGImage) async throws -> DocumentRecognitionResult
}

nonisolated public struct DocumentRecognitionResult: Sendable, Equatable {
    public let transcript: String        // 全文（换行符分隔）
    public let paragraphs: [String]      // 按文档结构分组的文本块
    public let tables: [[TableRow]]      // 二维字符串数组
    public init(transcript: String, paragraphs: [String], tables: [[TableRow]])
    public static let empty: DocumentRecognitionResult
}

public typealias TableRow = [String]
```

### `PDFExportable`
```swift
public protocol PDFExportable: Sendable {
    var content: String? { get }
    var imagePath: String? { get }
    var answerText: String? { get }
    var exportSubject: String? { get }
}
```

### `ServiceContainer`
```swift
public protocol ServiceContainer: Sendable {
    var analytics: AnalyticsServiceProtocol { get }
    var pdfExport: PDFExportService { get }
    var appConfig: AppConfiguration { get }
    var privacyConsent: PrivacyConsentService { get }
    var notification: NotificationServiceProtocol { get }
}
```

## SnapDrillCore — Service 公开方法

### `ReviewScheduler`
```swift
public struct ReviewScheduler {
    public init() {}
    public func scheduleNextReview(state: SM2State, rating: ReviewRating) -> SM2State
    public func intervalDescription(for rating: ReviewRating, from state: SM2State) -> String
}
```

### `PDFExportService`
```swift
public final class PDFExportService: Sendable {
    public static let shared = PDFExportService()
    public init() {}
    public func createPDF(
        from items: [any PDFExportable],
        options: PDFExportOptions = .default,
        imageProvider: @Sendable @escaping (String) -> UIImage?
    ) async throws -> Data
}
```

### `CaptureDraftService`
```swift
public final class CaptureDraftService: CaptureDraftServiceProtocol {
    public static let shared = CaptureDraftService()

    public struct Draft {
        public let image: UIImage?
        public let content: String
        public let date: Date
        public let subject: String?
    }

    public var hasDraft: Bool { get }
    public func saveDraft(image: UIImage? = nil, content: String, subject: String? = nil) async
    public func loadDraft() -> Draft?
    public func clearDraft()
}
```

### `LiveNotificationService`
```swift
public final class LiveNotificationService: NotificationServiceProtocol {
    public init() {}
    public func requestPermission() async -> Bool
    public func scheduleDaily(at hour: Int, minute: Int) async throws
    public func cancelAll()
}
```

### `NotificationServiceMock`
```swift
public final class NotificationServiceMock: NotificationServiceProtocol {
    public var simulatedPermissionGranted: Bool = true
    public var simulatedError: Error?
    public private(set) var requestPermissionCallCount = 0
    public private(set) var scheduledHours: [(hour: Int, minute: Int)] = []
    public private(set) var cancelAllCallCount = 0

    public init() {}
    public func requestPermission() async -> Bool
    public func scheduleDaily(at hour: Int, minute: Int) async throws
    public func cancelAll()
    public func reset()
}
```

### `AnalyticsServiceMock`
```swift
public final class AnalyticsServiceMock: AnalyticsServiceProtocol {
    public private(set) var trackedEvents: [(event: AnalyticsEvent, parameters: [String: String])] = []
    public private(set) var trackedScreens: [(screen: String, parameters: [String: String])] = []
    public private(set) var sessionStartCount = 0
    public private(set) var sessionEndCount = 0
    public private(set) var userProperties: [String: String] = [:]
    public private(set) var retentionTracking: [Int] = []

    public init() {}
    public func track(_ event: AnalyticsEvent, parameters: [String: String])
    public func trackScreen(_ screenName: String, parameters: [String: String])
    public func startSession()
    public func endSession()
    public func setUserProperty(_ value: String, forKey key: String)
    public func trackRetention(daysSinceInstall: Int)
    public func hasTrackedEvent(_ event: AnalyticsEvent) -> Bool
    public func hasTrackedScreen(_ screenName: String) -> Bool
    public func clear()
}
```

### `PrivacyConsentService`
```swift
public final class PrivacyConsentService {
    public static let shared = PrivacyConsentService()
    public init() {}
}
```
ATT 授权逻辑已根据 ADR-002 移除。保留空壳供 DI 兼容。

### `ContentTaggingService`
```swift
public actor ContentTaggingService: ContentTaggingServiceProtocol {
    public init() {}
    /// 使用 FoundationModels 的 contentTagging adapter，端侧推断学科和难度
    /// SystemLanguageModel.default.isAvailable 为 false 时静默返回 nil
    public func suggestTags(for text: String) async -> ContentTagSuggestion?
}
```

### `QuestionSplittingService`（PoC）
```swift
public actor QuestionSplittingService: QuestionSplittingServiceProtocol {
    public init() {}
    /// 使用 FoundationModels 默认 SystemLanguageModel 端侧分割题目
    /// 通过 @Generable ExtractedQuestionsPayload 结构化输出
    public func split(documentText text: String) async -> [ExtractedQuestionItem]
}
```

### `OCRService`
```swift
public actor OCRService: OCRServiceProtocol {
    public init() {}
    public func recognizeText(from cgImage: CGImage) async throws -> String
    /// iOS 26+，使用 RecognizeDocumentsRequest，配置 zh-Hans + en-US
    public func recognizeDocument(from cgImage: CGImage) async throws -> DocumentRecognitionResult
}
```

### `ImageStorage`
```swift
public struct ImageStorage: Sendable {
    nonisolated public init(baseDirectory: URL? = nil)
    nonisolated public func saveImage(_ image: UIImage) async throws -> String
    nonisolated public func deleteImage(path: String) async throws
    nonisolated public func loadImage(path: String) -> UIImage?
    nonisolated public func loadImageAsync(path: String) async -> UIImage?
    nonisolated public func loadDownsampledImage(path: String, maxLongSide: Int = 1200) -> UIImage?
    public func imageDirectorySize() async -> Int64
}
```

### `AppConfiguration`
```swift
public final class AppConfiguration {
    public static let shared = AppConfiguration()
    public init() {}
    public var appVersion: String { get }
    public var buildNumber: String { get }
    public var bundleIdentifier: String { get }
    public var fullVersion: String { get }
    public var environment: Environment { get }
    public var isProduction: Bool { get }
    public func resetToDefaults()

    public struct FeatureFlags {
        public static var crashReportingEnabled: Bool { get set }
        public static var analyticsEnabled: Bool { get set }
    }

    public enum Environment {
        public static var current: Environment { get }
    }
}
```

## SnapDrillCore — 公开类型

### 核心枚举 / 值类型
```swift
public enum Difficulty: Int, CaseIterable, Sendable, Codable, Identifiable, Hashable
public enum ReviewRating: Int
public struct SM2State: Sendable
nonisolated public struct Profile: Codable, Identifiable, Sendable, Equatable
nonisolated public struct PDFExportOptions: Sendable
public enum AnalyticsEvent: String
public struct SnapDrillLogger
public enum SnapDrillError: LocalizedError
public enum OCRError: Error
public enum ImageStorageError: Error
public final class AppActivityTracker
public final class DeletionScheduler
```

### `SM2State`
```swift
public struct SM2State: Sendable {
    public var easeFactor: Double
    public var interval: Int
    public var repetitions: Int
    public var nextReviewAt: Date?
    public var lastReviewedAt: Date?
    public init(
        easeFactor: Double = 2.5,
        interval: Int = 0,
        repetitions: Int = 0,
        nextReviewAt: Date? = nil,
        lastReviewedAt: Date? = nil
    )
}
```

### `Profile`
```swift
nonisolated public struct Profile: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public var name: String
    public var avatar: String
    public var avatarColorIndex: Int
    public let createdAt: Date
    public init(
        id: UUID = UUID(),
        name: String,
        avatar: String = "person.crop.circle.fill",
        avatarColorIndex: Int = 0,
        createdAt: Date = Date()
    )
}
```

### `PDFExportOptions`
```swift
nonisolated public struct PDFExportOptions: Sendable {
    public var hideAnswers: Bool
    public var showBlankAnswerArea: Bool
    public var showHeader: Bool
    public var itemsPerPage: Int
    public init(
        hideAnswers: Bool = true,
        showBlankAnswerArea: Bool = true,
        showHeader: Bool = true,
        itemsPerPage: Int = 2,
        customTitle: String? = nil
    )
    public static let `default` = PDFExportOptions()
}
```

### 依赖注入 / 工具类型
```swift
public final class LiveServiceContainer: ServiceContainer
public final class MockServiceContainer: ServiceContainer
public extension EnvironmentValues
public extension Notification.Name
public extension Collection
public extension Color {
    init(hex: String)
    func toHex() -> String?
}
```

## SnapDrillData — DataExecutor

### `DataExecutor`

拥有 ModelContainer 的 actor，根除 #599 死锁。生产代码优先使用 `init(storeURL:)`（MainActor 安全）；测试/非 MainActor 场景用 `createOffMainActor()`。

```swift
public actor DataExecutor {
    nonisolated public let container: ModelContainer
    public private(set) var isUsingInMemoryFallback: Bool
    public private(set) var initializationError: PersistenceError?

    public init(inMemory: Bool = false, storeURL: URL? = nil)
    public init(container: ModelContainer)

    /// 在非 MainActor 执行器上创建，避免 #599 死锁（测试专用）
    public static func createOffMainActor(
        inMemory: Bool = false,
        storeURL: URL? = nil
    ) async -> DataExecutor
}
```

## SnapDrillData — Repository 公开方法

### `ReviewRepository`
```swift
public final class ReviewRepository {
    public init(modelContext: ModelContext)
    public func totalCount() throws -> Int
    public func delete(id: UUID) async throws
    public func countBySubject(name: String) throws -> Int
    public func updateSubjectUsage(from oldName: String, to newName: String) throws
    public func countBySource(name: String) throws -> Int
    public func updateSourceUsage(from oldName: String, to newName: String) throws
    public func countByGrade(name: String) throws -> Int
    public func updateGradeUsage(from oldName: String, to newName: String) throws
    public func collectAllImagePaths() throws -> [String]
    public func deleteAll() throws
    public func fetchDueCount() throws -> Int
    public func fetchTodayCount() throws -> Int
    public func fetchTodayReviewedCount() throws -> Int
    public func totalItemCount() throws -> Int
    public func fetchDueModels() throws -> [ReviewItemModel]
    public func fetchModel(by id: UUID) throws -> ReviewItemModel?
    public func fetchModels(by ids: Set<UUID>) throws -> [ReviewItemModel]
    public func fetchAllModels() throws -> [ReviewItemModel]
    public func fetchSmartSelection(
        limit: Int,
        subjects: Set<String> = [],
        difficulties: Set<Int> = []
    ) throws -> [ReviewItemModel]
    public func fetchFilteredModels(
        searchText: String,
        subjects: Set<String>,
        tags: Set<String>,
        difficulties: Set<Int> = [],
        sortDescriptors: [SortDescriptor<ReviewItemModel>] = [SortDescriptor(\ReviewItemModel.createdAt, order: .reverse)],
        limit: Int,
        offset: Int
    ) throws -> [ReviewItemModel]
    public func insert(_ model: ReviewItemModel)
    public func insertAndSave(_ model: ReviewItemModel) throws
    public func saveContext() throws
    public func rollbackContext()
}
```

### `SubjectRepository`
```swift
public final class SubjectRepository {
    public init(modelContext: ModelContext)
    public func delete(id: UUID) throws
    public func totalCount() throws -> Int
    public func seedDefaultsIfNeeded()
    public func fetchAllModels() throws -> [SubjectModel]
    public func fetchModel(byName name: String) throws -> SubjectModel?
    public func insert(_ model: SubjectModel)
    public func insertAndSave(_ model: SubjectModel) throws
    public func saveContext() throws
    public func deleteAll() throws
}
```

### `SourceRepository`
```swift
public final class SourceRepository {
    public init(modelContext: ModelContext)
    public func delete(id: UUID) throws
    public func totalCount() throws -> Int
    public func seedDefaultsIfNeeded()
    public func fetchAllModels() throws -> [SourceModel]
    public func fetchModel(byName name: String) throws -> SourceModel?
    public func insert(_ model: SourceModel)
    public func insertAndSave(_ model: SourceModel) throws
    public func saveContext() throws
    public func deleteAll() throws
}
```

### `GradeRepository`
```swift
public final class GradeRepository {
    public init(modelContext: ModelContext)
    public func delete(id: UUID) throws
    public func totalCount() throws -> Int
    public func seedDefaultsIfNeeded()
    public func deleteAll() throws
    public func fetchAllModels() throws -> [GradeModel]
    public func fetchModel(byName name: String) throws -> GradeModel?
    public func insert(_ model: GradeModel)
    public func insertAndSave(_ model: GradeModel) throws
    public func saveContext() throws
}
```

### `TagRepository`
```swift
public final class TagRepository {
    public init(modelContext: ModelContext)
    public func delete(id: UUID) throws
    public func fetchAllModels() throws -> [TagModel]
    public func fetchOrCreateModel(name: String, colorHex: String) throws -> TagModel
    public func saveContext() throws
    public func deleteAll() throws
}
```

### `RepositoryContainer`
```swift
public final class RepositoryContainer {
    public let review: ReviewRepository
    public let subject: SubjectRepository
    public let source: SourceRepository
    public let tag: TagRepository
    public let grade: GradeRepository

    public init(executor: DataExecutor)
    public init(modelContext: ModelContext)
    public func deleteAllData() async throws
    public func deleteAllTaxonomy() throws
}

public final class PreviewRepositoryContainer {
    public let review: ReviewRepository
    public let subject: SubjectRepository
    public let source: SourceRepository
    public let tag: TagRepository
    public let grade: GradeRepository
    public init()
}
```

## SnapDrillData — Model 字段

### `ReviewItemModel`

| 字段 | Swift 声明 |
| --- | --- |
| id | `public var id: UUID = UUID()` |
| content | `public var content: String?` |
| imagePath | `public var imagePath: String?` |
| createdAt | `public var createdAt: Date = Date()` |
| lastReviewedAt | `public var lastReviewedAt: Date = Date.distantPast` |
| nextReviewAt | `public var nextReviewAt: Date = Date.distantPast` |
| subjectRawValue | `public var subjectRawValue: String = "其他"` |
| sourceRawValue | `public var sourceRawValue: String = "其他"` |
| tags | `public var tags: [TagModel]? = []` |
| answerText | `public var answerText: String?` |
| answerImagePath | `public var answerImagePath: String?` |
| difficulty | `public var difficulty: Int = 1` |
| difficultyValue | `public var difficultyValue: Difficulty` |
| grade | `public var grade: String = ""` |
| easeFactor | `public var easeFactor: Double = 2.5` |
| interval | `public var interval: Int = 0` |
| repetitions | `public var repetitions: Int = 0` |
| subject | `public var subject: String` |
| source | `public var source: String` |
| isScheduled | `public var isScheduled: Bool` |

```swift
public init(
    id: UUID = UUID(),
    content: String? = nil,
    imagePath: String? = nil,
    createdAt: Date = Date(),
    lastReviewedAt: Date = .distantPast,
    nextReviewAt: Date = .distantPast,
    subject: String = "其他",
    source: String = "其他",
    tags: [TagModel]? = [],
    answerText: String? = nil,
    answerImagePath: String? = nil,
    difficulty: Int = 1,
    grade: String = "",
    easeFactor: Double = 2.5,
    interval: Int = 0,
    repetitions: Int = 0
)

public func toExportSnapshot() -> ReviewExportSnapshot
```

### 其他公开模型
```swift
public final class SubjectModel
public final class SourceModel
public final class GradeModel
public final class TagModel
nonisolated public struct ReviewExportSnapshot: Sendable, Identifiable
nonisolated public struct BackupManifest: Codable, Sendable
nonisolated public struct ReviewItemBackupDTO: Codable, Sendable
nonisolated public struct SubjectBackupDTO: Codable, Sendable
nonisolated public struct SourceBackupDTO: Codable, Sendable
nonisolated public struct GradeBackupDTO: Codable, Sendable
nonisolated public struct TagBackupDTO: Codable, Sendable
nonisolated public struct BackupPayload: Codable, Sendable
```

## SnapDrillData — 备份/Profile

### `BackupService`
```swift
public actor BackupService {
    public typealias ProgressHandler = @Sendable (Int, Int) -> Void
    public init() {}
    public func createBackup(
        payload: BackupPayload,
        manifest: BackupManifest,
        profileDirectories: [URL],
        onProgress: ProgressHandler? = nil
    ) throws -> URL
    public func readManifest(from backupURL: URL) throws -> BackupManifest
    public func extractPayload(from backupURL: URL) throws -> BackupPayload
    public func restoreImages(
        from backupURL: URL,
        profileId: UUID,
        to imageBasePath: URL,
        onProgress: ProgressHandler? = nil
    ) throws
}
```

### `ProfileManager`
```swift
public final class ProfileManager {
    public private(set) var profiles: [Profile] = []
    public private(set) var activeProfileId: UUID
    public private(set) var activeContainer: ModelContainer
    public private(set) var activeRepositories: RepositoryContainer
    public private(set) var activeImageStorage: ImageStorage
    public private(set) var executor: DataExecutor
    public private(set) var isUsingInMemoryFallback: Bool

    public init(inMemory: Bool = false)
    public var activeProfile: Profile? { get }
    public func switchProfile(to profileId: UUID) throws(ProfileError)
    @discardableResult
    public func createProfile(name: String) -> Profile?
    public func deleteProfile(id: UUID) throws(ProfileError)
    public func renameProfile(id: UUID, newName: String)
}

public enum ProfileError: LocalizedError {
    case cannotDeleteLastProfile
    case switchBlocked(reason: String)
}
```

`ProfileManager` 内部维护 `static let perProfileKeys: [String]`（非 public API），用于定义需要按 Profile 隔离并在切换时自动保存/加载的 UserDefaults 键集合。

## SnapDrillUI — 公开类型

### 协议 / 导航
```swift
public protocol FeatureRouter: AnyObject, Observable {
    associatedtype Destination: Hashable
    var path: NavigationPath { get set }
    func push(_ destination: Destination)
    func pop()
    func reset()
}

public enum TabItem: Hashable, CaseIterable
```

### View 入口
```swift
public struct SnapDrillButton: View
public init(title: String, action: @escaping () -> Void)

public struct TagInputView: View
public init(tags: Binding<[String]>, text: Binding<String>, suggestions: [String] = [])

public struct ProgressLoadingView: View
public init(message: String, progress: Double? = nil)

public struct SkeletonLoadingView: View
public init(itemCount: Int = 5)

public struct FlipView<Front: View, Back: View>: View
public init(
    isFlipped: Bool,
    @ViewBuilder front: @escaping () -> Front,
    @ViewBuilder back: @escaping () -> Back
)

public struct ImageCropperView: UIViewControllerRepresentable
public init(originalImage: UIImage, onCrop: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void)

public struct ErrorMessageView: View
public init(
    title: String,
    message: String,
    icon: String = "exclamationmark.triangle.fill",
    actionTitle: String? = nil,
    action: (() -> Void)? = nil
)

public struct LoadingView: View
public init(message: String = "加载中...")

public struct OnboardingPage: Identifiable, Sendable
public init(title: String, description: String, imageName: String = "", systemImage: String? = nil)

public struct OnboardingView: View
public init(pages: [OnboardingPage], onComplete: @escaping () -> Void)

public final class OnboardingManager
public var shouldShowOnboarding: Bool
public func completeOnboarding()
public func resetAll()

public struct ReviewSwipeTip: Tip
public var title: Text { get }
public var message: Text? { get }
public var image: Image? { get }

public struct FieldConfigTip: Tip
public var title: Text { get }
public var message: Text? { get }
public var image: Image? { get }

public struct ContextualErrorView: View
public init(error: AppError, onAction: (() -> Void)? = nil)

public struct ErrorBannerView: View
public init(error: AppError, onDismiss: @escaping () -> Void)
```

### 其他公开辅助类型
```swift
public enum AccessibilityHelper
public struct AccessibilityAnnouncement
public enum AccessibilityNotificationPriority
public enum AppError: LocalizedError
```

## SnapDrillInfrastructure — 公开类型

### `FirebaseAnalyticsService`
```swift
@MainActor public final class FirebaseAnalyticsService: AnalyticsServiceProtocol {
    public static let shared = FirebaseAnalyticsService()
    public init() {}
    public func markConfigured()
    public func track(_ event: AnalyticsEvent, parameters: [String: String])
    public func trackScreen(_ screenName: String, parameters: [String: String])
    public func startSession()
    public func endSession()
    public func setUserProperty(_ value: String, forKey key: String)
    public func trackRetention(daysSinceInstall: Int)
}
```

### `FirebaseBootstrap`
```swift
public enum FirebaseBootstrap {
    public static func configure()
    public static func setCrashlyticsEnabled(_ enabled: Bool)
    public static func setAnalyticsEnabled(_ enabled: Bool)
}
```

## 错误类型

### Core
```swift
public enum SnapDrillError: LocalizedError {
    case dataNotFound
    case captureFailed
    case unknown(String)
}

public enum OCRError: Error {
    case invalidImage
}

public enum ImageStorageError: Error {
    case invalidImageData
}
```

### Data
```swift
public enum DataError: LocalizedError {
    case duplicateName(name: String, entityType: String)
}

public enum PersistenceError: LocalizedError {
    case containerInitializationFailed(underlying: Error)
    case migrationFailed(from: String, to: String, underlying: Error)
    case storageUnavailable(reason: String)
}

public enum BackupError: LocalizedError {
    case archiveCreationFailed
    case invalidArchive
    case missingManifest
    case missingDataFile
    case schemaVersionTooNew(fileVersion: Int, appVersion: Int)
    case insufficientDiskSpace
}

public enum ProfileError: LocalizedError {
    case cannotDeleteLastProfile
}
```

### UI
```swift
public enum AppError: LocalizedError {
    case cameraPermissionDenied
    case photoLibraryPermissionDenied
    case ocrFailed(String)
    case exportFailed(String)
    case importFailed(String)
    case dataCorrupted
    case unknown(Error)
}
```

---

## 新增 API（2026-04-10 基线审计补充）

### `DeletionScheduler`（SnapDrillCore/Service）
```swift
@Observable public final class DeletionScheduler {
    public var showUndoToast: Bool
    public func scheduleDeletion(ids: Set<UUID>, executor: @escaping DeletionExecutor)
    public func undoDeletion() -> DeletionUndoResult
    public func commitImmediately()
}
```
App 级删除调度器，管理 5 秒撤销窗口。LibraryViewModel 是调用方。

### `AppActivityTracker`（SnapDrillCore/Support）
```swift
@Observable public final class AppActivityTracker {
    public static let shared = AppActivityTracker()
    public private(set) var activeActivities: Set<AppActivity> = []
    public var canSwitchProfile: Bool { get }
    public var switchBlockReason: String? { get }
    public func begin(_ activity: AppActivity)
    public func end(_ activity: AppActivity)
}

public enum AppActivity: Sendable, Hashable {
    case capturing
    case exporting
    case printing
    case backupRestore
}
```
全局活动追踪器。ProfileManager 切换前通过 `canSwitchProfile` 检查进行中操作，避免数据丢失。

### `SmartPaperViewModel`（SnapDrillFeatures/Library）
```swift
final class SmartPaperViewModel {
    var questionCount: Int = 10
    var selectedSubjects: Set<String> = []
    var selectedDifficulties: Set<Int> = []
    var hideAnswers: Bool = true
    var showBlankAnswerArea: Bool = true
    var showHeader: Bool = true
    var itemsPerPage: Int = 2
    private(set) var selectedItems: [ReviewExportSnapshot] = []
    private(set) var availableSubjects: [String] = []
    private(set) var isLoading: Bool = false
    func loadInitialData()
    func refreshSelection()
    var pdfOptions: PDFExportOptions { get }
}
```
智能组卷 ViewModel。SM-2 选题 + PDF 生成。ADR-001 Hybrid 定价。

### `DashboardAnalyticsViewModel`（SnapDrillFeatures/Dashboard）
```swift
final class DashboardAnalyticsViewModel {
    private(set) var subjectTrend: [SubjectTrendPoint] = []
    private(set) var difficultyDistribution: [DifficultyBucket] = []
    private(set) var weakSubjects: [WeakSubjectItem] = []
    var hasData: Bool { get }
    func loadAnalytics()
    func cancelTasks()
}
```
高级统计 ViewModel。趋势图 + 难度分布 + 薄弱排行。ADR-001 Hybrid 定价。
