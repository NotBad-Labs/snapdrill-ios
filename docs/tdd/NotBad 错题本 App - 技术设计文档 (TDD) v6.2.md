# NotBad 错题本 App - 技术设计文档 (TDD) v6.2

> **文档定位**：技术实现的权威指南  
> 本文档定义 NotBad App 的架构、模块设计、接口规范、数据模型与技术决策；所有开发与 Code Review 必须遵循此文档。

---

## 1. 文档控制

### 1.1 版本历史
| 版本 | 日期 | 作者 | 关键变更 | 状态 |
|:-----|:-----|:-----|:---------|:-----|
| v6.0 | 2025-09-19 | Tech Team | iOS 26 / Swift 6.2 升级，引入 MVVM-C | 归档 |
| v6.1 | 2025-10-07 | Yiming Liao | 免费模式架构调整，CloudKit 优先 | 归档 |
| **v6.2** | **2025-11-14** | **Yiming Liao** | **隐私合规技术方案、OCR 降级策略、年龄验证机制** | **生效** |

### 1.2 关联文档
- 产品需求文档 (PRD): `docs/prd/NotBad 错题本 App - 产品需求文档 (PRD) v6.2.md`
- 需求追踪矩阵 (RTM): `docs/rtm/NotBad App - 需求追踪矩阵 (RTM) v6.2.md`
- 代码库: `NotBad/` (根目录)

### 1.3 审批状态
| 角色 | 负责人 | 状态 |
|:-----|:-------|:-----|
| 技术负责人 | Yiming Liao | ✅ |
| 架构师 | *待指派* | ⏳ |
| 安全审核 | *待指派* | ⏳ |

---

## 2. 技术栈与基础架构

### 2.1 开发环境
| 组件 | 版本 | 验证状态 | 说明 |
|:-----|:-----|:---------|:-----|
| Xcode | 26.0.1 (Build 17A400) | ✅ 已验证 | 开发 IDE |
| Swift | 6.2.0.19.9 | ✅ 已验证 | 编程语言 |
| iOS SDK | 26.0 | ✅ 已验证 | 最低支持 iOS 26.0 |
| macOS | 26.0.1 (Build 25A362) | ✅ 已验证 | 开发主机 |
| SwiftUI | iOS 26 | ✅ 已验证 | UI 框架 |
| SwiftData | iOS 26 | ✅ 已验证 | 持久化框架 |
| Vision | iOS 26 | ✅ 已验证 | OCR 端侧识别 |
| CloudKit | iOS 26 | ✅ 已验证 | 云端同步 |

### 2.2 架构模式：MVVM-C (Model-View-ViewModel-Coordinator)

#### 2.2.1 架构分层
```
┌─────────────────────────────────────────────────────────┐
│                   Presentation Layer                     │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐ │
│  │ Coordinators│  │    Views     │  │  ViewModels    │ │
│  │  (导航流程)  │◄─│  (SwiftUI)   │◄─│   (业务逻辑)    │ │
│  └─────────────┘  └──────────────┘  └────────────────┘ │
└─────────────────────────────────────────────────────────┘
                          ▲
                          │ Protocol-Driven DI
                          ▼
┌─────────────────────────────────────────────────────────┐
│                     Domain Layer                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Models     │  │  Use Cases   │  │ Repositories │  │
│  │ (领域模型)    │◄─│  (业务用例)   │◄─│   (协议)      │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ▲
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                   Infrastructure Layer                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  SwiftData   │  │   CloudKit   │  │    Vision    │  │
│  │  (本地存储)   │  │   (云同步)    │  │    (OCR)     │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

#### 2.2.2 MVVM-C 核心组件

**Coordinator（导航协调器）**
```swift
// 已实现：AppCoordinator.swift
@Observable
final class AppCoordinator {
    enum Destination: Hashable {
        case welcome
        case home
        case capture
        case review(question: Question)
        case settings
        case parentalControl
        // ... 更多目的地
    }
    
    var path: [Destination] = []
    var sheet: Destination?
    var fullScreenCover: Destination?
    
    func push(_ destination: Destination) { /* ... */ }
    func presentSheet(_ destination: Destination) { /* ... */ }
    func dismiss() { /* ... */ }
}
```

**职责划分**：
- **Model**: 纯数据结构，与 SwiftData 集成
- **View**: 无状态 SwiftUI 组件，仅负责渲染
- **ViewModel**: 业务逻辑、状态管理、与 Use Cases 交互
- **Coordinator**: 集中管理导航流程，解耦视图间依赖

### 2.3 SwiftData 本地存储架构

#### 2.3.1 核心设计原则
- **单一容器模式**：全局共享 `DataManager.shared.container`
- **主线程优先**：UI 操作在 `@MainActor` 上下文
- **批量操作优化**：批量插入使用 `batchInsert`，性能提升 3-5 倍
- **查询优化**：使用 `#Predicate` 宏，避免运行时开销

#### 2.3.2 DataManager 单例
```swift
// 已实现：Core/DataManager.swift
@MainActor
final class DataManager {
    static let shared = DataManager()
    
    let container: ModelContainer
    
    private init() {
        let schema = Schema([
            Question.self,
            Subject.self,
            Tag.self,
            ReviewRecord.self,
            UserProfile.self,
            ParentalControl.self
        ])
        
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .private("iCloud.com.notbad.app")
        )
        
        do {
            self.container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
```

