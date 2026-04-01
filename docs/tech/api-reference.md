# SnapDrill 内部 API 参考

> 各 Package 的公开接口（Protocol + public 方法）。替换任一模块的实现只需遵循对应 Protocol。
>
> 架构全景见 `architecture.md`，API 易错点见 `../../.claude/rules/api-pitfalls.md`。

---

## SnapDrillCore — Protocol 定义

### ServiceContainer（服务容器）

```swift
// DI/ServiceContainer.swift
public protocol ServiceContainer: Sendable {
    var analytics: AnalyticsServiceProtocol { get }
    var pdfExport: PDFExportService { get }
    var appConfig: AppConfiguration { get }
    var privacyConsent: PrivacyConsentService { get }
    var notification: NotificationServiceProtocol { get }
}
```

Environment Key: `\.services`

---

### OCRServiceProtocol（OCR 识别）

```swift
// Service/OCRServiceProtocol.swift
public protocol OCRServiceProtocol: Sendable {
    func recognizeText(from cgImage: CGImage) async throws -> String
}
```

- 实现：`OCRService`（Apple Vision 高精度模式）
- 返回：识别文本，多行 `\n` 分隔；无文字返回空字符串
- 错误：`OCRError.invalidImage` 或 Vision 框架错误

---

### AnalyticsServiceProtocol（分析埋点）

```swift
// Service/AnalyticsServiceProtocol.swift
public protocol AnalyticsServiceProtocol: Sendable {
    func track(_ event: AnalyticsEvent, parameters: [String: String])
    func trackScreen(_ screenName: String, parameters: [String: String])
    func startSession()
    func endSession()
    func setUserProperty(_ value: String, forKey key: String)
    func trackRetention(daysSinceInstall: Int)
}
```

- 实现：`FirebaseAnalyticsService`（Infrastructure 层）
- Mock：`AnalyticsServiceMock`（测试用，无操作）
- Environment Key: `\.analyticsService`

---

### NotificationServiceProtocol（通知）

```swift
// Service/NotificationServiceProtocol.swift
public protocol NotificationServiceProtocol: Sendable {
    func requestPermission() async -> Bool
    func scheduleDaily(at hour: Int, minute: Int) async throws
    func cancelAll()
}
```

- 实现：`LiveNotificationService`（UNUserNotificationCenter）
- Mock：`NotificationServiceMock`

---

### CaptureDraftServiceProtocol（草稿）

```swift
// Service/CaptureDraftServiceProtocol.swift
public protocol CaptureDraftServiceProtocol {
    var hasDraft: Bool { get }
    func saveDraft(image: UIImage?, content: String, subject: String?) async
    func loadDraft() -> CaptureDraftService.Draft?
    func clearDraft()
}
```

- 实现：`CaptureDraftService.shared`（单例）
- 草稿 7 天自动过期

---

### PDFExportable（PDF 导出数据源）

```swift
// Service/PDFExportable.swift
public protocol PDFExportable: Sendable {
    var content: String? { get }
    var imagePath: String? { get }
    var answerText: String? { get }
    var exportSubject: String? { get }
}
```

- 遵循者：`ReviewExportSnapshot`（SnapDrillData）

---

### RemoteConfigurable（远程配置）

```swift
// Support/AppConfiguration.swift
public protocol RemoteConfigurable {
    func fetchAndActivate() async throws
    func bool(forKey key: String) -> Bool?
    func string(forKey key: String) -> String?
    func double(forKey key: String) -> Double?
}
```

- 实现：`FirebaseRemoteConfigService`（Infrastructure 层）

---

### FeatureRouter（路由协议）

```swift
// SnapDrillUI/Navigation.swift
public protocol FeatureRouter: AnyObject, Observable {
    associatedtype Destination: Hashable
    var path: NavigationPath { get set }
    func push(_ destination: Destination)
    func pop()
    func reset()
}
```

- 已提供默认实现（push/pop/reset）
- 各 Feature 定义自己的 Destination enum

---

## SnapDrillCore — Service 公开方法

### ImageStorage（图片存储）

```swift
// Capture/ImageStorage.swift
nonisolated public init(baseDirectory: URL? = nil)

// 保存（下采样 2000px，JPEG 0.8）→ 返回相对路径 "images/uuid.jpg"
nonisolated public func saveImage(_ image: UIImage) async throws -> String

// 删除图片文件
nonisolated public func deleteImage(path: String) async throws

// 同步加载（仅限 PDFRenderer 闭包内使用，会阻塞调用线程）
nonisolated public func loadImage(path: String) -> UIImage?

// 异步加载（View 中推荐使用）
nonisolated public func loadImageAsync(path: String) async -> UIImage?

// 下采样加载（大图内存优化，默认 1200px）
nonisolated public func loadDownsampledImage(path: String, maxLongSide: Int = 1200) -> UIImage?

// 图片目录总占用字节
public func imageDirectorySize() async -> Int64
```

---

### PDFExportService（PDF 导出）

```swift
// Service/PDFExportService.swift
public func createPDF(
    from items: [any PDFExportable],
    options: PDFExportOptions = .default,
    imageProvider: @Sendable @escaping (String) -> UIImage?
) async throws -> Data
```

PDFExportOptions:
```swift
public var hideAnswers: Bool = true           // 隐藏答案
public var showBlankAnswerArea: Bool = true   // 留白答题区
public var showHeader: Bool = true            // 页眉页码
public var itemsPerPage: Int = 2              // 每页题数
```

---

### SM2State + ReviewScheduler（复习调度）

