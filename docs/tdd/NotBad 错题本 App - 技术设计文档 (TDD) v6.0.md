# NotBad 错题本 App - 技术设计文档 (TDD) v6.0

## 文档定位：技术实现单一事实来源 (Single Source of Truth for Implementation)

本文档基于 [**PRD v6.0**](../prd/NotBad%20错题本%20App%20-%20产品需求文档%20(PRD)%20v6.0.md) 的产品需求，为NotBad App的技术实现提供了唯一的、权威的、详尽的蓝图。它是开发、测试及运维团队的**核心行动纲领**，定义了基于iOS 26+ Swift 6.2前沿技术栈的架构设计、模块职责、接口契约、数据结构和非功能性实现方案。

## 文档治理与变更流程 (Document Governance)

本TDD严格遵循PRD确立的文档优先级：
1. **从属关系**: TDD细化PRD的技术约束，必须与PRD一致；冲突时以PRD为准
2. **变更流程**: 技术变更首先在TDD提出评审，同步更新RTM和其他从属文档
3. **版本一致性**: TDD版本号与PRD保持同步，确保技术实现与产品需求的严格对齐

## 速查：相关文档（快速跳转）

- 文档索引: [docs/README.md](../README.md)
- PRD: [docs/prd/NotBad 错题本 App - 产品需求文档 (PRD) v6.0.md](../prd/NotBad%20错题本%20App%20-%20产品需求文档%20(PRD)%20v6.0.md)
- RTM: [docs/rtm/NotBad App - 需求追踪矩阵 (RTM) v6.0.md](../rtm/NotBad%20App%20-%20需求追踪矩阵%20(RTM)%20v6.0.md)
- 业务术语表: [docs/glossary/NotBad App - 业务术语表 v6.0.md](../glossary/NotBad%20App%20-%20业务术语表%20v6.0.md)
- 技术术语表: [docs/glossary/NotBad App - 技术术语表 v6.0.md](../glossary/NotBad%20App%20-%20技术术语表%20v6.0.md)
- 术语→代码索引: [docs/glossary/NotBad App - 术语到代码索引 v6.0.md](../glossary/NotBad%20App%20-%20术语到代码索引%20v6.0.md)
- 附录A: [验收标准模板](../appendices/ACCEPTANCE_CRITERIA_TEMPLATE.md)
- 附录B: [分析事件规范](../appendices/ANALYTICS_EVENT_SPEC.md)
- 附录C: [指标对齐](../appendices/METRICS_ALIGNMENT.md)
- 附录D: [平台降级矩阵](../appendices/PLATFORM_DEGRADATION_MATRIX.md)
- 附录E: [P0/P1/P2行动项](../roadmap/P0_P1_P2_ACTIONS.md)

| 版本 | 日期 | 作者 | 变更说明 | 状态 |
| :---- | :---- | :---- | :---- | :---- |
| v4.0 | 2025-09-03 | Tech Team | 基础架构设计，基于传统技术栈 | 已归档 |
| **v6.0** | **2025-09-19** | **Tech Team** | **🚀 全面升级至iOS 26+ Swift 6.2前沿技术栈，对齐PRD v6.0产品需求** | ✅ **生效中** |

## 1. 技术概述 (Technical Overview)

### 1.1 技术目标 (Technical Goals)

基于iOS 26+ Swift 6.2前沿技术栈，构建一个高性能、高可靠、可扩展且易于维护的iOS原生应用，严格承接PRD v6.0中定义的所有功能性及非功能性需求：

**性能卓越**:
- 应用启动时间 < **0.8秒** (利用Swift 6.2编译优化和iOS 26启动加速)
- 核心交互响应 < **100ms** (基于Swift 6.2最新并发模型)
- OCR识别准确率 > **95%** (中文) / **90%** (数学公式)
- 内存使用 < **150MB** (iOS 26高级内存管理)
- 滚动流畅度 > **120fps** (iOS 26 ProMotion Max支持)

**数据安全**:
- 端到端加密，完全符合COPPA和GDPR隐私合规要求
- 未成年人数据分类保护 (高/中/低敏感度分级)
- 年龄分层隐私策略 (13-以下 vs 13-18岁)

**极致可靠**:
- 核心功能100%离线可用
- 崩溃率 < **0.05%** (Swift 6.2编译时安全保证)
- 数据同步成功率 > **99.9%**

**架构优雅**:
- Clean Architecture + Swift 6.2现代并发模式
- 100%编译时并发安全保证
- 高度可测试性和可维护性

### 1.2 Swift 6.2 & iOS 26 前沿技术利用 (Cutting-edge Technology Utilization)

**Swift 6.2 新特性应用**:
- **Enhanced Actor Isolation**: 实现完全的并发安全，OCR和数据同步性能提升
- **Improved TaskGroup**: 批量图片处理并发优化
- **Enhanced Collections**: 高性能错题搜索和分类操作
- **Advanced Pattern Matching**: 复杂数据筛选和AI分析准确率提升
- **Improved Error Handling**: 更优雅的错误处理机制，提升应用稳定性
- **Enhanced Sendable Checking**: 100%编译时并发安全验证

**iOS 26 平台特性应用**:
- **Advanced Vision Framework**: 超高精度OCR识别，支持复杂数学公式
- **Enhanced SwiftData**: 现代化本地持久化，支持复杂查询优化
- **ProMotion Max**: 120fps+滚动体验，动画流畅度极致优化
- **Advanced CloudKit**: 增强的多设备同步能力
- **Device-side AI Models**: 本地AI处理，隐私保护与性能并重
- **Advanced Memory Management**: 显著降低内存占用

### 1.3 架构决策记录 (Architecture Decision Records)

基于iOS 26+ Swift 6.2技术栈的关键架构决策：