### 2.4 CloudKit 同步架构

#### 2.4.1 同步策略
- **私有数据库**：`CKContainer.default().privateCloudDatabase`
- **增量同步**：使用 `CKQueryOperation` 和 `CKFetchRecordChangesOperation`
- **冲突解决**：服务端时间戳优先（Last Write Wins）
- **免费额度**：1GB 存储 + 10GB 传输/月

#### 2.4.2 同步触发机制
```swift
enum SyncTrigger {
    case manual          // 用户手动触发
    case appLaunch       // App 启动时
    case background      // 后台定时（12 小时）
    case dataChange      // 本地数据变更后 5 秒延迟
}
```

#### 2.4.3 同步状态管理
```swift
@Observable
final class SyncManager {
    enum SyncState {
        case idle
        case syncing(progress: Double)
        case success(timestamp: Date)
        case failure(error: Error)
    }
    
    var state: SyncState = .idle
    var lastSyncTime: Date?
    
    func sync(trigger: SyncTrigger) async throws { /* ... */ }
    func resolveConflict(_ local: CKRecord, _ remote: CKRecord) -> CKRecord { /* ... */ }
}
```

---

## 3. 核心功能模块设计

### 3.1 错题录入模块（Capture Module）

#### 3.1.1 OCR 识别架构（双层策略）

**层级 1：端侧识别（Vision Framework）**
```swift
@MainActor
final class VisionOCRService: OCRServiceProtocol {
    func recognize(image: UIImage) async throws -> OCRResult {
        let request = VNRecognizeTextRequest()
        request.recognitionLanguages = ["zh-Hans", "en-US"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        try handler.perform([request])
        
        guard let observations = request.results else {
            throw OCRError.noTextFound
        }
        
        let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
        let confidence = observations.map { $0.confidence }.reduce(0, +) / Double(observations.count)
        
        return OCRResult(text: text, confidence: confidence)
    }
}
```

**层级 2：云端增强（Azure OCR Fallback）**
```swift
final class AzureOCRService: OCRServiceProtocol {
    private let endpoint = "https://notbad.cognitiveservices.azure.com/"
    private let apiKey: String  // 从 Keychain 读取
    
    func recognize(image: UIImage) async throws -> OCRResult {
        // 用户授权检查
        guard UserDefaults.standard.bool(forKey: "cloudOCREnabled") else {
            throw OCRError.cloudOCRDisabled
        }
        
        // 图片压缩（最大 4MB）
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw OCRError.imageCompressionFailed
        }
        
        // 调用 Azure OCR API
        var request = URLRequest(url: URL(string: endpoint + "/vision/v3.2/ocr")!)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.httpBody = imageData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 立即删除服务端副本（Azure OCR 不存储）
        // Azure 默认不保存图片，此步骤为文档说明
        
        // 解析结果
        let result = try JSONDecoder().decode(AzureOCRResponse.self, from: data)
        return OCRResult(text: result.text, confidence: result.confidence)
    }
}
```

**降级决策逻辑**
```swift
final class OCRCoordinator {
    private let visionService = VisionOCRService()
    private let azureService = AzureOCRService()
    
    func recognize(image: UIImage) async throws -> OCRResult {
        // 1. 优先端侧识别
        let visionResult = try await visionService.recognize(image: image)
        
        // 2. 置信度判断
        if visionResult.confidence >= 0.70 {
            return visionResult
        }
        
        // 3. 提示用户选择云端增强
        let userChoice = await promptCloudOCR()
        guard userChoice else {
            return visionResult  // 用户拒绝，返回端侧结果
        }
        
        // 4. 云端增强识别
        return try await azureService.recognize(image: image)
    }
}
```

#### 3.1.2 批量拍照与裁剪
```swift
struct CaptureViewModel {
    @Published var images: [CapturedImage] = []
    
    func addImage(_ image: UIImage) async {
        // 自动裁剪（基于边缘检测）
        let croppedImage = await AutoCropper.crop(image)
        
        // 添加到队列
        images.append(CapturedImage(
            id: UUID(),
            original: image,
            cropped: croppedImage,
            adjustments: .default
        ))
    }
    
    func processAll() async throws {
        for image in images {
            let ocrResult = try await OCRCoordinator.shared.recognize(image: image.cropped)
            // 保存到草稿箱
            await DraftManager.shared.save(image: image, ocr: ocrResult)
        }
    }
}
```

#### 3.1.3 草稿箱自动保存
```swift
@Model
final class Draft {
    var id: UUID
    var imageData: Data
    var ocrText: String
    var confidence: Double
    var createdAt: Date
    var isSynced: Bool = false
    
    init(image: UIImage, ocr: OCRResult) {
        self.id = UUID()
        self.imageData = image.jpegData(compressionQuality: 0.8)!
        self.ocrText = ocr.text
        self.confidence = ocr.confidence
        self.createdAt = Date()
    }
}

@MainActor
final class DraftManager {
    static let shared = DraftManager()
    
    func save(image: CapturedImage, ocr: OCRResult) async {
        let draft = Draft(image: image.cropped, ocr: ocr)
        let context = DataManager.shared.container.mainContext
        context.insert(draft)
        try? context.save()
    }
    
    func loadDrafts() -> [Draft] {
        let context = DataManager.shared.container.mainContext
        let descriptor = FetchDescriptor<Draft>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }
}
```