```swift
// Engine/SM2State.swift
public struct SM2State: Sendable {
    public var easeFactor: Double    // 初始 2.5
    public var interval: Int        // 天
    public var repetitions: Int     // 连续正确次数
}

// Engine/ReviewScheduler.swift
public func scheduleNextReview(state: SM2State, rating: ReviewRating) -> SM2State
public func intervalDescription(for rating: ReviewRating, from state: SM2State) -> String
```

---

## SnapDrillData — Repository 公开方法

### ReviewRepository（题目）

```swift
// 查询
public func totalCount() throws -> Int
public func fetchPaginated(page: Int, pageSize: Int) throws -> ([ReviewItemModel], Int)
public func fetchFiltered(
    subjectNames: [String]?, sourceNames: [String]?, gradeNames: [String]?,
    tagNames: [String]?, searchText: String?,
    sortBy: FetchDescriptor<ReviewItemModel>.SortDescriptor?
) throws -> [ReviewItemModel]
public func fetchExportSnapshots() throws -> [ReviewExportSnapshot]

// 写入
public func insert(_ model: ReviewItemModel)         // 纯内存
public func insertAndSave(_ model: ReviewItemModel) throws  // 含持久化
public func saveContext() throws
public func rollbackContext()

// 删除（含图片清理）
public func delete(id: UUID) async throws
public func deleteAll() throws

// 分类引用计数和级联更新
public func countBySubject(name: String) throws -> Int
public func updateSubjectUsage(from oldName: String, to newName: String) throws
// Source, Grade, Tag 同理
```

---

### SubjectRepository / SourceRepository / GradeRepository（分类）

```swift
public func fetchAllModels() throws -> [Model]           // 按 sortOrder 升序
public func fetchModel(byName name: String) throws -> Model?
public func insert(_ model: Model)
public func insertAndSave(_ model: Model) throws         // 含名称唯一性校验
public func delete(id: UUID) throws
public func seedDefaultsIfNeeded()                        // 首次启动初始化
public func saveContext() throws
public func rollbackContext()
```

---

### TagRepository（标签）

```swift
public func fetchAllModels() throws -> [TagModel]
public func fetchOrCreateModel(name: String, colorHex: String) throws -> TagModel
public func delete(id: UUID) throws
public func deleteAll() throws
public func saveContext() throws
```

- `fetchOrCreateModel` 只 insert 不 save，调用方统一 saveContext()

---

### RepositoryContainer（聚合）

```swift
public let review: ReviewRepository
public let subject: SubjectRepository
public let source: SourceRepository
public let tag: TagRepository
public let grade: GradeRepository

public func deleteAllData() async throws              // 清空所有数据
public func collectBackupPayload() throws -> BackupPayload
public func restoreFromPayload(_ payload: BackupPayload) throws
```

Environment Key: `\.repositories`

---

### ProfileManager（多 Profile）

```swift
public private(set) var profiles: [Profile]
public private(set) var activeProfileId: UUID
public private(set) var activeContainer: ModelContainer
public private(set) var activeRepositories: RepositoryContainer
public private(set) var activeImageStorage: ImageStorage

public var activeProfile: Profile? { get }
public func createProfile(name: String) throws -> Profile
public func renameProfile(id: UUID, newName: String) throws
public func deleteProfile(id: UUID) async throws
public func switchProfile(id: UUID) throws
```

Environment Key: `\.profileManager`

---

### BackupService（备份/恢复）

```swift
public actor BackupService {
    public func createBackup(
        payload: BackupPayload, manifest: BackupManifest,
        imageBasePath: URL, onProgress: ProgressHandler?
    ) throws -> URL

    public func readManifest(from backupURL: URL) throws -> BackupManifest
    public func extractPayload(from backupURL: URL) throws -> BackupPayload
    public func restoreImages(
        from backupURL: URL, to imageBasePath: URL,
        onProgress: ProgressHandler?
    ) throws
}
```

---

## SnapDrillData — Model 字段

### ReviewItemModel

| 字段 | 类型 | 默认值 | 说明 |
|---|---|---|---|
| `id` | UUID | auto | 主键 |
| `content` | String? | nil | 题目文字（与 imagePath 至少一个非 nil） |
| `imagePath` | String? | nil | 题目图片相对路径 |
| `answerText` | String? | nil | 答案文字 |
| `answerImagePath` | String? | nil | 答案图片 |
| `subjectRawValue` | String | "其他" | 学科 |
| `sourceRawValue` | String | "其他" | 来源 |
| `grade` | String | "" | 年级 |
| `difficulty` | Int | 1 | 难度 1-5 |
| `tags` | [TagModel]? | [] | 多对多标签 |
| `easeFactor` | Double | 2.5 | SM-2 难度因子 |
| `interval` | Int | 0 | SM-2 间隔天数 |
| `repetitions` | Int | 0 | SM-2 连续正确次数 |
| `createdAt` | Date | now | 创建时间 |
| `lastReviewedAt` | Date | distantPast | 上次复习 |
| `nextReviewAt` | Date | distantPast | 下次复习 |

---

## 错误类型

| 模块 | 错误 | 场景 |
|---|---|---|
| Core | `OCRError.invalidImage` | CGImage 为 nil |
| Core | `ImageStorageError.invalidImageData` | JPEG 压缩失败 |
| Data | `DataError.duplicateName` | 学科/来源/年级重名 |
| Data | `PersistenceError.containerCreationFailed` | SwiftData 初始化失败 |
| Data | `BackupError.invalidArchive` | ZIP 文件损坏 |
| Data | `ProfileError.profileNotFound` | Profile ID 不存在 |