- [ADR-001 本地数据层与持久化框架选型 (SwiftData)](../adr/ADR-001%20本地数据层与持久化框架选型%20(SwiftData).md)
- [ADR-002 云同步与多端一致性策略 (Local-First + CloudKit)](../adr/ADR-002%20云同步与多端一致性策略%20(Local-First%20+%20CloudKit).md)
- [ADR-003 OCR 处理流水线与重处理策略](../adr/ADR-003%20OCR%20处理流水线与重处理策略.md)
- [ADR-004 Swift 6.2 架构升级决策](../adr/ADR-004%20Swift%206.2%20架构升级决策.md)

## 2. 系统架构设计 (System Architecture)

### 2.1 架构原则 (Architecture Principles)

**Clean Architecture + Swift 6.2 现代化增强**:
- 严格分层，依赖倒置，领域层是核心
- 利用Swift 6.2的Enhanced Actor Isolation保证并发安全
- 所有跨层通信通过Protocol进行，支持Enhanced Sendable检查

**Local-First + CloudKit Premium**:
- 用户数据优先在设备本地处理和存储
- CloudKit提供跨设备同步，支持iOS 26增强特性
- 网络仅用于同步，确保100%离线可用性

**SOLID + Swift 6.2 Enhancement**:
- 遵循SOLID原则，利用Swift 6.2的类型系统增强
- Enhanced Pattern Matching支持复杂业务逻辑
- Improved Error Handling确保优雅的错误处理

### 2.2 分层架构设计 (Layered Architecture)

```
┌─────────────────────────────────────────────────┐
│           Presentation Layer (SwiftUI + MVVM-C)              │
│   SwiftUI Views + ViewModels + Coordinators                 │
│   利用iOS 26最新SwiftUI特性和ProMotion Max               │
├─────────────────────────────────────────────────┤
│              Application Layer                              │
│        Use Cases / Interactors                            │
│    基于Swift 6.2 Enhanced TaskGroup并发处理              │
├─────────────────────────────────────────────────┤
│               Domain Layer                                 │
│  Entities, Value Objects, Repository Protocols            │
│     Swift 6.2 Enhanced Sendable 类型安全                │
├─────────────────────────────────────────────────┤
│            Infrastructure Layer                            │
│  SwiftData(iOS26) + CloudKit + Vision + Analytics          │
│       Enhanced Actor 模式确保线程安全                    │
└─────────────────────────────────────────────────┘
```

### 2.3 核心模块架构 (Core Module Architecture)

**OCR Processing Module (Enhanced Vision)**:
```swift
@MainActor
class OCRProcessor: ObservableObject {
    private let visionService: VisionOCRService
    private let enhancedProcessor: iOS26OCRProcessor

    @Published var processingState: OCRState = .idle

    func processImage(_ image: UIImage) async throws -> OCRResult {
        // 利用iOS 26 Enhanced Vision Framework
        // Swift 6.2 TaskGroup 并发处理
    }
}
```

**Data Sync Module (Enhanced CloudKit)**:
```swift
actor SyncCoordinator {
    private let cloudKitService: EnhancedCloudKitService
    private let localRepository: SwiftDataRepository

    func synchronize() async throws {
        // Swift 6.2 Enhanced Actor Isolation
        // iOS 26 CloudKit 增强同步能力
    }
}
```

## 3. 数据设计 (Data Architecture)

### 3.1 核心数据模型 (Swift 6.2 Enhanced Data Models)

基于Swift 6.2的Enhanced Sendable和类型安全特性：

```swift
import Foundation
import SwiftData

// 利用Swift 6.2 Enhanced Sendable特性
@Model
final class ReviewItem: Sendable {
    @Attribute(.unique) var id: UUID
    var content: ReviewContent
    var metadata: ReviewMetadata
    var studyHistory: [StudyRecord]
    var masteryLevel: MasteryLevel
    var privacyLevel: PrivacyLevel // 新增：隐私分级
    var createdAt: Date
    var updatedAt: Date

    init(content: ReviewContent, metadata: ReviewMetadata) {
        self.id = UUID()
        self.content = content
        self.metadata = metadata
        self.studyHistory = []
        self.masteryLevel = .notStarted
        self.privacyLevel = .medium // 默认中等敏感度
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// Swift 6.2 Enhanced Pattern Matching支持
struct ReviewContent: Codable, Sendable {
    let originalText: String
    let processedText: String
    let images: [ImageData]
    let subject: Subject
    let difficulty: DifficultyLevel
    let tags: Set<String>

    // Enhanced Collections支持高效搜索
    func matches(searchTerm: String) -> Bool {
        // 利用Swift 6.2新的字符串匹配特性
    }
}

// 隐私保护数据分类
enum PrivacyLevel: String, Codable, CaseIterable, Sendable {
    case high = "high"       // 个人身份信息
    case medium = "medium"   // 学习内容
    case low = "low"         // 统计数据
}

// 年龄分层保护
struct UserPrivacySettings: Codable, Sendable {
    let userAge: AgeGroup
    let parentalConsent: Bool
    let dataCollectionLevel: DataCollectionLevel
    let socialFeaturesEnabled: Bool

    enum AgeGroup: String, Codable, Sendable {
        case under13 = "under13"
        case teen13to17 = "teen13to17"
        case adult18plus = "adult18plus"
    }

    enum DataCollectionLevel: String, Codable, Sendable {
        case minimal = "minimal"
        case standard = "standard"
        case enhanced = "enhanced"
    }
}
```

### 3.2 iOS 26 SwiftData 持久化架构 (Advanced Persistence)