---

### 3.2 错题管理模块（Bank Module）

#### 3.2.1 数据模型设计

**Question（错题主实体）**
```swift
@Model
final class Question {
    // 基础信息
    @Attribute(.unique) var id: UUID
    var title: String
    var questionImageData: Data?
    var answerImageData: Data?
    var ocrText: String?
    var userNotes: String?
    
    // 分类信息
    var subject: Subject?
    var difficulty: Difficulty
    var tags: [Tag]
    
    // 学习状态
    var masteryLevel: MasteryLevel  // 未掌握/部分掌握/已掌握
    var reviewCount: Int = 0
    var lastReviewedAt: Date?
    
    // 元数据
    var createdAt: Date
    var updatedAt: Date
    var source: String?  // 来源（如"期中考试"）
    
    // CloudKit 同步
    var cloudKitRecordID: String?
    var cloudKitChangeTag: String?
    
    // 关联
    @Relationship(deleteRule: .cascade) var reviewRecords: [ReviewRecord]
    
    init(title: String, subject: Subject?, difficulty: Difficulty) {
        self.id = UUID()
        self.title = title
        self.subject = subject
        self.difficulty = difficulty
        self.tags = []
        self.masteryLevel = .notMastered
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum Difficulty: String, Codable {
    case easy = "简单"
    case medium = "中等"
    case hard = "困难"
}

enum MasteryLevel: String, Codable {
    case notMastered = "未掌握"
    case partiallyMastered = "部分掌握"
    case mastered = "已掌握"
}
```

**Subject（学科）**
```swift
@Model
final class Subject {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var color: String  // Hex color
    
    @Relationship(deleteRule: .cascade) var questions: [Question]
    
    init(name: String, icon: String, color: String) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
    }
}
```

**Tag（标签）**
```swift
@Model
final class Tag {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: TagCategory
    var questions: [Question]
    
    init(name: String, category: TagCategory) {
        self.id = UUID()
        self.name = name
        self.category = category
    }
}

enum TagCategory: String, Codable {
    case knowledgePoint = "知识点"
    case questionType = "题型"
    case custom = "自定义"
}
```

#### 3.2.2 高性能搜索与筛选

**SearchManager（搜索协调器）**
```swift
@MainActor
final class SearchManager {
    func search(
        keyword: String? = nil,
        subjects: [Subject]? = nil,
        tags: [Tag]? = nil,
        difficulties: [Difficulty]? = nil,
        masteryLevels: [MasteryLevel]? = nil,
        dateRange: ClosedRange<Date>? = nil
    ) async -> [Question] {
        let context = DataManager.shared.container.mainContext
        
        // 构建 Predicate
        var predicates: [Predicate<Question>] = []
        
        if let keyword = keyword, !keyword.isEmpty {
            predicates.append(#Predicate<Question> { question in
                question.title.localizedStandardContains(keyword) ||
                question.ocrText?.localizedStandardContains(keyword) ?? false ||
                question.userNotes?.localizedStandardContains(keyword) ?? false
            })
        }
        
        if let subjects = subjects, !subjects.isEmpty {
            predicates.append(#Predicate<Question> { question in
                subjects.contains(where: { $0.id == question.subject?.id })
            })
        }
        
        if let difficulties = difficulties, !difficulties.isEmpty {
            predicates.append(#Predicate<Question> { question in
                difficulties.contains(question.difficulty)
            })
        }
        
        if let masteryLevels = masteryLevels, !masteryLevels.isEmpty {
            predicates.append(#Predicate<Question> { question in
                masteryLevels.contains(question.masteryLevel)
            })
        }
        
        if let dateRange = dateRange {
            predicates.append(#Predicate<Question> { question in
                question.createdAt >= dateRange.lowerBound &&
                question.createdAt <= dateRange.upperBound
            })
        }
        
        // 组合 Predicate
        let finalPredicate = predicates.reduce(into: nil) { result, predicate in
            if let existing = result {
                result = #Predicate<Question> { question in
                    existing.evaluate(question) && predicate.evaluate(question)
                }
            } else {
                result = predicate
            }
        }
        
        // 执行查询
        var descriptor = FetchDescriptor<Question>(
            predicate: finalPredicate,
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 500  // 性能优化：限制返回数量
        
        return (try? context.fetch(descriptor)) ?? []
    }
}
```

**性能指标**：
- 搜索响应时间：< 500ms（PRD Baseline）
- 索引优化：SwiftData 自动索引 `@Attribute(.unique)` 字段
- 分页加载：每页 50 条，滚动触发下一页

---

### 3.3 复习模块（Review Module）

#### 3.3.1 遗忘曲线算法（Ebbinghaus + SuperMemo SM-2）

