# SnapDrill 基础设施速查

> **使用规则**：修改代码前，先用 `Grep` 或 `Read` 确认 API 真实存在，禁止凭名称推测。
> 本文件只列出**容易搞错的模式和关键导航**，完整签名请读源文件。

---

## 包 → 类型导航

| 包 | 关键类型 | 源文件路径提示 |
|---|---|---|
| **Core** | ReviewScheduler, SM2State, ReviewRating, Difficulty | Engine/ |
| **Core** | OCRService (actor), ImageStorage (struct) | Service/ |
| **Core** | PDFExportService, CaptureDraftService | Service/ |
| **Core** | AppConfiguration, FeatureFlags | Support/ |
| **Core** | PrivacyConsentService | Service/ |
| **Core** | SnapDrillLogger | Logger/ |
| **Core** | ServiceContainer (protocol), LiveServiceContainer, MockServiceContainer | DI/ |
| **Core** | AnalyticsServiceProtocol, OCRServiceProtocol, NotificationServiceProtocol, CaptureDraftServiceProtocol | 各 Service/ 或根目录 |
| **Data** | ReviewItemModel (@Model), TagModel, SubjectModel, SourceModel, GradeModel | 根目录 |
| **Data** | ReviewRepository, SubjectRepository, SourceRepository, GradeRepository, TagRepository | 根目录 |
| **Data** | RepositoryContainer | 根目录 |
| **Data** | BackupService (actor), BackupPayload, BackupManifest | 根目录 |
| **Data** | DataError, PersistenceError, BackupError | 根目录 |
| **UI** | FlipView, TagInputView, ImageCropperView, SnapDrillButton | 根目录 |
| **UI** | FeatureRouter (protocol), TabItem | Navigation/ |
| **UI** | AccessibilityHelper, AccessibilityAnnouncement | 根目录 |
| **Features** | 5 个 Feature 各有 View + ViewModel + Router | SnapDrillFeature{Name}/ |
| **Infrastructure** | FirebaseBootstrap, FirebaseAnalyticsService, FirebaseRemoteConfigService | 根目录 |

## @Environment 注入（唯一正确写法）

```swift
@Environment(\.repositories) var repositories: RepositoryContainer
@Environment(\.services) var services: any ServiceContainer
```

## Notification（禁止使用裸字符串）

```swift
// 定义在 Core/Support/ReviewDataNotification.swift
.reviewDataDidChange    // 题目数据写操作后 post
.switchToCaptureTab     // Tab 切换
.switchToLibraryTab
.switchToSettingsTab

// 发送：NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)
// 监听：.onReceive(NotificationCenter.default.publisher(for: .xxx)) { _ in ... }
```

## 日志（禁止 print）

```swift
SnapDrillLogger.generic.error("...")  // 子系统：.generic / .ui / .data / .network / .engine / .capture
```

## 常见错误防范

| 错误写法 | 正确写法 |
|---|---|
| `ReviewDataNotification.post()` | `NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)` |
| `repository.save(model)` | `repository.insertAndSave(model)` 或 `repository.saveContext()` |
| `repository.fetch(id:)` | `repository.fetchModel(by: id)` |
| `SnapDrillLogger.log("...")` | `SnapDrillLogger.generic.error("...")` |
| `ReviewItemModel.save()` | `@Model` 无 save()，通过 Repository 保存 |
| `SM2State.update(...)` | SM2State 是值类型，`scheduler.scheduleNextReview()` 返回新值 |

## 关键设计约束

- SM2State 是**值类型**（struct），调度返回新值，不原地修改
- Repository 方法 `insert()` 只做内存插入不 save，调用方须 `saveContext()`；`insertAndSave()` 才写磁盘
- `delete(id:)` 和 `deleteAllData()` 是 `async`（内部含文件 I/O）
- ImageStorage 的 `loadImage()` 是同步（仅 PDF 渲染用），日常用 `loadImageAsync()` 或 `loadDownsampledImage()`
- BackupService 是 **actor**（线程安全，不在 MainActor 上）
- Infrastructure 包**仅 App target 可 import**，其他包禁止