**Enhanced SwiftData Configuration**:
```swift
import SwiftData

@MainActor
class PersistenceController: ObservableObject {
    lazy var container: ModelContainer = {
        let schema = Schema([
            ReviewItem.self,
            StudyRecord.self,
            UserProfile.self,
            DiscoveryPost.self // 新增：Discovery社区数据
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.notbad.reviewapp")
        )

        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )

            // iOS 26 性能优化配置
            container.mainContext.autosaveEnabled = true
            return container
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}
```

**数据加密与隐私保护**:
```swift
actor EncryptionService {
    private let keychain: KeychainService

    func encryptHighSensitivityData(_ data: Data) async throws -> EncryptedData {
        // AES-256加密，密钥存储在Keychain
        // 符合COPPA/GDPR要求
    }

    func anonymizeForDiscovery(_ item: ReviewItem) async -> AnonymizedItem {
        // Discovery社区数据匿名化处理
        // 移除所有个人标识信息
    }
}
```

## 4. Discovery 社区模块技术设计 (Discovery Community Technical Design)

### 4.1 社区数据架构 (Community Data Architecture)

基于PRD v6.0的Discovery功能要求，设计匿名化社区数据模型：

```swift
@Model
final class DiscoveryPost: Sendable {
    @Attribute(.unique) var id: UUID
    var anonymizedContent: AnonymizedContent // 完全匿名化内容
    var subject: Subject
    var difficultyLevel: DifficultyLevel
    var contributionScore: Int
    var createdAt: Date
    var moderationStatus: ModerationStatus

    // 隐私保护：无用户标识信息
    var interactionCount: Int // 聚合统计，无个人信息
    var helpfulnessScore: Double
}

struct AnonymizedContent: Codable, Sendable {
    let problemDescription: String // 题目描述（去除个人信息）
    let solutionApproaches: [String] // 解题思路
    let keyKnowledgePoints: [String] // 知识点标签
    let aiGeneratedSummary: String // AI生成的总结
}

enum ModerationStatus: String, Codable, CaseIterable, Sendable {
    case pending = "pending"
    case approved = "approved"
    case flagged = "flagged"
    case rejected = "rejected"
}
```

### 4.2 隐私保护机制 (Privacy Protection Mechanisms)

**年龄分层访问控制**:
```swift
actor DiscoveryAccessController {
    func canAccessDiscovery(user: UserProfile) async -> Bool {
        switch user.privacySettings.userAge {
        case .under13:
            return user.privacySettings.parentalConsent &&
                   user.privacySettings.socialFeaturesEnabled
        case .teen13to17:
            return user.privacySettings.socialFeaturesEnabled
        case .adult18plus:
            return true
        }
    }

    func canContribute(user: UserProfile) async -> Bool {
        // 额外的贡献权限检查
        // AI内容审核通过率等因素
    }
}
```

**内容审核系统**:
```swift
actor ContentModerationService {
    private let aiModerator: LocalAIModerator
    private let humanReviewQueue: HumanReviewQueue

    func moderateContent(_ content: AnonymizedContent) async throws -> ModerationResult {
        // 1. 本地AI初步审核
        let aiResult = await aiModerator.analyze(content)

        // 2. 敏感内容检测
        let sensitivityScore = await analyzeSensitivity(content)

        // 3. 需要人工复审的内容排队
        if sensitivityScore > 0.7 || aiResult.confidence < 0.8 {
            await humanReviewQueue.enqueue(content)
            return .pendingHumanReview
        }

        return aiResult.approved ? .approved : .rejected
    }
}
```

## 5. 性能优化设计 (Performance Optimization Design)

### 5.1 Swift 6.2 并发性能优化 (Concurrency Performance)

**Enhanced TaskGroup 批量处理**:
```swift
actor BatchProcessor {
    func processBatchImages(_ images: [UIImage]) async throws -> [OCRResult] {
        return try await withThrowingTaskGroup(of: OCRResult.self) { group in
            var results: [OCRResult] = []

            // Swift 6.2 Enhanced TaskGroup
            for (index, image) in images.enumerated() {
                group.addTask {
                    return try await self.processImage(image, index: index)
                }
            }

            for try await result in group {
                results.append(result)
            }

            return results.sorted { $0.index < $1.index }
        }
    }
}
```

**Enhanced Collections 搜索优化**:
```swift
actor SearchEngine {
    private let index: SearchIndex

    func search(_ query: String) async -> [ReviewItem] {
        // 利用Swift 6.2 Enhanced Collections
        // 高性能全文检索
        return await index.search(query)
            .filter { item in
                // Enhanced Pattern Matching
                item.content.matches(searchTerm: query)
            }
            .sorted { $0.relevanceScore > $1.relevanceScore }
    }
}
```

### 5.2 iOS 26 内存管理优化 (Advanced Memory Management)

**智能内存管理**:
```swift
@MainActor
class MemoryManager: ObservableObject {
    private let memoryPressureMonitor = MemoryPressureMonitor()
    private let imageCache = LRUCache<UUID, UIImage>(capacity: 50)

    func optimizeMemoryUsage() async {
        let currentUsage = await getCurrentMemoryUsage()

        if currentUsage > 120_000_000 { // 120MB阈值
            // iOS 26 智能内存回收
            await performIntelligentCleanup()
        }
    }

    private func performIntelligentCleanup() async {
        // 清理图片缓存
        imageCache.removeOldestEntries(count: 20)

        // 压缩低优先级数据
        await compressLowPriorityData()

        // 暂停后台任务
        await pauseNonCriticalTasks()
    }
}
```

## 6. 安全与隐私技术实现 (Security & Privacy Implementation)

### 6.1 数据分类加密策略 (Data Classification Encryption)

基于PRD v6.0的隐私保护要求：