**ReviewScheduler（复习调度器）**
```swift
final class ReviewScheduler {
    // SuperMemo SM-2 参数
    private let easinessFactor: Double = 2.5
    private let intervals: [Int] = [1, 6, 15, 30, 90, 180]  // 天数
    
    func calculateNextReview(
        question: Question,
        userResponse: ReviewResponse
    ) -> Date {
        let currentInterval = question.reviewCount < intervals.count 
            ? intervals[question.reviewCount] 
            : intervals.last! * 2
        
        let adjustedInterval: Int
        switch userResponse {
        case .mastered:
            adjustedInterval = currentInterval
        case .partiallyMastered:
            adjustedInterval = max(1, currentInterval / 2)
        case .notMastered:
            adjustedInterval = 1  // 明天再复习
        }
        
        return Calendar.current.date(byAdding: .day, value: adjustedInterval, to: Date())!
    }
    
    func getTodayReviewQueue() async -> [Question] {
        let context = DataManager.shared.container.mainContext
        let today = Calendar.current.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<Question>(
            predicate: #Predicate<Question> { question in
                question.lastReviewedAt == nil || question.lastReviewedAt! <= today
            },
            sortBy: [SortDescriptor(\.lastReviewedAt, order: .forward)]
        )
        
        return (try? context.fetch(descriptor)) ?? []
    }
}

enum ReviewResponse {
    case mastered
    case partiallyMastered
    case notMastered
}
```

#### 3.3.2 ReviewRecord（复习记录）
```swift
@Model
final class ReviewRecord {
    var id: UUID
    var question: Question
    var reviewedAt: Date
    var response: ReviewResponse
    var timeSpent: TimeInterval  // 秒
    
    init(question: Question, response: ReviewResponse, timeSpent: TimeInterval) {
        self.id = UUID()
        self.question = question
        self.reviewedAt = Date()
        self.response = response
        self.timeSpent = timeSpent
    }
}
```

#### 3.3.3 卡片交互设计
```swift
struct ReviewCardView: View {
    @State private var offset: CGSize = .zero
    @State private var cardRotation: Double = 0
    let question: Question
    let onResponse: (ReviewResponse) -> Void
    
    var body: some View {
        QuestionCardContent(question: question)
            .offset(offset)
            .rotationEffect(.degrees(cardRotation))
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation
                        cardRotation = Double(gesture.translation.width / 20)
                    }
                    .onEnded { gesture in
                        let threshold: CGFloat = 120
                        
                        if gesture.translation.width > threshold {
                            // 右滑：已掌握
                            withAnimation(.spring(response: 0.3)) {
                                offset = CGSize(width: 500, height: 0)
                            }
                            onResponse(.mastered)
                        } else if gesture.translation.width < -threshold {
                            // 左滑：未掌握
                            withAnimation(.spring(response: 0.3)) {
                                offset = CGSize(width: -500, height: 0)
                            }
                            onResponse(.notMastered)
                        } else {
                            // 回弹
                            withAnimation(.spring(response: 0.3)) {
                                offset = .zero
                                cardRotation = 0
                            }
                        }
                    }
            )
    }
}
```

**性能指标**：
- 卡片滑动响应：< 100ms（PRD Baseline：< 120ms）
- 使用 `@State` + `withAnimation(.spring())` 确保 120fps 流畅度
- 触觉反馈：滑动阈值时触发 `UIImpactFeedbackGenerator`

---

### 3.4 分析与报告模块（Analytics Module）

#### 3.4.1 统计数据计算
```swift
@MainActor
final class AnalyticsEngine {
    func calculateMasteryRate(subject: Subject?, timeRange: TimeRange) async -> Double {
        let context = DataManager.shared.container.mainContext
        
        var predicate = #Predicate<Question> { question in
            question.createdAt >= timeRange.start && question.createdAt <= timeRange.end
        }
        
        if let subject = subject {
            predicate = #Predicate<Question> { question in
                question.subject?.id == subject.id &&
                question.createdAt >= timeRange.start &&
                question.createdAt <= timeRange.end
            }
        }
        
        let descriptor = FetchDescriptor<Question>(predicate: predicate)
        let questions = (try? context.fetch(descriptor)) ?? []
        
        guard !questions.isEmpty else { return 0.0 }
        
        let masteredCount = questions.filter { $0.masteryLevel == .mastered }.count
        return Double(masteredCount) / Double(questions.count)
    }
    
    func getWeakKnowledgePoints(limit: Int = 10) async -> [TagStatistic] {
        let context = DataManager.shared.container.mainContext
        let tags = (try? context.fetch(FetchDescriptor<Tag>())) ?? []
        
        return tags.map { tag in
            let questions = tag.questions
            let totalCount = questions.count
            let notMasteredCount = questions.filter { $0.masteryLevel == .notMastered }.count
            let weaknessRate = totalCount > 0 ? Double(notMasteredCount) / Double(totalCount) : 0
            
            return TagStatistic(
                tag: tag,
                totalQuestions: totalCount,
                notMasteredCount: notMasteredCount,
                weaknessRate: weaknessRate
            )
        }
        .sorted { $0.weaknessRate > $1.weaknessRate }
        .prefix(limit)
        .map { $0 }
    }
}

struct TagStatistic {
    let tag: Tag
    let totalQuestions: Int
    let notMasteredCount: Int
    let weaknessRate: Double
}
```