```swift
actor PrivacyProtectionService {
    private let encryptionService: EncryptionService
    private let keyManager: SecureKeyManager

    func protectUserData(_ item: ReviewItem) async throws {
        switch item.privacyLevel {
        case .high:
            // 高敏感数据：端到端加密 + 本地密钥
            item.content = try await encryptionService.encryptWithLocalKey(item.content)

        case .medium:
            // 中敏感数据：标准AES加密
            item.content = try await encryptionService.encryptStandard(item.content)

        case .low:
            // 低敏感数据：仅传输加密
            // 本地明文存储，减少计算开销
            break
        }
    }

    func anonymizeForCommunity(_ item: ReviewItem) async throws -> AnonymizedContent {
        // 完全移除个人标识信息
        // 保留学习价值的核心内容
        return AnonymizedContent(
            problemDescription: removePersonalInfo(item.content.originalText),
            solutionApproaches: extractSolutions(item.studyHistory),
            keyKnowledgePoints: extractKnowledgePoints(item.content.tags),
            aiGeneratedSummary: await generateAnonymousSummary(item.content)
        )
    }
}
```

### 6.2 COPPA/GDPR 合规技术实现 (Compliance Implementation)

**年龄验证与数据收集控制**:
```swift
@MainActor
class ComplianceManager: ObservableObject {
    @Published var complianceStatus: ComplianceStatus = .checking

    func enforceDataCollection(for user: UserProfile) async {
        switch user.privacySettings.userAge {
        case .under13:
            if !user.privacySettings.parentalConsent {
                // 禁用所有数据收集
                await disableAnalytics()
                await disableSocialFeatures()
                await enableMinimalMode()
            }

        case .teen13to17:
            // 受限数据收集
            await enableLimitedAnalytics()
            await enableParentalControls()

        case .adult18plus:
            // 标准数据收集
            await enableStandardAnalytics()
        }
    }

    func handleDataDeletionRequest(userId: UUID) async throws {
        // GDPR Article 17 - Right to Erasure
        try await deleteAllUserData(userId: userId)
        try await removeFromCloudKit(userId: userId)
        try await clearLocalKeychain(userId: userId)
        try await notifyThirdPartyServices(userId: userId)
    }
}
```

## 7. 质量保证与测试策略 (QA & Testing Strategy)

### 7.1 Swift 6.2 测试架构 (Testing Architecture)

**Enhanced Testing with Swift 6.2**:
```swift
import XCTest
import Testing // Swift 6.2 新测试框架

@MainActor
class ReviewItemUseCaseTests: XCTestCase {

    @Test("创建错题应在0.5秒内完成")
    func testCreateReviewItemPerformance() async throws {
        let useCase = CreateReviewItemUseCase(
            repository: MockRepository(),
            ocrService: MockOCRService()
        )

        let startTime = ContinuousClock.now

        let result = try await useCase.execute(
            image: TestImages.sampleMathProblem,
            subject: .mathematics
        )

        let duration = ContinuousClock.now - startTime

        #expect(duration < .milliseconds(500))
        #expect(result.confidence > 0.95)
    }

    @Test("并发OCR处理应保持线程安全")
    func testConcurrentOCRProcessing() async throws {
        let processor = OCRProcessor()
        let images = TestImages.batchSamples

        // Swift 6.2 并发安全测试
        let results = try await withThrowingTaskGroup(of: OCRResult.self) { group in
            for image in images {
                group.addTask {
                    return try await processor.processImage(image)
                }
            }

            var allResults: [OCRResult] = []
            for try await result in group {
                allResults.append(result)
            }
            return allResults
        }

        #expect(results.count == images.count)
        #expect(results.allSatisfy { $0.confidence > 0.90 })
    }
}
```

### 7.2 性能基准测试 (Performance Benchmarks)

**iOS 26 性能基准**:
```swift
class PerformanceBenchmarks: XCTestCase {

    func testAppLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
        // 目标：< 0.8秒
    }

    func testMemoryUsage() {
        measure(metrics: [XCTMemoryMetric()]) {
            // 批量加载1000个错题
            loadLargeDataSet()
        }
        // 目标：< 150MB
    }

    func testOCRAccuracy() async throws {
        let testCases = OCRTestCases.allCases
        var accuracyResults: [Double] = []

        for testCase in testCases {
            let result = try await ocrService.process(testCase.image)
            let accuracy = calculateAccuracy(
                expected: testCase.expectedText,
                actual: result.text
            )
            accuracyResults.append(accuracy)
        }

        let averageAccuracy = accuracyResults.reduce(0, +) / Double(accuracyResults.count)
        XCTAssertGreaterThan(averageAccuracy, 0.95) // > 95%准确率
    }
}
```

## 8. DevOps 与可观测性 (DevOps & Observability)

### 8.1 Swift 6.2 CI/CD 管道 (Enhanced CI/CD)

**GitHub Actions with Swift 6.2**:
```yaml
name: iOS 26 Swift 6.2 CI/CD

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-test:
    runs-on: macos-15 # iOS 26 支持

    steps:
    - uses: actions/checkout@v4

    - name: Setup Xcode 16
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '16.0'

    - name: Swift 6.2 Compiler Checks
      run: |
        swift --version
        # Swift 6.2 严格并发检查
        xcodebuild -scheme NotBad \
          -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
          -enableAddressSanitizer YES \
          -enableThreadSanitizer YES \
          build

    - name: Run Performance Benchmarks
      run: |
        xcodebuild test \
          -scheme NotBadPerformanceTests \
          -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
          -resultBundlePath TestResults.xcresult

    - name: Validate Memory Usage
      run: |
        # 验证内存使用 < 150MB
        python Scripts/validate_memory_usage.py TestResults.xcresult
```

### 8.2 可观测性体系 (Observability System)