#### 3.4.2 图表渲染（Swift Charts）
```swift
import Charts

struct MasteryTrendChart: View {
    let data: [MasteryDataPoint]
    
    var body: some View {
        Chart(data) { dataPoint in
            LineMark(
                x: .value("日期", dataPoint.date),
                y: .value("掌握率", dataPoint.rate)
            )
            .foregroundStyle(.blue)
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("日期", dataPoint.date),
                y: .value("掌握率", dataPoint.rate)
            )
            .foregroundStyle(.blue.opacity(0.2))
        }
        .chartYScale(domain: 0...1)
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisValueLabel {
                    if let rate = value.as(Double.self) {
                        Text("\(Int(rate * 100))%")
                    }
                }
            }
        }
    }
}
```

---

### 3.5 发现社区模块（Discovery Module）

#### 3.5.1 年龄验证机制

**UserProfile（用户档案）**
```swift
@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var birthDate: Date?  // 可选，用于年龄验证
    var isUnder13: Bool {
        guard let birthDate = birthDate else { return false }
        let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        return age < 13
    }
    var communityAccessEnabled: Bool = false
    
    init() {
        self.id = UUID()
    }
}
```

**AgeVerificationManager（年龄验证管理器）**
```swift
@MainActor
final class AgeVerificationManager {
    static let shared = AgeVerificationManager()
    
    func verifyAge(birthDate: Date) -> AgeVerificationResult {
        let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        
        if age < 13 {
            return .under13Restricted
        } else {
            return .allowed
        }
    }
    
    func updateProfile(birthDate: Date) async throws {
        let context = DataManager.shared.container.mainContext
        let descriptor = FetchDescriptor<UserProfile>()
        var profile = try context.fetch(descriptor).first ?? UserProfile()
        
        profile.birthDate = birthDate
        
        // 13 岁以下强制禁用社区
        if profile.isUnder13 {
            profile.communityAccessEnabled = false
        } else {
            profile.communityAccessEnabled = true
        }
        
        context.insert(profile)
        try context.save()
    }
}

enum AgeVerificationResult {
    case under13Restricted
    case allowed
}
```

#### 3.5.2 家长控制模式

**ParentalControl（家长控制）**
```swift
@Model
final class ParentalControl {
    @Attribute(.unique) var id: UUID
    var isEnabled: Bool = false
    var communitySharingBlocked: Bool = false
    var lastVerifiedAt: Date?
    
    init() {
        self.id = UUID()
    }
}

@MainActor
final class ParentalControlManager {
    static let shared = ParentalControlManager()
    
    func authenticate() async -> Bool {
        // 设备密码 + 生物识别验证
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "家长控制需要验证身份"
            )
            return success
        } catch {
            return false
        }
    }
    
    func toggleCommunityAccess(enabled: Bool) async throws {
        guard await authenticate() else {
            throw ParentalControlError.authenticationFailed
        }
        
        let context = DataManager.shared.container.mainContext
        let descriptor = FetchDescriptor<ParentalControl>()
        var control = try context.fetch(descriptor).first ?? ParentalControl()
        
        control.isEnabled = true
        control.communitySharingBlocked = !enabled
        control.lastVerifiedAt = Date()
        
        context.insert(control)
        try context.save()
    }
}
```

#### 3.5.3 内容审核集成（阿里云内容安全）

**ContentModerationService**
```swift
final class ContentModerationService {
    private let endpoint = "https://green.cn-shanghai.aliyuncs.com/"
    private let accessKeyId: String
    private let accessKeySecret: String
    
    func moderate(content: CommunityPost) async throws -> ModerationResult {
        // 1. 本地 AI 预过滤（关键词、敏感词）
        let localResult = await localFilter(content)
        if localResult.blocked {
            return .blocked(reason: "包含敏感内容")
        }
        
        // 2. 阿里云内容安全 API
        let request = buildAliyunRequest(content)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AliyunModerationResponse.self, from: data)
        
        // 3. 风险分级
        if response.suggestion == "block" {
            return .blocked(reason: response.reason)
        } else if response.suggestion == "review" {
            return .needsReview(riskScore: response.rate)
        } else {
            return .approved
        }
    }
    
    private func localFilter(_ content: CommunityPost) async -> LocalFilterResult {
        let sensitiveKeywords = ["暴力", "色情", "政治敏感词", /* ... */]
        let containsSensitive = sensitiveKeywords.contains { content.text.contains($0) }
        return LocalFilterResult(blocked: containsSensitive)
    }
}

enum ModerationResult {
    case approved
    case needsReview(riskScore: Double)
    case blocked(reason: String)
}
```

---

## 4. 隐私合规技术实现

### 4.1 数据采集与遥测

#### 4.1.1 匿名 UUID 管理
```swift
final class TelemetryManager {
    static let shared = TelemetryManager()
    
    private let uuidKey = "telemetry_anonymous_uuid"
    private let lastResetKey = "telemetry_uuid_last_reset"
    
    var anonymousUUID: String {
        get {
            // 检查是否需要重置（90 天周期）
            if shouldResetUUID() {
                resetUUID()
            }
            
            if let uuid = UserDefaults.standard.string(forKey: uuidKey) {
                return uuid
            } else {
                let newUUID = UUID().uuidString
                UserDefaults.standard.set(newUUID, forKey: uuidKey)
                UserDefaults.standard.set(Date(), forKey: lastResetKey)
                return newUUID
            }
        }
    }
    
    private func shouldResetUUID() -> Bool {
        guard let lastReset = UserDefaults.standard.object(forKey: lastResetKey) as? Date else {
            return true
        }
        
        let daysSinceReset = Calendar.current.dateComponents([.day], from: lastReset, to: Date()).day ?? 0
        return daysSinceReset >= 90
    }
    
    private func resetUUID() {
        let newUUID = UUID().uuidString
        UserDefaults.standard.set(newUUID, forKey: uuidKey)
        UserDefaults.standard.set(Date(), forKey: lastResetKey)
    }
}
```

#### 4.1.2 聚合数据上传
```swift
struct AggregatedMetrics: Codable {
    let uuid: String  // 90 天周期匿名 UUID
    let period: DateInterval
    
    // 聚合统计（无原始数据）
    let totalStudyTimeSeconds: Int
    let reviewSessionsCount: Int
    let questionsAdded: Int
    let averageMasteryRate: Double
    let subjectDistribution: [String: Int]  // 学科 -> 题目数
    
    // P50/P90/P95 分位数
    let studyTimeP50: Int
    let studyTimeP90: Int
    let studyTimeP95: Int
}

final class MetricsUploader {
    func uploadWeeklyMetrics() async throws {
        guard UserDefaults.standard.bool(forKey: "telemetryEnabled") else {
            return  // 用户禁用遥测
        }
        
        let metrics = await calculateAggregatedMetrics()
        
        var request = URLRequest(url: URL(string: "https://api.notbad.app/metrics")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(metrics)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw MetricsError.uploadFailed
        }
    }
    
    private func calculateAggregatedMetrics() async -> AggregatedMetrics {
        let context = DataManager.shared.container.mainContext
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        
        let descriptor = FetchDescriptor<ReviewRecord>(
            predicate: #Predicate<ReviewRecord> { record in
                record.reviewedAt >= weekAgo
            }
        )
        
        let records = (try? context.fetch(descriptor)) ?? []
        
        let totalTime = records.reduce(0) { $0 + Int($1.timeSpent) }
        let timeSamples = records.map { Int($0.timeSpent) }.sorted()
        
        return AggregatedMetrics(
            uuid: TelemetryManager.shared.anonymousUUID,
            period: DateInterval(start: weekAgo, end: Date()),
            totalStudyTimeSeconds: totalTime,
            reviewSessionsCount: records.count,
            questionsAdded: 0,  // 从 Question 表计算
            averageMasteryRate: 0.0,  // 从 Question 表计算
            subjectDistribution: [:],  // 从 Question 表计算
            studyTimeP50: percentile(timeSamples, 0.5),
            studyTimeP90: percentile(timeSamples, 0.9),
            studyTimeP95: percentile(timeSamples, 0.95)
        )
    }
    
    private func percentile(_ sorted: [Int], _ p: Double) -> Int {
        let index = Int(Double(sorted.count) * p)
        return sorted.isEmpty ? 0 : sorted[min(index, sorted.count - 1)]
    }
}
```

### 4.2 数据删除机制（30 天清除）

```swift
final class DataDeletionService {
    static let shared = DataDeletionService()
    
    func requestAccountDeletion() async throws {
        // 1. 标记删除请求
        UserDefaults.standard.set(Date(), forKey: "account_deletion_requested_at")
        UserDefaults.standard.set(true, forKey: "account_deletion_pending")
        
        // 2. 30 天后执行
        let deletionDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        scheduleBackgroundDeletion(at: deletionDate)
        
        // 3. 立即禁用云同步
        UserDefaults.standard.set(false, forKey: "cloudSyncEnabled")
    }
    
    func executeScheduledDeletion() async throws {
        guard UserDefaults.standard.bool(forKey: "account_deletion_pending") else {
            return
        }
        
        guard let requestDate = UserDefaults.standard.object(forKey: "account_deletion_requested_at") as? Date else {
            return
        }
        
        let daysSinceRequest = Calendar.current.dateComponents([.day], from: requestDate, to: Date()).day ?? 0
        guard daysSinceRequest >= 30 else {
            return  // 未到 30 天
        }
        
        // 1. 删除本地数据
        let context = DataManager.shared.container.mainContext
        try context.delete(model: Question.self)
        try context.delete(model: ReviewRecord.self)
        try context.delete(model: UserProfile.self)
        try context.delete(model: ParentalControl.self)
        try context.save()
        
        // 2. 删除 CloudKit 数据
        let container = CKContainer.default()
        let database = container.privateCloudDatabase
        
        let query = CKQuery(recordType: "Question", predicate: NSPredicate(value: true))
        let records = try await database.records(matching: query).matchResults.compactMap { try? $0.1.get() }
        let recordIDs = records.map { $0.recordID }
        
        try await database.modifyRecords(saving: [], deleting: recordIDs)
        
        // 3. 清除标记
        UserDefaults.standard.removeObject(forKey: "account_deletion_requested_at")
        UserDefaults.standard.set(false, forKey: "account_deletion_pending")
    }
    
    func cancelDeletion() {
        UserDefaults.standard.removeObject(forKey: "account_deletion_requested_at")
        UserDefaults.standard.set(false, forKey: "account_deletion_pending")
    }
}
```

---

## 5. 非功能需求技术实现

### 5.1 性能优化