**结构化日志与监控**:
```swift
import OSLog

actor AnalyticsService {
    private let logger = Logger(subsystem: "com.notbad.app", category: "analytics")

    func trackEvent(_ event: AnalyticsEvent) async {
        let eventData = await serializeEvent(event)

        // 隐私安全的结构化日志
        logger.info("""
            📊 Event: \(event.name, privacy: .public)
            📝 Data: \(eventData, privacy: .private)
            🕒 Timestamp: \(Date().ISO8601Format(), privacy: .public)
            👤 User: \(event.anonymizedUserId, privacy: .public)
            """)

        // 异步上报到分析服务
        await uploadToAnalyticsService(eventData)
    }

    func trackPerformanceMetric(_ metric: PerformanceMetric) async {
        switch metric {
        case .launchTime(let duration):
            if duration > 0.8 {
                logger.warning("⚠️ Launch time exceeded target: \(duration)s")
            }

        case .memoryUsage(let bytes):
            if bytes > 150_000_000 {
                logger.warning("⚠️ Memory usage exceeded target: \(bytes / 1_000_000)MB")
            }

        case .ocrAccuracy(let accuracy):
            if accuracy < 0.95 {
                logger.warning("⚠️ OCR accuracy below target: \(accuracy * 100)%")
            }
        }
    }
}
```

## 9. 项目交付计划 (Project Delivery Plan)

### 9.1 分阶段交付策略 (Phased Delivery Strategy)

基于PRD v6.0的MVP要求和iOS 26+ Swift 6.2技术栈：

**Phase 1: 核心MVP (6周)**
- **技术目标**: Swift 6.2基础架构 + iOS 26核心功能
- **交付模块**:
  - Enhanced OCR Service (Vision Framework)
  - SwiftData 本地存储
  - 基础UI框架 (SwiftUI + iOS 26特性)
  - 错题CRUD操作
- **验收标准**:
  - ✅ 启动时间 < 0.8秒
  - ✅ OCR准确率 > 90%
  - ✅ 100%离线可用
  - ✅ 内存使用 < 150MB

**Phase 2: 增强功能 (4周)**
- **技术目标**: CloudKit同步 + Discovery社区
- **交付模块**:
  - Enhanced CloudKit 数据同步
  - Discovery 社区基础功能
  - 隐私保护机制
  - 基础分析统计
- **验收标准**:
  - ✅ 多设备同步成功率 > 99%
  - ✅ 社区内容匿名化
  - ✅ COPPA/GDPR合规

**Phase 3: 生产就绪 (4周)**
- **技术目标**: 性能优化 + 监控完善
- **交付模块**:
  - 性能深度优化
  - 可观测性体系
  - 安全加固
  - App Store发布准备
- **验收标准**:
  - ✅ 崩溃率 < 0.05%
  - ✅ 所有性能指标达标
  - ✅ 安全合规认证通过

### 9.2 风险缓解策略 (Risk Mitigation)

**技术风险**:
- **Swift 6.2 兼容性**:
  - 缓解：早期原型验证，保持Xcode 15降级能力
- **iOS 26 设备覆盖率**:
  - 缓解：20-30%早期采用者足够MVP验证，后续扩展支持

**性能风险**:
- **0.8秒启动目标**:
  - 缓解：分阶段优化，关键路径预加载，懒加载非核心组件
- **150MB内存限制**:
  - 缓解：智能缓存管理，图片压缩，及时内存回收

## 10. 附录 (Appendix)

### 10.1 Swift 6.2 Migration Guide

从现有代码迁移到Swift 6.2的关键步骤：

1. **启用并发检查**: `SWIFT_STRICT_CONCURRENCY = complete`
2. **Actor化服务层**: 将所有Service转换为Actor
3. **Sendable协议**: 为所有数据模型添加Sendable
4. **Enhanced Collections**: 升级搜索和排序逻辑
5. **Error Handling**: 使用新的result builders

### 10.2 iOS 26 Feature Adoption

利用iOS 26新特性的优先级列表：

- **P0**: Enhanced Vision (OCR核心功能)
- **P0**: SwiftData改进 (数据持久化)
- **P1**: ProMotion Max (用户体验)
- **P1**: Advanced CloudKit (数据同步)
- **P2**: 3D知识图谱 (差异化功能)

### 10.3 Performance Monitoring Dashboard

关键性能指标实时监控：

```swift
struct PerformanceDashboard {
    let launchTime: Measurement<UnitDuration>      // 目标: < 0.8s
    let memoryUsage: Measurement<UnitInformationStorage> // 目标: < 150MB
    let ocrAccuracy: Double                        // 目标: > 95%
    let syncSuccessRate: Double                    // 目标: > 99%
    let crashRate: Double                          // 目标: < 0.05%
    let userSatisfaction: Double                   // 目标: > 4.5分
}
```

## 11. 性能监控与分析埋点系统 (Performance Monitoring & Analytics)

### 11.1 核心性能指标 (Core Performance Metrics)

#### 11.1.1 应用性能指标

**启动性能**:
- **指标**: 冷启动时间 (Cold Launch Time)
- **定义**: 从用户点击应用图标到首屏完全渲染的时间
- **目标**: P95 < 0.8s (基于Swift 6.2编译优化)
- **基准设备**: iPhone 15 Pro / iPhone 15 Pro Max / iPhone SE (2022)
- **监控方式**: iOS 原生MetricKit + 自定义计时器
- **埋点事件**: `app_launch_cold`

```swift
// 启动性能监控实现
@MainActor
class LaunchPerformanceMonitor {
    private let startTime = DispatchTime.now()

    func recordLaunchComplete() {
        let duration = DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds
        let durationMs = Double(duration) / 1_000_000

        Analytics.track("app_launch_cold", parameters: [
            "duration_ms": durationMs,
            "device_model": UIDevice.current.model,
            "ios_version": UIDevice.current.systemVersion,
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "memory_pressure": ProcessInfo.processInfo.thermalState.rawValue
        ])
    }
}
```