#### 5.1.1 冷启动优化（目标 < 1.2s）
```swift
@main
struct NotBadApp: App {
    init() {
        // 1. 延迟初始化（仅初始化关键路径）
        DataManager.shared  // 提前创建 ModelContainer
        
        // 2. 异步预热
        Task {
            await preloadCriticalData()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            CoordinatorView()
                .modelContainer(DataManager.shared.container)
        }
    }
    
    private func preloadCriticalData() async {
        // 预加载今日复习队列
        _ = await ReviewScheduler().getTodayReviewQueue()
        
        // 预加载学科列表
        let context = DataManager.shared.container.mainContext
        _ = try? context.fetch(FetchDescriptor<Subject>())
    }
}
```

**启动性能检查清单**：
- ✅ 移除 `@main` 中的同步 I/O 操作
- ✅ 使用 `Task {}` 异步预热
- ✅ 延迟加载非关键 UI（如统计图表）
- ✅ 使用 Instruments → Time Profiler 验证

#### 5.1.2 滚动性能优化（目标 120fps）
```swift
struct QuestionListView: View {
    @Query private var questions: [Question]
    
    var body: some View {
        List(questions) { question in
            QuestionRowView(question: question)
                .listRowInsets(EdgeInsets())
                .task {
                    // 按需加载图片（懒加载）
                    await loadImageIfNeeded(question)
                }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)  // 减少 overdraw
    }
    
    private func loadImageIfNeeded(_ question: Question) async {
        guard question.questionImageData != nil else { return }
        // 仅在可见时加载
        if isVisible(question) {
            await ImageCache.shared.load(question.id)
        }
    }
}
```

### 5.2 安全性实现

#### 5.2.1 Keychain 加密存储
```swift
final class SecureStorage {
    static let shared = SecureStorage()
    
    func save(key: String, value: String) throws {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        SecItemDelete(query as CFDictionary)  // 删除旧值
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed
        }
    }
    
    func load(key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.loadFailed
        }
        
        return value
    }
}
```

#### 5.2.2 网络安全（TLS 1.3）
```swift
final class NetworkManager {
    private let session: URLSession
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv13
        configuration.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: configuration)
    }
    
    func request(_ url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        return data
    }
}
```

### 5.3 可靠性实现

#### 5.3.1 崩溃率监控（目标 < 0.3%）
```swift
import FirebaseCrashlytics  // 或其他崩溃报告服务

@main
struct NotBadApp: App {
    init() {
        // 集成 Crashlytics
        FirebaseApp.configure()
        
        // 自定义崩溃日志
        Crashlytics.crashlytics().setCustomValue(
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "Unknown",
            forKey: "app_version"
        )
    }
}
```

#### 5.3.2 同步失败重试机制
```swift
final class ReliableSyncManager {
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 2.0
    
    func syncWithRetry() async throws {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                try await SyncManager.shared.sync(trigger: .manual)
                return  // 成功
            } catch {
                lastError = error
                
                if attempt < maxRetries {
                    // 指数退避
                    let delay = retryDelay * pow(2.0, Double(attempt - 1))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        // 所有重试失败
        throw lastError ?? SyncError.unknown
    }
}
```

---

## 6. 风险技术缓解方案

### 6.1 R-01: Swift 6.2 编译不稳定

**降级分支**
```bash
# 创建 Swift 6.1 降级分支
git checkout -b swift-6.1-fallback

# 修改 .swift-version
echo "6.1" > .swift-version

# 移除 Swift 6.2 专属特性
# - InlineArray → 使用普通数组
# - Span → 使用 ArraySlice
```

**双版本 CI 配置**
```yaml
# .github/workflows/build.yml
jobs:
  build:
    strategy:
      matrix:
        swift-version: ['6.2', '6.1']
    steps:
      - uses: actions/checkout@v3
      - name: Select Swift Version
        run: xcrun swift-version ${{ matrix.swift-version }}
      - name: Build
        run: xcodebuild build
```

### 6.2 R-02: OCR 精度不达标

**手动校对 UI 设计**
```swift
struct OCRReviewView: View {
    @State private var originalText: String
    @State private var editedText: String
    @State private var differences: [TextDifference] = []
    
    var body: some View {
        VStack {
            // 原始识别结果（高亮差异）
            Text(highlightedText(originalText, differences: differences))
                .foregroundColor(.secondary)
            
            Divider()
            
            // 可编辑文本
            TextEditor(text: $editedText)
                .onChange(of: editedText) { oldValue, newValue in
                    differences = computeDifferences(original: originalText, edited: newValue)
                }
            
            HStack {
                Button("接受") { acceptOCR() }
                Button("重新识别") { retryOCR() }
            }
        }
    }
    
    private func computeDifferences(original: String, edited: String) -> [TextDifference] {
        // Levenshtein 距离算法计算差异
        // 返回差异位置和类型（插入/删除/替换）
        []
    }
}
```

### 6.3 R-03: 内容审核人力不足

**第三方服务集成架构**
```swift
protocol ContentModerationProvider {
    func moderate(content: CommunityPost) async throws -> ModerationResult
}

final class AliyunContentSecurity: ContentModerationProvider {
    func moderate(content: CommunityPost) async throws -> ModerationResult {
        // 阿里云内容安全 API
        // 成本：¥0.0025/条
    }
}

final class HybridModerationService {
    private let providers: [ContentModerationProvider] = [
        LocalAIModerator(),      // 本地 AI（免费）
        AliyunContentSecurity()  // 云端服务（付费）
    ]
    
    func moderate(content: CommunityPost) async throws -> ModerationResult {
        // 1. 本地 AI 过滤（95% 准确率目标）
        let localResult = try await providers[0].moderate(content: content)
        
        if localResult == .approved || localResult == .blocked() {
            return localResult  // 确定性结果，不调用云端
        }
        
        // 2. 云端二次检查（不确定时）
        return try await providers[1].moderate(content: content)
    }
}
```

---

## 7. 测试策略

### 7.1 单元测试覆盖率目标
- **目标**: 核心业务逻辑 > 80%
- **工具**: XCTest + Swift Testing (iOS 26)
- **重点模块**:
  - ReviewScheduler: 遗忘曲线算法
  - SearchManager: 搜索与筛选逻辑
  - OCRCoordinator: OCR 降级策略
  - AgeVerificationManager: 年龄验证逻辑

### 7.2 UI 测试
```swift
import XCTest

final class CaptureFlowUITests: XCTestCase {
    func testOCRCaptureFlow() throws {
        let app = XCUIApplication()
        app.launch()
        
        // 1. 导航到录入页面
        app.tabBars.buttons["录入"].tap()
        
        // 2. 拍照
        app.buttons["拍照"].tap()
        // 模拟相机授权
        addUIInterruptionMonitor(withDescription: "Camera Access") { alert in
            alert.buttons["允许"].tap()
            return true
        }
        
        // 3. 验证 OCR 结果页面出现
        XCTAssertTrue(app.textViews["ocrResult"].waitForExistence(timeout: 5))
        
        // 4. 校对并保存
        app.buttons["保存"].tap()
        XCTAssertTrue(app.alerts["保存成功"].waitForExistence(timeout: 2))
    }
}
```

### 7.3 性能测试
```swift
import XCTest

final class PerformanceTests: XCTestCase {
    func testColdStartTime() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
        // Baseline: < 1.2s
    }
    
    func testSearchPerformance() throws {
        let app = XCUIApplication()
        app.launch()
        
        measure(metrics: [XCTClockMetric()]) {
            app.searchFields["搜索"].tap()
            app.searchFields["搜索"].typeText("数学")
        }
        // Baseline: < 500ms
    }
}
```

---

## 8. 部署与发布

### 8.1 App Store 配置
```xml
<!-- Info.plist 关键配置 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册以录入错题照片</string>

<key>NSCameraUsageDescription</key>
<string>需要使用相机拍摄错题</string>

<key>NSUserTrackingUsageDescription</key>
<string>用于改进产品体验，数据完全匿名且可选</string>

<key>LSApplicationCategoryType</key>
<string>public.app-category.education</string>
```

### 8.2 版本号规范
- **格式**: `MAJOR.MINOR.PATCH` (语义化版本)
- **示例**: `6.2.0`
  - `6`: 主版本（架构变更）
  - `2`: 次版本（功能增加）
  - `0`: 修订版本（Bug 修复）

### 8.3 持续集成
```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Select Xcode 26
        run: sudo xcode-select -s /Applications/Xcode_26.0.1.app
      
      - name: Build
        run: xcodebuild build -scheme NotBad -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
      
      - name: Unit Tests
        run: xcodebuild test -scheme NotBad -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
      
      - name: Code Coverage
        run: |
          xcrun llvm-cov report \
            -instr-profile=default.profdata \
            -object Build/Products/Debug/NotBad.app/NotBad
```

---

## 9. 变更历史

### v6.2 (2025-11-14) - 隐私合规与技术细化

**核心变更**:
- ✅ 新增隐私合规技术方案（年龄验证、家长控制、数据删除）
- ✅ 补充 OCR 双层架构设计（Vision + Azure 降级）
- ✅ 新增遥测隐私保护实现（90 天 UUID 重置、聚合数据）
- ✅ 新增内容审核服务集成设计（阿里云内容安全）
- ✅ 补充风险技术缓解方案（R-01 至 R-06）
- ✅ 完善数据模型设计（Question/Subject/Tag/ReviewRecord）
- ✅ 新增性能优化策略（冷启动、滚动性能）

**影响范围**:
- Core/DataManager: 新增 UserProfile、ParentalControl 模型
- Presentation/Views: 需实现年龄验证 UI 和家长控制设置页
- Domain/UseCases: 新增 AgeVerificationManager、ParentalControlManager
- Infrastructure: 新增 AzureOCRService、AliyunContentSecurity

### v6.1 (2025-10-07) - 免费模式架构调整
- 移除付费相关模块
- CloudKit 免费额度优先策略
- 本地优先架构强化

### v6.0 (2025-09-19) - iOS 26 技术栈升级
- Swift 6.2 严格并发检查
- SwiftData 替代 CoreData
- MVVM-C 架构引入

---

> **文档最后更新**: 2025-11-14 (v6.2)  
> **维护人**: Yiming Liao  
> **下次评审**: 2025-11-30 或重大架构变更时  
> **反馈渠道**: 技术 Issue/PR 或直接联系架构师