**响应性能**:
- 搜索首屏渲染: P95 < 300ms
- 页面切换: P95 < 300ms
- OCR处理: P95 < 2.5s
- 滚动丢帧率: P95 < 1%

**资源使用**:
- 内存使用(正常): P95 < 60MB
- 内存使用(OCR峰值): P95 < 150MB
- AR渲染帧率: P95 ≥ 60fps

#### 11.1.2 功能质量指标

**OCR准确性监控**:
```swift
actor OCRAccuracyTracker {
    private var recognitionSessions: [String: OCRSession] = [:]

    func trackRecognition(sessionId: String,
                         confidence: Double,
                         textLength: Int,
                         language: String) {
        Analytics.track("ocr_accuracy", parameters: [
            "session_id": sessionId,
            "confidence_score": confidence,
            "text_length": textLength,
            "language": language,
            "device_neural_engine": MLModel.isNeuralEngineSupported
        ])
    }

    func trackManualCorrection(sessionId: String,
                              correctionCount: Int,
                              originalText: String,
                              correctedText: String) {
        Analytics.track("ocr_manual_correction", parameters: [
            "session_id": sessionId,
            "correction_count": correctionCount,
            "accuracy_estimate": calculateAccuracy(originalText, correctedText)
        ])
    }
}
```

### 11.2 埋点事件规范 (Analytics Event Specification)

#### 11.2.1 事件命名规范

**命名格式**: `{module}_{action}_{object}`

**模块定义**:
- `app`: 应用级别事件
- `camera`: 拍照相关
- `ocr`: OCR处理相关
- `review`: 复习相关
- `sync`: 数据同步相关
- `user`: 用户行为相关
- `discovery`: Discovery社区相关
- `subscription`: 订阅付费相关

**动作定义**:
- `start`: 开始某个操作
- `complete`: 完成某个操作
- `fail`: 操作失败
- `cancel`: 用户取消操作

#### 11.2.2 核心埋点事件

```swift
enum AnalyticsEvent: String, CaseIterable {
    // 应用生命周期
    case appLaunchCold = "app_launch_cold"
    case appLaunchWarm = "app_launch_warm"
    case appBackground = "app_background"
    case appForeground = "app_foreground"

    // 用户行为
    case userOnboardingStart = "user_onboarding_start"
    case userOnboardingComplete = "user_onboarding_complete"
    case userSubscriptionUpgrade = "user_subscription_upgrade"

    // 核心功能
    case cameraCapture = "camera_capture_complete"
    case ocrProcessing = "ocr_processing_complete"
    case reviewSessionStart = "review_session_start"
    case reviewSessionComplete = "review_session_complete"

    // Discovery社区
    case discoveryPostView = "discovery_post_view"
    case discoveryPostShare = "discovery_post_share"
    case discoveryContentReport = "discovery_content_report"

    // 性能监控
    case performanceMetric = "performance_metric"
    case errorOccurred = "error_occurred"
    case crashDetected = "crash_detected"
}
```

#### 11.2.3 分析事件详细规范

**事件约定**:
- **ID格式**: snake_case命名
- **时间单位**: ms (int类型)
- **采样率**: 100% (除非特别指定)
- **隐私保护**: 无PII信息，使用匿名ID，未成年人无跨应用追踪

**核心事件定义**:
```swift
// 拍照录入流程
Analytics.track("capture_started", parameters: [
    "source": "camera|album",
    "batch": batchCount
])

Analytics.track("capture_ocr_completed", parameters: [
    "duration_ms": processingDuration,
    "ocr_confidence": confidenceScore,
    "edited": userEditedResult
])

// 学习管理
Analytics.track("item_tagged", parameters: [
    "tags": selectedTags,
    "subject": subjectCategory
])

Analytics.track("review_session_started", parameters: [
    "set_size": reviewItemCount,
    "algo": "spaced|manual"
])

Analytics.track("review_card_swiped", parameters: [
    "direction": "right|left|again",
    "item_id": anonymizedItemId,
    "time_spent_ms": cardViewDuration
])

// 通知系统
Analytics.track("notification_delivered", parameters: [
    "type": "review",
    "deep_link": linkDestination
])

Analytics.track("notification_opened", parameters: [
    "type": "review"
])

// 搜索功能
Analytics.track("search_performed", parameters: [
    "query_length": searchQuery.count,
    "filters": appliedFilters,
    "result_count": resultSet.count
])
```

**仪表板映射**:
- **获客指标**: App Store Connect + 自定义分析
- **参与度指标**: review_*, search_* 事件系列
- **质量指标**: 崩溃率、延迟分布

**数据保留与隐私**:
- **聚合数据保留**: 180天
- **原始数据保留**: 30天
- **K-匿名性**: 用户群组 < 5人时不显示数据
- **用户控制**: 遵循iOS分析退出设置

#### 11.2.4 指标基准与方法论

**基准设备**:
- iPhone 15 Pro (A17 Pro) - 旗舰级
- iPhone 12 (A14) - 主流级
- iPhone SE (2022) (A15) - 入门级

**测量方法论**:
- **环境标准化**: 飞行模式关闭，屏幕亮度50%
- **统计方法**: 测量P50/P95，每场景3次运行，必要时排除首次运行
- **工具链**: MetricKit + os_signpost + Xcode Instruments + ASC metrics

**关键性能目标**:
```swift
struct PerformanceTargets {
    // 应用启动
    static let coldLaunchP95 = Measurement(value: 0.8, unit: UnitDuration.seconds)

    // 内存使用
    static let normalMemoryP95 = Measurement(value: 60, unit: UnitInformationStorage.megabytes)
    static let ocrPeakMemoryP95 = Measurement(value: 150, unit: UnitInformationStorage.megabytes)

    // 功能响应
    static let searchLatencyP95 = Measurement(value: 300, unit: UnitDuration.milliseconds) // 5k items indexed
    static let ocrProcessingP95 = Measurement(value: 2.5, unit: UnitDuration.seconds)     // standard lighting
}
```

**监控与报告**:
- **周度仪表板**: 自动化性能趋势报告
- **回归检测**: 性能下降超过10%时触发告警
- **多维度分析**: 按设备型号、iOS版本、功能模块分层分析

### 11.3 用户体验指标 (User Experience Metrics)

#### 11.3.1 用户参与度

- **日活跃用户(DAU)**: 目标增长率 >20%/月
- **7天留存率**: >70%
- **30天留存率**: >40%
- **日均使用时长**: >15分钟/用户

#### 11.3.2 功能使用率

- **错题录入频率**: >3次/周/用户
- **复习完成率**: >60%
- **核心功能使用率**: >80%
- **Discovery社区参与率**: >30%

## 12. 平台兼容性与降级策略 (Platform Compatibility & Degradation)

### 12.1 平台支持策略

**最低支持版本**:

- **最低iOS版本**: iOS 26.0+ (统一平台基线，简化维护与测试)
- **目标iOS版本**: iOS 26.0+ (当前即目标，功能完整)
- **未来iOS版本**: iOS 27.0+ (跟进新特性时评估)

**设备支持范围**:

- **iPhone**: iPhone 17 系列及以上（推荐测试设备）
- **iPad**: iPad Pro (M4) 及以上（如涉及 iPadOS）
- **基准测试设备**: iPhone 17 Pro, iPhone 17 Pro Max

### 12.2 功能支持矩阵

> 注意：自 v6.0 起，应用的 Deployment Target 已统一到 iOS 26.0+。下表中的 iOS 16/17/18 列用于记录历史降级策略与兼容性设计，当前代码仅需满足 iOS 26+ 路径。

#### 12.2.1 核心功能 (Must Have)

| 功能 | iOS 16.0+ | iOS 17.0+ | iOS 18.0+ | iOS 26.0+ | 降级策略 |
|------|-----------|-----------|-----------|-----------|----------|
| 拍照录入 | ✅ 基础相机 | ✅ 同左 | ✅ 增强相机 | ✅ 同左 | 系统相机调用 |
| OCR识别 | ✅ Vision基础 | ✅ Vision优化 | ✅ Vision高级 | ✅ Vision AI | 云端OCR备选 |
| 错题管理 | ✅ 完整支持 | ✅ 同左 | ✅ 同左 | ✅ 同左 | 无需降级 |
| 本地存储 | ✅ Core Data | ✅ SwiftData基础 | ✅ SwiftData完整 | ✅ 同左 | Core Data兜底 |
| 基础复习 | ✅ 完整支持 | ✅ 同左 | ✅ 同左 | ✅ 同左 | 无需降级 |

#### 12.2.2 高级功能 (Should Have)

| 功能 | iOS 16.0+ | iOS 17.0+ | iOS 18.0+ | iOS 26.0+ | 降级策略 |
|------|-----------|-----------|-----------|-----------|----------|
| CloudKit同步 | ✅ 基础同步 | ✅ 增强同步 | ✅ 完整同步 | ✅ 智能同步 | 本地存储 |
| 智能复习 | ✅ 基础算法 | ✅ 机器学习 | ✅ Core ML优化 | ✅ Proactive Intelligence | 静态算法 |
| Discovery社区 | ✅ 基础功能 | ✅ 同左 | ✅ 增强体验 | ✅ 智能推荐 | 基础列表 |

### 12.3 能力检测与降级实现

#### 12.3.1 iOS版本检测

```swift
struct FeatureAvailability {
    static let swiftDataSupport = ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 17
    static let proactiveIntelligence = ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26
    static let enhancedAR = ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 18

    static func supportsFeature(_ feature: AppFeature) -> Bool {
        switch feature {
        case .swiftData:
            return swiftDataSupport
        case .proactiveIntelligence:
            return proactiveIntelligence
        case .advancedAR:
            return enhancedAR && ARWorldTrackingConfiguration.isSupported
        case .enhancedVision:
            return ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26
        }
    }
}
```

#### 12.3.2 设备能力检测

```swift
struct DeviceCapability {
    static let supportsARKit = ARWorldTrackingConfiguration.isSupported
    static let supportsCoreML = MLModel.available
    static let supportsNeuralEngine = isNeuralEngineAvailable()
    static let memoryCapacity = ProcessInfo.processInfo.physicalMemory

    static func performanceLevel() -> PerformanceLevel {
        let deviceModel = UIDevice.current.model
        let memoryGB = memoryCapacity / (1024 * 1024 * 1024)

        switch (deviceModel, memoryGB) {
        case (_, let memory) where memory >= 8:
            return .premium  // iPhone 17 Pro 系列
        case (_, let memory) where memory >= 6:
            return .high     // iPhone 17 系列
        case (_, let memory) where memory >= 4:
            return .medium   // iPhone 14/15 系列
        default:
            return .low      // iPhone SE等入门设备
        }
    }
}
```

#### 12.3.3 条件编译策略

```swift
// 数据存储层降级
#if canImport(SwiftData)
    import SwiftData
    typealias DataStore = SwiftDataStore
#else
    import CoreData
    typealias DataStore = CoreDataStore
#endif

// 运行时功能选择
func createDataStore() -> DataStoreProtocol {
    if #available(iOS 17.0, *), FeatureAvailability.swiftDataSupport {
        return SwiftDataStore()
    } else {
        return CoreDataStore()
    }
}

// AI功能降级
@available(iOS 18.0, *)
class ProactiveReviewManager {
    // iOS 18+ 专用的 Proactive Intelligence 实现
}

class LegacyReviewManager {
    // iOS 16+ 兼容的基础实现
}

func createReviewManager() -> ReviewManagerProtocol {
    if #available(iOS 18.0, *), DeviceCapability.supportsCoreML {
        return ProactiveReviewManager()
    } else {
        return LegacyReviewManager()
    }
}
```

### 12.4 性能优化分级

#### 12.4.1 基准设备性能目标

| 设备级别 | 代表设备 | 启动时间目标 | 内存限制 | 功能级别 |
|----------|----------|--------------|----------|----------|
| 入门级 | iPhone SE (2022) | P95 < 1.2s | < 50MB | 核心功能 |
| 中端 | iPhone 12/13 | P95 < 1.0s | < 80MB | 完整功能 |
| 高端 | iPhone 14/15 | P95 < 0.8s | < 120MB | 增强功能 |
| 旗舰 | iPhone 17 Pro Max | P95 < 0.6s | < 150MB | 全部功能 |

#### 12.4.2 动态性能调整

```swift
@MainActor
class PerformanceManager {
    private let deviceLevel = DeviceCapability.performanceLevel()

    func adjustForDevice() {
        switch deviceLevel {
        case .low:
            // 降低动画复杂度、减少并发任务
            UIView.setAnimationsEnabled(false)
            TaskGroup.maxConcurrency = 2

        case .medium:
            // 平衡性能与体验
            TaskGroup.maxConcurrency = 4

        case .high, .premium:
            // 启用全部增强功能
            TaskGroup.maxConcurrency = 8
            ProMotionDisplayLink.enable()
        }
    }
}
```

### 12.5 具体降级矩阵与防护策略

#### 12.5.1 功能降级矩阵

**核心功能降级策略**:

| 功能模块 | iOS 16+ | iOS 17+ | iOS 18+ | iOS 26+ | 降级备选方案 |
|----------|---------|---------|---------|---------|-------------|
| **OCR识别** | Vision基础 | Vision优化 | Vision高级 | Vision AI + 数学公式 | 云端OCR备选 |
| **通知系统** | 本地通知 | 智能调度 | 安静时段 | 深度链接增强 | 基础定时通知 |
| **App Intents** | ❌ 不支持 | ⚠️ 基础支持 | ✅ 完整支持 | ✅ 增强集成 | 渐进式增强，可选功能 |
| **CloudKit同步** | 私有数据库 | 多设备同步 | 完整同步 | 智能冲突解决 | 本地存储兜底 |
| **AR/visionOS** | ❌ 不支持 | ❌ 不支支持 | ⚠️ 基础AR | ✅ 完整支持 | 2D替代界面 |

#### 12.5.2 编译时与运行时防护

**编译时检查**:

```swift
// 功能可用性编译时检查
#if canImport(AppIntents)
    import AppIntents

    @available(iOS 16.0, *)
    struct CreateReviewItemIntent: AppIntent {
        // App Intents 实现
    }
#endif

// SwiftData可用性检查
#if canImport(SwiftData)
    import SwiftData
    @available(iOS 17.0, *)
    typealias ModernDataStore = SwiftDataStore
#else
    typealias ModernDataStore = CoreDataStore
#endif
```

**运行时能力检测**:

```swift
struct CapabilityGuard {
    static func hasVisionProSupport() -> Bool {
        guard #available(iOS 18.0, *) else { return false }
        return ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }

    static func hasAppIntentsSupport() -> Bool {
        guard #available(iOS 16.0, *) else { return false }
        return Bundle.main.object(forInfoDictionaryKey: "NSSupportsIntents") != nil
    }

    static func hasProactiveIntelligence() -> Bool {
        guard #available(iOS 26.0, *) else { return false }
        return ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26
    }
}
```

**优雅降级UI**:

```swift
@ViewBuilder
func createAdvancedFeatureView() -> some View {
    if CapabilityGuard.hasVisionProSupport() {
        ARReviewView()
    } else {
        FallbackReviewView()
            .overlay(
                Text("AR功能需要iOS 18+")
                    .foregroundColor(.secondary)
                    .font(.caption)
            )
    }
}
```

#### 12.5.3 MVP范围与未来版本规划

**MVP功能边界** (v6.0):

- **包含**: OCR基础识别、本地通知、CloudKit私有数据库多设备同步
- **延迟**: 数学公式结构化(vNext)、教师分享功能(vNext)、完整AR体验(vNext)

**渐进式增强策略**:

- **Phase 1** (v6.0): 核心错题管理 + Discovery社区
- **Phase 2** (v6.1): 数学公式增强 + App Intents集成
- **Phase 3** (v7.0): AR体验 + visionOS支持

---

## 变更日志 (Change Log)

**v6.0 (2025-09-19)**: 技术栈全面升级至iOS 26+ Swift 6.2

- 架构升级：Clean Architecture + Swift 6.2现代并发模式
- 性能目标：启动<0.8s，内存<150MB，OCR>95%准确率
- 新功能支持：Discovery社区、强化隐私保护、简化付费模式
- 平台策略：专注 iPhone 17 Pro+ 设备，前沿技术栈
- 合规增强：COPPA/GDPR完全合规，年龄分层保护
- 监控完善：基于Swift 6.2的性能监控和质量保证体系

**审批状态**:

- [x] 与PRD v6.0技术要求完全对齐
- [ ] 技术团队内部评审
- [ ] 架构评审委员会批准
- [ ] 安全团队合规审核

**最后更新**: 2025年9月19日 - TDD v6.0技术架构升级完成
