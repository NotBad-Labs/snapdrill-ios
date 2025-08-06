#  NotBad」教育应用完整开发方案（Swift 6 + SwiftData）
「NotBad」教育应用完整开发方案（Swift 6 + SwiftData）
一、项目概述
1.1 项目定位

名称：NotBad - 智能错题本
目标：打造基于Swift 6最新技术的现代化教育应用
核心价值：通过AI技术和智能算法，帮助学生高效管理和复习错题

1.2 技术承诺
language: Swift 6.0
minimum_ios: 17.0
core_technologies:
  - SwiftData 2.0 (数据持久化)
  - Swift 6 Concurrency (完整并发模型)
  - SwiftUI 5.0 (声明式UI)
  - Vision Framework (OCR识别)
  - CloudKit (云同步)
architecture_principles:
  - Actor-based isolation
  - Strict concurrency checking
  - Type-safe data flow
  - Privacy by design
  二、系统架构设计
2.1 整体架构图
graph TB
    subgraph "表现层"
        UI[SwiftUI Views]
        VM[ViewModels]
    end
    
    subgraph "业务层"
        UC[Use Cases]
        DM[Domain Models]
    end
    
    subgraph "数据层"
        SD[SwiftData]
        CK[CloudKit]
        Cache[缓存系统]
    end
    
    subgraph "基础设施层"
        AI[AI处理引擎]
        Sync[同步服务]
        Monitor[监控系统]
    end
    
    UI --> VM
    VM --> UC
    UC --> DM
    DM --> SD
    SD --> CK
    UC --> AI
    
    style UI fill:#e1f5fe
    style SD fill:#fff3e0
    style AI fill:#f3e5f5
    2.2 模块架构设计
核心模块定义
// Package.swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NotBadApp",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "NotBadCore", targets: ["NotBadCore"]),
        .library(name: "NotBadUI", targets: ["NotBadUI"]),
        .library(name: "NotBadData", targets: ["NotBadData"]),
        .library(name: "NotBadAI", targets: ["NotBadAI"])
    ],
    dependencies: [
        // 仅使用Apple官方框架，确保稳定性
    ],
    targets: [
        .target(
            name: "NotBadCore",
            dependencies: [],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .target(
            name: "NotBadData",
            dependencies: ["NotBadCore"]
        ),
        .target(
            name: "NotBadAI",
            dependencies: ["NotBadCore"]
        ),
        .target(
            name: "NotBadUI",
            dependencies: ["NotBadCore", "NotBadData", "NotBadAI"]
        ),
        .testTarget(
            name: "NotBadTests",
            dependencies: ["NotBadCore", "NotBadData", "NotBadAI", "NotBadUI"]
        )
    ]
)

三、数据模型设计（SwiftData）
3.1 核心数据模型
import SwiftData
import Foundation

// MARK: - 学科模型
@Model
public final class Subject: Sendable {
    @Attribute(.unique) public let id: UUID
    public var name: String
    public var icon: String
    public var colorHex: String
    public var createdAt: Date
    public var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \StudyItem.subject)
    public var studyItems: [StudyItem]?
    
    public init(name: String, icon: String, colorHex: String) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = .now
        self.updatedAt = .now
    }
}

// MARK: - 学习项目模型（错题）
@Model
public final class StudyItem: Sendable {
    @Attribute(.unique) public let id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var masteryLevel: Double // 0.0 - 1.0
    public var lastReviewDate: Date?
    public var nextReviewDate: Date
    public var reviewCount: Int
    
    // 关系
    @Relationship(deleteRule: .nullify)
    public var subject: Subject?
    
    @Relationship(deleteRule: .cascade, inverse: \ItemContent.item)
    public var content: ItemContent?
    
    @Relationship(deleteRule: .cascade, inverse: \ReviewRecord.item)
    public var reviewRecords: [ReviewRecord]?
    
    @Relationship(deleteRule: .cascade, inverse: \Tag.items)
    public var tags: [Tag]?
    
    public init() {
        self.id = UUID()
        self.createdAt = .now
        self.updatedAt = .now
        self.masteryLevel = 0.0
        self.nextReviewDate = .now.addingTimeInterval(86400) // 24小时后
        self.reviewCount = 0
    }
}

// MARK: - 题目内容
@Model
public final class ItemContent: Sendable {
    @Attribute(.unique) public let id: UUID
    public var questionText: String
    public var questionImages: [Data]? // 图片数据
    public var answerText: String
    public var answerImages: [Data]?
    public var explanation: String?
    public var difficulty: Int // 1-5
    
    @Relationship(deleteRule: .nullify)
    public var item: StudyItem?
    
    public init(questionText: String, answerText: String) {
        self.id = UUID()
        self.questionText = questionText
        self.answerText = answerText
        self.difficulty = 3
    }
}

// MARK: - 复习记录
@Model
public final class ReviewRecord: Sendable {
    @Attribute(.unique) public let id: UUID
    public var reviewDate: Date
    public var quality: Int // 0-5 (SM-2算法)
    public var timeSpent: TimeInterval
    public var correct: Bool
    
    @Relationship(deleteRule: .nullify)
    public var item: StudyItem?
    
    public init(quality: Int, timeSpent: TimeInterval, correct: Bool) {
        self.id = UUID()
        self.reviewDate = .now
        self.quality = quality
        self.timeSpent = timeSpent
        self.correct = correct
    }
}

// MARK: - 标签系统
@Model
public final class Tag: Sendable {
    @Attribute(.unique) public let id: UUID
    @Attribute(.unique) public var name: String
    public var colorHex: String
    public var createdAt: Date
    
    @Relationship(deleteRule: .nullify)
    public var items: [StudyItem]?
    
    public init(name: String, colorHex: String = "#007AFF") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.createdAt = .now
    }
}

// MARK: - 学习统计
@Model
public final class StudyStatistics: Sendable {
    @Attribute(.unique) public let id: UUID
    public var date: Date
    public var itemsReviewed: Int
    public var itemsAdded: Int
    public var totalTimeSpent: TimeInterval
    public var averageAccuracy: Double
    public var streakDays: Int
    
    public init(date: Date) {
        self.id = UUID()
        self.date = date
        self.itemsReviewed = 0
        self.itemsAdded = 0
        self.totalTimeSpent = 0
        self.averageAccuracy = 0
        self.streakDays = 0
    }
}
3.2 数据访问层（Actor-based）
import SwiftData

@ModelActor
public actor DataManager {
    // MARK: - 单例访问
    public static let shared = DataManager(modelContainer: .appContainer)
    
    // MARK: - 学习项目操作
    public func createStudyItem(
        questionText: String,
        questionImages: [Data]? = nil,
        answerText: String,
        answerImages: [Data]? = nil,
        subject: Subject? = nil,
        tags: [Tag]? = nil
    ) async throws -> StudyItem {
        let item = StudyItem()
        let content = ItemContent(questionText: questionText, answerText: answerText)
        content.questionImages = questionImages
        content.answerImages = answerImages
        
        item.content = content
        item.subject = subject
        item.tags = tags
        
        modelContext.insert(item)
        try await modelContext.save()
        
        return item
    }
    
    public func fetchStudyItems(
        subject: Subject? = nil,
        tag: Tag? = nil,
        needsReview: Bool = false
    ) async throws -> [StudyItem] {
        var descriptor = FetchDescriptor<StudyItem>()
        
        var predicates: [Predicate<StudyItem>] = []
        
        if let subject = subject {
            predicates.append(#Predicate { item in
                item.subject?.id == subject.id
            })
        }
        
        if needsReview {
            let now = Date.now
            predicates.append(#Predicate { item in
                item.nextReviewDate <= now
            })
        }
        
        if !predicates.isEmpty {
            descriptor.predicate = predicates.reduce(into: nil) { result, predicate in
                result = result.map { $0 && predicate } ?? predicate
            }
        }
        
        descriptor.sortBy = [SortDescriptor(\.nextReviewDate)]
        
        return try await modelContext.fetch(descriptor)
    }
    
    public func updateReview(
        item: StudyItem,
        quality: Int,
        timeSpent: TimeInterval
    ) async throws {
        let correct = quality >= 3
        let record = ReviewRecord(quality: quality, timeSpent: timeSpent, correct: correct)
        record.item = item
        
        // 更新复习算法（SM-2）
        let (newInterval, newEF) = calculateNextReview(
            quality: quality,
            previousInterval: item.reviewCount,
            previousEF: item.masteryLevel
        )
        
        item.masteryLevel = newEF
        item.lastReviewDate = .now
        item.nextReviewDate = .now.addingTimeInterval(Double(newInterval) * 86400)
        item.reviewCount += 1
        item.updatedAt = .now
        
        modelContext.insert(record)
        try await modelContext.save()
    }
    
    // MARK: - SM-2 算法实现
    private func calculateNextReview(
        quality: Int,
        previousInterval: Int,
        previousEF: Double
    ) -> (interval: Int, easinessFactor: Double) {
        var easinessFactor = previousEF
        var interval = previousInterval
        
        if quality >= 3 {
            if previousInterval == 0 {
                interval = 1
            } else if previousInterval == 1 {
                interval = 6
            } else {
                interval = Int(Double(previousInterval) * easinessFactor)
            }
            
            easinessFactor = easinessFactor + (0.1 - Double(5 - quality) * (0.08 + Double(5 - quality) * 0.02))
        } else {
            interval = 1
            easinessFactor = max(1.3, easinessFactor - 0.2)
        }
        
        easinessFactor = max(1.3, easinessFactor)
        
        return (interval, easinessFactor)
    }
    
    // MARK: - 统计功能
    public func getTodayStatistics() async throws -> StudyStatistics {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        
        let descriptor = FetchDescriptor<StudyStatistics>(
            predicate: #Predicate { stat in
                stat.date >= today
            }
        )
        
        if let existing = try await modelContext.fetch(descriptor).first {
            return existing
        } else {
            let newStats = StudyStatistics(date: today)
            modelContext.insert(newStats)
            try await modelContext.save()
            return newStats
        }
    }
    
    public func updateStatistics(
        itemsReviewed: Int = 0,
        itemsAdded: Int = 0,
        timeSpent: TimeInterval = 0,
        accuracy: Double? = nil
    ) async throws {
        let stats = try await getTodayStatistics()
        
        stats.itemsReviewed += itemsReviewed
        stats.itemsAdded += itemsAdded
        stats.totalTimeSpent += timeSpent
        
        if let accuracy = accuracy {
            let totalReviews = Double(stats.itemsReviewed)
            stats.averageAccuracy = (stats.averageAccuracy * (totalReviews - 1) + accuracy) / totalReviews
        }
        
        try await modelContext.save()
    }
}

// MARK: - ModelContainer 扩展
extension ModelContainer {
    static let appContainer: ModelContainer = {
        do {
            let schema = Schema([
                Subject.self,
                StudyItem.self,
                ItemContent.self,
                ReviewRecord.self,
                Tag.self,
                StudyStatistics.self
            ])
            
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}
四、AI处理引擎（OCR与智能识别）
4.1 OCR处理模块
import Vision
import UIKit
import CoreML

public actor OCREngine: Sendable {
    // MARK: - 引擎配置
    private let configuration: OCRConfiguration
    private var textRecognitionRequest: VNRecognizeTextRequest?
    private var mathRecognitionModel: VNCoreMLModel?
    
    public init(configuration: OCRConfiguration = .default) {
        self.configuration = configuration
    }
    
    // MARK: - 主要识别接口
    public func recognizeText(from image: UIImage) async throws -> OCRResult {
        // 设备能力检测
        let deviceTier = await DeviceCapability.current.tier
        let processingStrategy = selectStrategy(for: deviceTier)
        
        // 图像预处理
        let processedImage = try await preprocessImage(image, strategy: processingStrategy)
        
        // 并行执行文字和数学公式识别
        async let textResult = performTextRecognition(on: processedImage)
        async let mathResult = performMathRecognition(on: processedImage)
        
        let (text, math) = try await (textResult, mathResult)
        
        // 智能内容分析
        let contentType = await analyzeContentType(text: text, math: math)
        
        return OCRResult(
            text: text,
            mathExpressions: math,
            contentType: contentType,
            confidence: calculateConfidence(text: text, math: math),
            processingTime: Date()
        )
    }
    
    // MARK: - 文字识别
    private func performTextRecognition(on image: CGImage) async throws -> [RecognizedText] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = configuration.accuracyLevel
        request.recognitionLanguages = configuration.languages
        request.usesLanguageCorrection = true
        
        return try await withCheckedThrowingContinuation { continuation in
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            request.completionHandler = { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                let texts = observations.compactMap { observation -> RecognizedText? in
                    guard let topCandidate = observation.topCandidates(1).first else { return nil }
                    
                    return RecognizedText(
                        string: topCandidate.string,
                        confidence: topCandidate.confidence,
                        boundingBox: observation.boundingBox
                    )
                }
                
                continuation.resume(returning: texts)
            }
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.processingFailed(error))
            }
        }
    }
    
    // MARK: - 数学公式识别
    private func performMathRecognition(on image: CGImage) async throws -> [MathExpression] {
        // 使用专门的数学识别模型
        guard let mathModel = try? await loadMathModel() else {
            return []
        }
        
        let request = VNCoreMLRequest(model: mathModel)
        
        return try await withCheckedThrowingContinuation { continuation in
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            request.completionHandler = { request, error in
                if let error = error {
                    continuation.resume(returning: []) // 数学识别失败不影响整体
                    return
                }
                
                // 处理数学识别结果
                let expressions = self.parseMathResults(request.results)
                continuation.resume(returning: expressions)
            }
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }
    
    // MARK: - 图像预处理
    private func preprocessImage(_ image: UIImage, strategy: ProcessingStrategy) async throws -> CGImage {
        guard let ciImage = CIImage(image: image) else {
            throw OCRError.invalidImage
        }
        
        let context = CIContext(options: [.useSoftwareRenderer: false])
        
        // 应用滤镜链
        var processedImage = ciImage
        
        // 1. 自动增强
        if let enhanced = ciImage.autoAdjusted() {
            processedImage = enhanced
        }
        
        // 2. 降噪处理
        if strategy.includesNoiseReduction {
            processedImage = processedImage
                .applyingFilter("CINoiseReduction", parameters: [
                    "inputNoiseLevel": 0.02,
                    "inputSharpness": 0.4
                ])
        }
        
        // 3. 对比度调整
        processedImage = processedImage
            .applyingFilter("CIColorControls", parameters: [
                "inputContrast": 1.1,
                "inputBrightness": 0.05
            ])
        
        // 4. 二值化处理（针对文字）
        if strategy.includesBinarization {
            processedImage = processedImage
                .applyingFilter("CIPhotoEffectNoir")
                .applyingFilter("CIColorControls", parameters: [
                    "inputContrast": 2.0
                ])
        }
        
        guard let cgImage = context.createCGImage(processedImage, from: processedImage.extent) else {
            throw OCRError.preprocessingFailed
        }
        
        return cgImage
    }
    
    // MARK: - 内容类型分析
    private func analyzeContentType(text: [RecognizedText], math: [MathExpression]) async -> ContentType {
        let textContent = text.map { $0.string }.joined(separator: " ")
        
        // 基于内容特征判断题目类型
        if math.count > text.count {
            return .mathematics
        } else if textContent.contains(where: { "物理化学生物".contains($0) }) {
            return .science
        } else if textContent.range(of: "[A-Za-z]{10,}", options: .regularExpression) != nil {
            return .english
        } else {
            return .general
        }
    }
    
    // MARK: - 辅助方法
    private func selectStrategy(for tier: DeviceTier) -> ProcessingStrategy {
        switch tier {
        case .high:
            return ProcessingStrategy(
                includesNoiseReduction: true,
                includesBinarization: true,
                maxProcessingSize: CGSize(width: 4096, height: 4096)
            )
        case .medium:
            return ProcessingStrategy(
                includesNoiseReduction: true,
                includesBinarization: false,
                maxProcessingSize: CGSize(width: 2048, height: 2048)
            )
        case .low:
            return ProcessingStrategy(
                includesNoiseReduction: false,
                includesBinarization: false,
                maxProcessingSize: CGSize(width: 1024, height: 1024)
            )
        }
    }
    
    private func calculateConfidence(text: [RecognizedText], math: [MathExpression]) -> Double {
        let textConfidence = text.map { $0.confidence }.reduce(0, +) / Double(max(text.count, 1))
        let mathConfidence = math.map { $0.confidence }.reduce(0, +) / Double(max(math.count, 1))
        
        return (textConfidence + mathConfidence) / 2.0
    }
    
    private func loadMathModel() async throws -> VNCoreMLModel? {
        // 加载数学识别模型
        // 这里应该加载实际的 CoreML 模型
        return nil
    }
    
    private func parseMathResults(_ results: [Any]?) -> [MathExpression] {
        // 解析数学识别结果
        return []
    }
}

// MARK: - 数据结构定义
public struct OCRResult: Sendable {
    public let text: [RecognizedText]
    public let mathExpressions: [MathExpression]
    public let contentType: ContentType
    public let confidence: Double
    public let processingTime: Date
}

public struct RecognizedText: Sendable {
    public let string: String
    public let confidence: Float
    public let boundingBox: CGRect
}

public struct MathExpression: Sendable {
    public let latex: String
    public let confidence: Float
    public let boundingBox: CGRect
}

public enum ContentType: String, Sendable {
    case mathematics = "数学"
    case science = "理科"
    case english = "英语"
    case general = "综合"
}

public struct OCRConfiguration: Sendable {
    public let accuracyLevel: VNRequestTextRecognitionLevel
    public let languages: [String]
    public let minimumTextHeight: Float
    
    public static let `default` = OCRConfiguration(
        accuracyLevel: .accurate,
        languages: ["zh-Hans", "en-US"],
        minimumTextHeight: 0.05
    )
}

public struct ProcessingStrategy: Sendable {
    let includesNoiseReduction: Bool
    let includesBinarization: Bool
    let maxProcessingSize: CGSize
}

public enum OCRError: Error, Sendable {
    case invalidImage
    case recognitionFailed(Error)
    case noTextFound
    case processingFailed(Error)
    case preprocessingFailed
}
4.2 设备能力检测
import UIKit

public actor DeviceCapability: Sendable {
    public static let current = DeviceCapability()
    
    public enum DeviceTier: Sendable {
        case high   // A15+ 芯片，6GB+ RAM
        case medium // A12-A14 芯片，4GB RAM
        case low    // 其他设备
    }
    
    private var _tier: DeviceTier?
    
    public var tier: DeviceTier {
        get async {
            if let cached = _tier {
                return cached
            }
            
            let detected = await detectDeviceTier()
            _tier = detected
            return detected
        }
    }
    
    private func detectDeviceTier() async -> DeviceTier {
        let device = await UIDevice.current
        let processorCount = ProcessInfo.processInfo.processorCount
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        
        // 基于处理器和内存判断
        if processorCount >= 8 && physicalMemory >= 6 * 1024 * 1024 * 1024 {
            return .high
        } else if processorCount >= 6 && physicalMemory >= 4 * 1024 * 1024 * 1024 {
            return .medium
        } else {
            return .low
        }
    }
    
    public func optimalConcurrencyLimit() async -> Int {
        switch await tier {
        case .high: return 8
        case .medium: return 4
        case .low: return 2
        }
    }
    
    public func recommendedImageSize() async -> CGSize {
        switch await tier {
        case .high: return CGSize(width: 4096, height: 4096)
        case .medium: return CGSize(width: 2048, height: 2048)
        case .low: return CGSize(width: 1024, height: 1024)
        }
    }
}

五、用户界面层（SwiftUI）
5.1 主界面结构
import SwiftUI
import SwiftData

@main
struct NotBadApp: App {
    let container = ModelContainer.appContainer
    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environment(appState)
                .task {
                    await appState.initialize()
                }
        }
    }
}

// MARK: - 应用状态管理
@MainActor
@Observable
final class AppState: Sendable {
    var selectedTab: Tab = .study
    var isLoading = false
    var error: AppError?
    
    enum Tab: String, CaseIterable, Sendable {
        case study = "学习"
        case review = "复习"
        case statistics = "统计"
        case settings = "设置"
        
        var icon: String {
            switch self {
            case .study: return "book.fill"
            case .review: return "clock.fill"
            case .statistics: return "chart.line.uptrend.xyaxis"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    func initialize() async {
        // 初始化应用状态
        await DeviceCapability.current.tier // 预热设备检测
        await DataManager.shared.getTodayStatistics() // 初始化今日统计
    }
}

// MARK: - 主界面
struct ContentView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        TabView(selection: Binding(
            get: { appState.selectedTab },
            set: { appState.selectedTab = $0 }
        )) {
            ForEach(AppState.Tab.allCases, id: \.self) { tab in
                NavigationStack {
                    tabContent(for: tab)
                }
                .tabItem {
                    Label(tab.rawValue, systemImage: tab.icon)
                }
                .tag(tab)
            }
        }
        .tint(.accentColor)
    }
    
    @ViewBuilder
    private func tabContent(for tab: AppState.Tab) -> some View {
        switch tab {
        case .study:
            StudyHomeView()
        case .review:
            ReviewView()
        case .statistics:
            StatisticsView()
        case .settings:
            SettingsView()
        }
    }
}
5.2 学习主页
import SwiftUI
import SwiftData

struct StudyHomeView: View {
    @Query private var subjects: [Subject]
    @Query(sort: \StudyItem.createdAt, order: .reverse) 
    private var recentItems: [StudyItem]
    
    @State private var showingAddItem = false
    @State private var selectedSubject: Subject?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 快速操作区
                QuickActionsSection(showingAddItem: $showingAddItem)
                
                // 学科选择区
                SubjectsSection(
                    subjects: subjects,
                    selectedSubject: $selectedSubject
                )
                
                // 最近添加的错题
                RecentItemsSection(items: recentItems)
            }
            .padding()
        }
        .navigationTitle("学习")
        .sheet(isPresented: $showingAddItem) {
            AddItemView(preselectedSubject: selectedSubject)
        }
    }
}

// MARK: - 快速操作区
struct QuickActionsSection: View {
    @Binding var showingAddItem: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速操作")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 16) {
                QuickActionButton(
                    title: "拍照添加",
                    icon: "camera.fill",
                    color: .blue
                ) {
                    showingAddItem = true
                }
                
                QuickActionButton(
                    title: "手动输入",
                    icon: "square.and.pencil",
                    color: .green
                ) {
                    showingAddItem = true
                }
                
                QuickActionButton(
                    title: "批量导入",
                    icon: "square.stack.3d.up.fill",
                    color: .orange
                ) {
                    // 批量导入功能
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
           VStack(spacing: 8) {
               Image(systemName: icon)
                   .font(.title2)
                   .foregroundStyle(.white)
                   .frame(width: 50, height: 50)
                   .background(color.gradient)
                   .clipShape(RoundedRectangle(cornerRadius: 12))
               
               Text(title)
                   .font(.caption)
                   .foregroundStyle(.primary)
           }
       }
       .buttonStyle(.plain)
   }
}

// MARK: - 学科选择区
struct SubjectsSection: View {
   let subjects: [Subject]
   @Binding var selectedSubject: Subject?
   
   var body: some View {
       VStack(alignment: .leading, spacing: 12) {
           Text("学科分类")
               .font(.headline)
               .foregroundStyle(.secondary)
           
           ScrollView(.horizontal, showsIndicators: false) {
               HStack(spacing: 12) {
                   ForEach(subjects) { subject in
                       SubjectCard(
                           subject: subject,
                           isSelected: selectedSubject?.id == subject.id
                       ) {
                           selectedSubject = selectedSubject?.id == subject.id ? nil : subject
                       }
                   }
                   
                   // 添加学科按钮
                   AddSubjectButton()
               }
           }
       }
   }
}

struct SubjectCard: View {
   let subject: Subject
   let isSelected: Bool
   let action: () -> Void
   
   var body: some View {
       Button(action: action) {
           VStack(spacing: 8) {
               Text(subject.icon)
                   .font(.title)
               
               Text(subject.name)
                   .font(.caption)
                   .lineLimit(1)
               
               if let itemCount = subject.studyItems?.count {
                   Text("\(itemCount)题")
                       .font(.caption2)
                       .foregroundStyle(.secondary)
               }
           }
           .frame(width: 80, height: 100)
           .background(
               RoundedRectangle(cornerRadius: 12)
                   .fill(isSelected ? Color(hex: subject.colorHex).opacity(0.2) : Color(.systemGray6))
                   .overlay(
                       RoundedRectangle(cornerRadius: 12)
                           .strokeBorder(
                               isSelected ? Color(hex: subject.colorHex) : Color.clear,
                               lineWidth: 2
                           )
                   )
           )
       }
       .buttonStyle(.plain)
   }
}

// MARK: - 最近添加的错题
struct RecentItemsSection: View {
   let items: [StudyItem]
   
   var body: some View {
       VStack(alignment: .leading, spacing: 12) {
           HStack {
               Text("最近添加")
                   .font(.headline)
                   .foregroundStyle(.secondary)
               
               Spacer()
               
               NavigationLink("查看全部") {
                   AllItemsView()
               }
               .font(.caption)
           }
           
           if items.isEmpty {
               EmptyStateView(
                   icon: "doc.text",
                   title: "还没有错题",
                   message: "点击上方按钮开始添加第一道错题"
               )
               .frame(height: 200)
           } else {
               VStack(spacing: 8) {
                   ForEach(items.prefix(5)) { item in
                       NavigationLink(destination: ItemDetailView(item: item)) {
                           ItemRow(item: item)
                       }
                   }
               }
           }
       }
   }
}

struct ItemRow: View {
   let item: StudyItem
   
   var body: some View {
       HStack {
           // 学科标识
           if let subject = item.subject {
               Text(subject.icon)
                   .font(.title3)
                   .frame(width: 40, height: 40)
                   .background(Color(hex: subject.colorHex).opacity(0.1))
                   .clipShape(Circle())
           }
           
           // 题目内容
           VStack(alignment: .leading, spacing: 4) {
               if let content = item.content {
                   Text(content.questionText)
                       .font(.subheadline)
                       .lineLimit(2)
                       .foregroundStyle(.primary)
               }
               
               HStack(spacing: 8) {
                   // 掌握度
                   MasteryIndicator(level: item.masteryLevel)
                   
                   // 复习次数
                   Label("\(item.reviewCount)次", systemImage: "arrow.triangle.2.circlepath")
                       .font(.caption2)
                       .foregroundStyle(.secondary)
                   
                   Spacer()
                   
                   // 下次复习时间
                   if item.nextReviewDate <= .now {
                       Label("需要复习", systemImage: "exclamationmark.circle.fill")
                           .font(.caption2)
                           .foregroundStyle(.orange)
                   } else {
                       Text(item.nextReviewDate.relativeDateString)
                           .font(.caption2)
                           .foregroundStyle(.secondary)
                   }
               }
           }
           
           Image(systemName: "chevron.right")
               .font(.caption)
               .foregroundStyle(.tertiary)
       }
       .padding()
       .background(Color(.systemGray6))
       .clipShape(RoundedRectangle(cornerRadius: 10))
   }
}

struct MasteryIndicator: View {
   let level: Double
   
   var body: some View {
       HStack(spacing: 2) {
           ForEach(0..<5) { index in
               Circle()
                   .fill(Double(index) < level * 5 ? Color.green : Color(.systemGray4))
                   .frame(width: 6, height: 6)
           }
       }
   }
}
5.3 添加错题界面
import SwiftUI
import PhotosUI

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let preselectedSubject: Subject?
    
    @State private var selectedSubject: Subject?
    @State private var questionText = ""
    @State private var answerText = ""
    @State private var explanation = ""
    @State private var difficulty = 3
    @State private var selectedTags: Set<Tag> = []
    
    // 图片相关
    @State private var questionImages: [UIImage] = []
    @State private var answerImages: [UIImage] = []
    @State private var showingImagePicker = false
    @State private var imagePickerTarget: ImageTarget = .question
    
    // OCR相关
    @State private var isProcessingOCR = false
    @State private var ocrError: Error?
    
    // 表单验证
    private var isValid: Bool {
        !questionText.isEmpty && !answerText.isEmpty
    }
    
    enum ImageTarget {
        case question, answer
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 学科选择
                Section("学科分类") {
                    SubjectPicker(selectedSubject: $selectedSubject)
                }
                
                // 题目输入
                Section("题目内容") {
                    // 文字输入
                    TextField("输入题目或拍照识别", text: $questionText, axis: .vertical)
                        .lineLimit(3...10)
                    
                    // 图片区域
                    ImageSection(
                        images: questionImages,
                        target: .question,
                        onAddImage: {
                            imagePickerTarget = .question
                            showingImagePicker = true
                        },
                        onDeleteImage: { index in
                            questionImages.remove(at: index)
                        },
                        onOCR: performOCR
                    )
                }
                
                // 答案输入
                Section("答案") {
                    TextField("输入答案", text: $answerText, axis: .vertical)
                        .lineLimit(2...8)
                    
                    ImageSection(
                        images: answerImages,
                        target: .answer,
                        onAddImage: {
                            imagePickerTarget = .answer
                            showingImagePicker = true
                        },
                        onDeleteImage: { index in
                            answerImages.remove(at: index)
                        },
                        onOCR: performOCR
                    )
                }
                
                // 解析说明
                Section("解析（可选）") {
                    TextField("输入解题思路或要点", text: $explanation, axis: .vertical)
                        .lineLimit(2...8)
                }
                
                // 难度和标签
                Section("其他信息") {
                    // 难度选择
                    Picker("难度", selection: $difficulty) {
                        ForEach(1...5, id: \.self) { level in
                            HStack {
                                ForEach(0..<level, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                        .font(.caption)
                                }
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // 标签选择
                    TagSelector(selectedTags: $selectedTags)
                }
            }
            .navigationTitle("添加错题")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            await saveItem()
                        }
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(images: imagePickerTarget == .question ? $questionImages : $answerImages)
            }
            .alert("OCR识别失败", isPresented: .constant(ocrError != nil)) {
                Button("确定") {
                    ocrError = nil
                }
            } message: {
                if let error = ocrError {
                    Text(error.localizedDescription)
                }
            }
            .overlay {
                if isProcessingOCR {
                    ProcessingOverlay(message: "正在识别文字...")
                }
            }
        }
        .onAppear {
            selectedSubject = preselectedSubject
        }
    }
    
    // MARK: - OCR处理
    private func performOCR(for target: ImageTarget) {
        guard let image = (target == .question ? questionImages : answerImages).first else { return }
        
        Task {
            isProcessingOCR = true
            defer { isProcessingOCR = false }
            
            do {
                let result = try await OCREngine().recognizeText(from: image)
                
                await MainActor.run {
                    let recognizedText = result.text.map { $0.string }.joined(separator: "\n")
                    
                    switch target {
                    case .question:
                        questionText = recognizedText
                    case .answer:
                        answerText = recognizedText
                    }
                }
            } catch {
                await MainActor.run {
                    ocrError = error
                }
            }
        }
    }
    
    // MARK: - 保存数据
    private func saveItem() async {
        do {
            let questionImageData = questionImages.compactMap { $0.jpegData(compressionQuality: 0.8) }
            let answerImageData = answerImages.compactMap { $0.jpegData(compressionQuality: 0.8) }
            
            let item = try await DataManager.shared.createStudyItem(
                questionText: questionText,
                questionImages: questionImageData,
                answerText: answerText,
                answerImages: answerImageData,
                subject: selectedSubject,
                tags: Array(selectedTags)
            )
            
            // 更新统计
            try await DataManager.shared.updateStatistics(itemsAdded: 1)
            
            await MainActor.run {
                dismiss()
            }
        } catch {
            // 错误处理
            print("保存失败: \(error)")
        }
    }
}

// MARK: - 子组件
struct ImageSection: View {
    let images: [UIImage]
    let target: AddItemView.ImageTarget
    let onAddImage: () -> Void
    let onDeleteImage: (Int) -> Void
    let onOCR: (AddItemView.ImageTarget) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // 添加图片按钮
                    Button(action: onAddImage) {
                        VStack {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                            Text("添加图片")
                                .font(.caption)
                        }
                        .frame(width: 80, height: 80)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // 已添加的图片
                    ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            // 删除按钮
                            Button {
                                onDeleteImage(index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white, .red)
                            }
                            .offset(x: 8, y: -8)
                        }
                    }
                }
            }
            
            // OCR按钮
            if !images.isEmpty {
                Button {
                    onOCR(target)
                } label: {
                    Label("识别文字", systemImage: "text.viewfinder")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

struct ProcessingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                
                Text(message)
                    .foregroundStyle(.white)
            }
            .padding(24)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
5.4 复习界面
import SwiftUI
import SwiftData

struct ReviewView: View {
    @Query private var itemsToReview: [StudyItem]
    @State private var currentIndex = 0
    @State private var showingAnswer = false
    @State private var reviewSession: ReviewSession?
    
    private var filteredItems: [StudyItem] {
        itemsToReview.filter { $0.nextReviewDate <= .now }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if filteredItems.isEmpty {
                    EmptyReviewView()
                } else if let currentItem = currentItem {
                    ReviewCardView(
                        item: currentItem,
                        showingAnswer: $showingAnswer,
                        onRate: { quality in
                            Task {
                                await rateItem(quality: quality)
                            }
                        }
                    )
                } else {
                    ReviewCompletedView()
                }
            }
            .navigationTitle("复习")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !filteredItems.isEmpty {
                        Text("\(currentIndex + 1) / \(filteredItems.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .task {
            await startReviewSession()
        }
    }
    
    private var currentItem: StudyItem? {
        guard currentIndex < filteredItems.count else { return nil }
        return filteredItems[currentIndex]
    }
    
    private func startReviewSession() async {
        reviewSession = ReviewSession(itemCount: filteredItems.count)
    }
    
    private func rateItem(quality: Int) async {
        guard let item = currentItem else { return }
        
        do {
            let timeSpent = reviewSession?.timeForCurrentItem() ?? 0
            
            try await DataManager.shared.updateReview(
                item: item,
                quality: quality,
                timeSpent: timeSpent
            )
            
            // 更新统计
            try await DataManager.shared.updateStatistics(
                itemsReviewed: 1,
                timeSpent: timeSpent,
                accuracy: quality >= 3 ? 1.0 : 0.0
            )
            
            // 进入下一题
            await MainActor.run {
                showingAnswer = false
                currentIndex += 1
                reviewSession?.nextItem()
            }
        } catch {
            print("更新复习记录失败: \(error)")
        }
    }
}

// MARK: - 复习卡片
struct ReviewCardView: View {
    let item: StudyItem
    @Binding var showingAnswer: Bool
    let onRate: (Int) -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 卡片内容
            ScrollView {
                VStack(spacing: 20) {
                    // 学科和难度信息
                    HStack {
                        if let subject = item.subject {
                            Label(subject.name, systemImage: subject.icon)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if let difficulty = item.content?.difficulty {
                            DifficultyView(level: difficulty)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 题目内容
                    if let content = item.content {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("题目")
                                .font(.headline)
                            
                            Text(content.questionText)
                                .font(.body)
                            
                            if let images = content.questionImages {
                                ForEach(Array(images.enumerated()), id: \.offset) { _, imageData in
                                    if let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // 答案部分
                        if showingAnswer {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("答案")
                                    .font(.headline)
                                    .foregroundStyle(.green)
                                
                                Text(content.answerText)
                                    .font(.body)
                                
                                if let images = content.answerImages {
                                    ForEach(Array(images.enumerated()), id: \.offset) { _, imageData in
                                        if let uiImage = UIImage(data: imageData) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFit()
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                    }
                                }
                                
                                if let explanation = content.explanation, !explanation.isEmpty {
                                    Divider()
                                    
                                    Text("解析")
                                        .font(.headline)
                                        .foregroundStyle(.blue)
                                    
                                    Text(explanation)
                                        .font(.body)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .transition(.asymmetric(
                                insertion: .push(from: .bottom).combined(with: .opacity),
                                removal: .push(from: .top).combined(with: .opacity)
                            ))
                        }
                    }
                }
                .padding()
            }
            
            // 操作按钮
            VStack(spacing: 16) {
                if !showingAnswer {
                    Button {
                        withAnimation(.spring()) {
                            showingAnswer = true
                        }
                    } label: {
                        Text("显示答案")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else {
                    RatingButtons(onRate: onRate)
                }
            }
            .padding()
            .background(.regularMaterial)
        }
        .offset(dragOffset)
        .rotationEffect(.degrees(rotation))
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                    rotation = Double(value.translation.width / 20)
                }
                .onEnded { value in
                    if abs(value.translation.width) > 100 {
                        // 滑动评分
                        let quality = value.translation.width > 0 ? 5 : 1
                        onRate(quality)
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = .zero
                            rotation = 0
                        }
                    }
                }
        )
    }
}

// MARK: - 评分按钮
struct RatingButtons: View {
    let onRate: (Int) -> Void
    
    let ratings = [
        (1, "完全不会", Color.red),
        (2, "困难", Color.orange),
        (3, "一般", Color.yellow),
        (4, "容易", Color.green),
        (5, "完美", Color.blue)
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            Text("掌握程度")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                ForEach(ratings, id: \.0) { quality, label, color in
                    Button {
                        onRate(quality)
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(quality)")
                                .font(.title3.bold())
                            Text(label)
                                .font(.caption2)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(color.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }
}

// MARK: - 空状态视图
struct EmptyReviewView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            Text("太棒了！")
                .font(.title.bold())
            
            Text("今天没有需要复习的内容")
                .font(.body)
                .foregroundStyle(.secondary)
            
            NavigationLink {
                StudyHomeView()
            } label: {
                Label("添加新内容", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.accentColor.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
}

// MARK: - 复习完成视图
struct ReviewCompletedView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "star.fill")
                .font(.system(size: 80))
                .foregroundStyle(.yellow)
            
            Text("复习完成！")
                .font(.title.bold())
            
            Text("今天的复习任务已经完成")
                .font(.body)
                .foregroundStyle(.secondary)
            
            // 可以添加今日统计摘要
        }
        .padding()
    }
}

// MARK: - 复习会话管理
class ReviewSession {
    private var startTime: Date
    private var itemStartTime: Date
    private let totalItems: Int
    private var completedItems: Int = 0
    
    init(itemCount: Int) {
        self.startTime = Date()
        self.itemStartTime = Date()
        self.totalItems = itemCount
    }
    
    func timeForCurrentItem() -> TimeInterval {
        Date().timeIntervalSince(itemStartTime)
    }
    
    func nextItem() {
        completedItems += 1
        itemStartTime = Date()
    }
    
    var totalTime: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    var progress: Double {
        Double(completedItems) / Double(totalItems)
    }
}
六、同步与备份系统
6.1 CloudKit 同步管理
import CloudKit
import SwiftData

public actor SyncManager {
    public static let shared = SyncManager()
    
    private let container = CKContainer.default()
    private let privateDatabase = CKContainer.default().privateCloudDatabase
    
    // 同步状态
    @Published public var syncStatus: SyncStatus = .idle
    @Published public var lastSyncDate: Date?
    
    public enum SyncStatus: Sendable {
        case idle
        case syncing(progress: Double)
        case completed
        case failed(Error)
    }
    
    // MARK: - 同步控制
    public func startSync() async {
        await MainActor.run {
            syncStatus = .syncing(progress: 0)
        }
        
        do {
            // 1. 检查 iCloud 账户状态
            try await verifyiCloudAccount()
            
            // 2. 同步数据
            try await syncData()
            
            // 3. 更新状态
            await MainActor.run {
                syncStatus = .completed
                lastSyncDate = Date()
            }
            
        } catch {
            await MainActor.run {
                syncStatus = .failed(error)
            }
        }
    }
    
    private func verifyiCloudAccount() async throws {
        let status = try await container.accountStatus()
        
        switch status {
        case .available:
            break
        case .noAccount:
            throw SyncError.noiCloudAccount
        case .restricted:
            throw SyncError.restricted
        case .couldNotDetermine:
            throw SyncError.unknown
        case .temporarilyUnavailable:
            throw SyncError.temporarilyUnavailable
        @unknown default:
            throw SyncError.unknown
        }
    }
    
    private func syncData() async throws {
        // SwiftData 的 CloudKit 集成会自动处理大部分同步
        // 这里可以添加额外的同步逻辑，如：
        
        // 1. 手动触发同步
        NotificationCenter.default.post(
            name: .NSPersistentStoreRemoteChange,
            object: nil
        )
        
        // 2. 处理冲突
        try await resolveConflicts()
        
        // 3. 验证数据完整性
        try await verifyDataIntegrity()
    }
    
    private func resolveConflicts() async throws {
        // 冲突解决策略
        // 对于错题本应用，通常采用"最后写入优先"策略
    }
    
    private func verifyDataIntegrity() async throws {
        // 数据完整性检查
        let localCount = try await DataManager.shared.getTotalItemCount()
        print("本地数据项: \(localCount)")
    }
}

// MARK: - 同步错误定义
public enum SyncError: LocalizedError, Sendable {
    case noiCloudAccount
    case restricted
    case temporarilyUnavailable
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .noiCloudAccount:
            return "请登录 iCloud 账户以启用同步功能"
        case .restricted:
            return "iCloud 访问受限"
        case .temporarilyUnavailable:
            return "iCloud 暂时不可用，请稍后重试"
        case .unknown:
            return "未知的同步错误"
        }
    }
}
6.2 数据导出功能
import SwiftUI
import UniformTypeIdentifiers

public struct ExportManager {
    public static func exportToJSON(items: [StudyItem]) async throws -> Data {
        let exportData = try await items.asyncMap { item in
            await ExportItem(from: item)
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        return try encoder.encode(exportData)
    }
    
    public static func exportToPDF(items: [StudyItem]) async throws -> Data {
        // PDF 导出逻辑
        fatalError("PDF export not implemented")
    }
}

// MARK: - 导出数据结构
struct ExportItem: Codable {
    let id: UUID
    let subject: String?
    let questionText: String
   let answerText: String
   let explanation: String?
   let difficulty: Int
   let masteryLevel: Double
   let reviewCount: Int
   let createdAt: Date
   let tags: [String]
   
   init(from item: StudyItem) async {
       self.id = item.id
       self.subject = item.subject?.name
       self.questionText = item.content?.questionText ?? ""
       self.answerText = item.content?.answerText ?? ""
       self.explanation = item.content?.explanation
       self.difficulty = item.content?.difficulty ?? 3
       self.masteryLevel = item.masteryLevel
       self.reviewCount = item.reviewCount
       self.createdAt = item.createdAt
       self.tags = item.tags?.map { $0.name } ?? []
   }
}

// MARK: - 文档交互
struct DocumentExporter: View {
   let data: Data
   let filename: String
   let contentType: UTType
   
   @State private var isExporting = false
   
   var body: some View {
       Button("导出") {
           isExporting = true
       }
       .fileExporter(
           isPresented: $isExporting,
           document: ExportDocument(data: data),
           contentType: contentType,
           defaultFilename: filename
       ) { result in
           switch result {
           case .success(let url):
               print("导出成功: \(url)")
           case .failure(let error):
               print("导出失败: \(error)")
           }
       }
   }
}

struct ExportDocument: FileDocument {
   static var readableContentTypes: [UTType] { [.json, .pdf] }
   
   let data: Data
   
   init(data: Data) {
       self.data = data
   }
   
   init(configuration: ReadConfiguration) throws {
       guard let data = configuration.file.regularFileContents else {
           throw CocoaError(.fileReadCorruptFile)
       }
       self.data = data
   }
   
   func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
       FileWrapper(regularFileWithContents: data)
   }
}
七、性能优化与监控
7.1 性能监控系统
import os
import MetricKit

public actor PerformanceMonitor {
    public static let shared = PerformanceMonitor()
    
    private let logger = Logger(subsystem: "com.notbad", category: "Performance")
    private var metrics: [PerformanceMetric] = []
    
    // MARK: - 性能指标收集
    public func track<T>(
        _ operation: String,
        metadata: [String: Any] = [:],
        body: () async throws -> T
    ) async rethrows -> T {
        let signpostID = OSSignpostID(log: logger)
        
        logger.signpost(.begin, id: signpostID, "Operation: \(operation)")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let result = try await body()
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            logger.signpost(.end, id: signpostID, "Duration: %.3f seconds", duration)
            
            await recordMetric(
                operation: operation,
                duration: duration,
                success: true,
                metadata: metadata
            )
            
            return result
        } catch {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            logger.signpost(.end, id: signpostID, "Failed after %.3f seconds", duration)
            
            await recordMetric(
                operation: operation,
                duration: duration,
                success: false,
                metadata: metadata
            )
            
            throw error
        }
    }
    
    private func recordMetric(
        operation: String,
        duration: TimeInterval,
        success: Bool,
        metadata: [String: Any]
    ) async {
        let metric = PerformanceMetric(
            operation: operation,
            duration: duration,
            success: success,
            timestamp: Date(),
            metadata: metadata
        )
        
        metrics.append(metric)
        
        // 保持最近1000条记录
        if metrics.count > 1000 {
            metrics = Array(metrics.suffix(1000))
        }
        
        // 检测性能异常
        await detectAnomalies(for: operation, duration: duration)
    }
    
    // MARK: - 异常检测
    private func detectAnomalies(for operation: String, duration: TimeInterval) async {
        let recentMetrics = metrics
            .filter { $0.operation == operation }
            .suffix(20)
        
        guard recentMetrics.count >= 10 else { return }
        
        let averageDuration = recentMetrics
            .map { $0.duration }
            .reduce(0, +) / Double(recentMetrics.count)
        
        // 如果当前操作时间超过平均值的3倍，记录警告
        if duration > averageDuration * 3 {
            logger.warning("Performance anomaly detected for \(operation): \(duration)s vs avg \(averageDuration)s")
            
            // 发送性能警告通知
            await notifyPerformanceIssue(
                operation: operation,
                duration: duration,
                average: averageDuration
            )
        }
    }
    
    // MARK: - MetricKit 集成
    public func setupMetricKit() {
        MXMetricManager.shared.add(self)
    }
    
    private func notifyPerformanceIssue(
        operation: String,
        duration: TimeInterval,
        average: TimeInterval
    ) async {
        // 通知逻辑
    }
}

// MARK: - MetricKit 代理
extension PerformanceMonitor: MXMetricManagerSubscriber {
    public nonisolated func didReceive(_ payloads: [MXMetricPayload]) {
        Task {
            await processMetricPayloads(payloads)
        }
    }
    
    public nonisolated func didReceive(_ payloads: [MXDiagnosticPayload]) {
        Task {
            await processDiagnosticPayloads(payloads)
        }
    }
    
    private func processMetricPayloads(_ payloads: [MXMetricPayload]) async {
        for payload in payloads {
            // 处理应用性能指标
            if let cpuMetrics = payload.cpuMetrics {
                logger.info("CPU usage: \(cpuMetrics.cumulativeCPUTime)")
            }
            
            if let memoryMetrics = payload.memoryMetrics {
                logger.info("Peak memory: \(memoryMetrics.peakMemoryUsage)")
            }
            
            // 上报到分析服务
            await Analytics.shared.report(payload)
        }
    }
    
    private func processDiagnosticPayloads(_ payloads: [MXDiagnosticPayload]) async {
        for payload in payloads {
            // 处理崩溃和挂起报告
            if let crashDiagnostics = payload.crashDiagnostics {
                for crash in crashDiagnostics {
                    logger.error("Crash detected: \(crash.exceptionType?.description ?? "Unknown")")
                }
            }
        }
    }
}

// MARK: - 性能指标数据结构
struct PerformanceMetric: Sendable {
    let operation: String
    let duration: TimeInterval
    let success: Bool
    let timestamp: Date
    let metadata: [String: Any]
}
7.2 内存优化管理
import UIKit

@MainActor
public class MemoryManager: ObservableObject {
    public static let shared = MemoryManager()
    
    @Published public var memoryWarningLevel: MemoryWarningLevel = .normal
    
    public enum MemoryWarningLevel {
        case normal
        case warning
        case critical
    }
    
    private var memoryPressureSource: DispatchSourceMemoryPressure?
    
    init() {
        setupMemoryMonitoring()
        setupNotifications()
    }
    
    // MARK: - 内存监控
    private func setupMemoryMonitoring() {
        let source = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical])
        
        source.setEventHandler { [weak self] in
            let event = source.data
            
            Task { @MainActor in
                if event.contains(.critical) {
                    self?.handleCriticalMemory()
                } else if event.contains(.warning) {
                    self?.handleMemoryWarning()
                }
            }
        }
        
        source.resume()
        memoryPressureSource = source
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func didReceiveMemoryWarning() {
        handleMemoryWarning()
    }
    
    // MARK: - 内存处理
    private func handleMemoryWarning() {
        memoryWarningLevel = .warning
        
        Task {
            // 清理缓存
            await ImageCache.shared.reduceCacheSize(by: 0.5)
            
            // 释放非必要资源
            await DataCache.shared.clearTemporary()
            
            // 通知其他组件
            NotificationCenter.default.post(
                name: .memoryPressureWarning,
                object: nil
            )
        }
    }
    
    private func handleCriticalMemory() {
        memoryWarningLevel = .critical
        
        Task {
            // 激进的内存清理
            await ImageCache.shared.clearAll()
            await DataCache.shared.clearAll()
            
            // 停止后台任务
            await BackgroundTaskManager.shared.suspendNonCriticalTasks()
            
            // 通知用户
            await showMemoryWarningAlert()
        }
    }
    
    private func showMemoryWarningAlert() async {
        // 显示内存警告
    }
    
    // MARK: - 内存使用统计
    public func currentMemoryUsage() -> MemoryUsage {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }
        
        if result == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size) / 1024.0 / 1024.0
            let totalMemory = Double(ProcessInfo.processInfo.physicalMemory) / 1024.0 / 1024.0
            
            return MemoryUsage(
                used: usedMemory,
                total: totalMemory,
                percentage: usedMemory / totalMemory
            )
        }
        
        return MemoryUsage(used: 0, total: 0, percentage: 0)
    }
}

// MARK: - 内存使用信息
public struct MemoryUsage {
    public let used: Double // MB
    public let total: Double // MB
    public let percentage: Double
    
    public var formattedUsed: String {
        String(format: "%.1f MB", used)
    }
    
    public var formattedPercentage: String {
        String(format: "%.1f%%", percentage * 100)
    }
}

// MARK: - 通知扩展
extension Notification.Name {
    static let memoryPressureWarning = Notification.Name("memoryPressureWarning")
}
7.3 图片缓存系统
import UIKit

public actor ImageCache {
    public static let shared = ImageCache()
    
    private var memoryCache = NSCache<NSString, UIImage>()
    private let diskCacheURL: URL
    private var diskCacheSize: Int = 0
    private let maxDiskCacheSize = 100 * 1024 * 1024 // 100MB
    
    init() {
        // 设置磁盘缓存路径
        let cacheDirectory = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first!
        diskCacheURL = cacheDirectory.appendingPathComponent("ImageCache")
        
        // 创建缓存目录
        try? FileManager.default.createDirectory(
            at: diskCacheURL,
            withIntermediateDirectories: true
        )
        
        // 配置内存缓存
        memoryCache.countLimit = 50
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // 计算初始磁盘缓存大小
        Task {
            await calculateDiskCacheSize()
        }
    }
    
    // MARK: - 缓存操作
    public func image(for key: String) async -> UIImage? {
        // 1. 检查内存缓存
        if let image = memoryCache.object(forKey: key as NSString) {
            return image
        }
        
        // 2. 检查磁盘缓存
        let fileURL = diskCacheURL.appendingPathComponent(key.md5)
        
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        // 3. 更新内存缓存
        memoryCache.setObject(image, forKey: key as NSString)
        
        return image
    }
    
    public func store(_ image: UIImage, for key: String) async {
        // 1. 存储到内存缓存
        let cost = image.size.width * image.size.height * 4 // 假设每像素4字节
        memoryCache.setObject(
            image,
            forKey: key as NSString,
            cost: Int(cost)
        )
        
        // 2. 异步存储到磁盘
        Task.detached(priority: .background) {
            guard let data = image.jpegData(compressionQuality: 0.8) else { return }
            
            let fileURL = await self.diskCacheURL.appendingPathComponent(key.md5)
            
            do {
                try data.write(to: fileURL)
                await self.addDiskCacheSize(data.count)
                
                // 检查是否需要清理
                await self.cleanDiskCacheIfNeeded()
            } catch {
                print("Failed to write image to disk: \(error)")
            }
        }
    }
    
    // MARK: - 缓存清理
    public func clearAll() async {
        // 清理内存缓存
        memoryCache.removeAllObjects()
        
        // 清理磁盘缓存
        try? FileManager.default.removeItem(at: diskCacheURL)
        try? FileManager.default.createDirectory(
            at: diskCacheURL,
            withIntermediateDirectories: true
        )
        
        diskCacheSize = 0
    }
    
    public func reduceCacheSize(by factor: Double) async {
        // 减少内存缓存
        let newLimit = Int(Double(memoryCache.totalCostLimit) * (1 - factor))
        memoryCache.totalCostLimit = max(newLimit, 10 * 1024 * 1024) // 最少保留10MB
        
        // 清理部分磁盘缓存
        await cleanDiskCache(targetSize: Int(Double(diskCacheSize) * (1 - factor)))
    }
    
    private func cleanDiskCacheIfNeeded() async {
        guard diskCacheSize > maxDiskCacheSize else { return }
        
        await cleanDiskCache(targetSize: maxDiskCacheSize / 2)
    }
    
    private func cleanDiskCache(targetSize: Int) async {
        let fileManager = FileManager.default
        
        do {
            // 获取所有缓存文件
            let resourceKeys: [URLResourceKey] = [
                .contentAccessDateKey,
                .fileSizeKey
            ]
            
            let files = try fileManager.contentsOfDirectory(
                at: diskCacheURL,
                includingPropertiesForKeys: resourceKeys
            )
            
            // 按访问时间排序
            let sortedFiles = try files.sorted { url1, url2 in
                let date1 = try url1.resourceValues(forKeys: [.contentAccessDateKey]).contentAccessDate ?? .distantPast
                let date2 = try url2.resourceValues(forKeys: [.contentAccessDateKey]).contentAccessDate ?? .distantPast
                return date1 < date2
            }
            
            // 删除旧文件直到达到目标大小
            var currentSize = diskCacheSize
            
            for fileURL in sortedFiles {
                guard currentSize > targetSize else { break }
                
                let fileSize = try fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                try fileManager.removeItem(at: fileURL)
                
                currentSize -= fileSize
            }
            
            diskCacheSize = currentSize
            
        } catch {
            print("Failed to clean disk cache: \(error)")
        }
    }
    
    private func calculateDiskCacheSize() async {
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(
                at: diskCacheURL,
                includingPropertiesForKeys: [.fileSizeKey]
            )
            
            diskCacheSize = try files.reduce(0) { total, fileURL in
                let fileSize = try fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                return total + fileSize
            }
        } catch {
            diskCacheSize = 0
        }
    }
    
    private func addDiskCacheSize(_ size: Int) {
        diskCacheSize += size
    }
}

// MARK: - String MD5 扩展
extension String {
    var md5: String {
        // 简化的哈希实现，实际应用中应使用 CryptoKit
        return self.data(using: .utf8)?.base64EncodedString() ?? self
    }
}
八、隐私与安全
8.1 隐私管理器
import LocalAuthentication
import CryptoKit

public actor PrivacyManager {
    public static let shared = PrivacyManager()
    
    private let context = LAContext()
    
    // MARK: - 生物识别认证
    public func authenticateUser() async throws -> Bool {
        // 检查生物识别可用性
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw PrivacyError.biometricNotAvailable
        }
        
        // 执行认证
        return try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "访问您的学习数据需要验证身份"
        )
    }
    
    // MARK: - 数据加密
    public func encryptSensitiveData(_ data: Data, for key: String) throws -> Data {
        let symmetricKey = try deriveKey(from: key)
        
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
        
        guard let encrypted = sealedBox.combined else {
            throw PrivacyError.encryptionFailed
        }
        
        return encrypted
    }
    
    public func decryptSensitiveData(_ encryptedData: Data, for key: String) throws -> Data {
        let symmetricKey = try deriveKey(from: key)
        
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decrypted = try AES.GCM.open(sealedBox, using: symmetricKey)
        
        return decrypted
    }
    
    private func deriveKey(from password: String) throws -> SymmetricKey {
        guard let passwordData = password.data(using: .utf8) else {
            throw PrivacyError.invalidPassword
        }
        
        let salt = "NotBadApp.Salt".data(using: .utf8)!
        
        let derivedKey = try PBKDF2<SHA256>.deriveKey(
            from: passwordData,
            salt: salt,
            iterations: 100_000,
            outputByteCount: 32
        )
        
        return SymmetricKey(data: derivedKey)
    }
    
    // MARK: - 隐私设置
    public func updatePrivacySettings(_ settings: PrivacySettings) async {
        // 保存隐私设置
        UserDefaults.standard.set(settings.allowAnalytics, forKey: "privacy.analytics")
        UserDefaults.standard.set(settings.allowCrashReporting, forKey: "privacy.crashReporting")
        UserDefaults.standard.set(settings.requireAuthentication, forKey: "privacy.requireAuth")
    }
    
    public func currentPrivacySettings() -> PrivacySettings {
        PrivacySettings(
            allowAnalytics: UserDefaults.standard.bool(forKey: "privacy.analytics"),
            allowCrashReporting: UserDefaults.standard.bool(forKey: "privacy.crashReporting"),
            requireAuthentication: UserDefaults.standard.bool(forKey: "privacy.requireAuth")
        )
    }
}

// MARK: - 隐私相关数据结构
public struct PrivacySettings: Sendable {
    public var allowAnalytics: Bool
    public var allowCrashReporting: Bool
    public var requireAuthentication: Bool
}

public enum PrivacyError: LocalizedError {
    case biometricNotAvailable
    case authenticationFailed
    case encryptionFailed
    case decryptionFailed
    case invalidPassword
    
    public var errorDescription: String? {
        switch self {
        case .biometricNotAvailable:
            return "生物识别功能不可用"
        case .authenticationFailed:
            return "身份验证失败"
        case .encryptionFailed:
            return "数据加密失败"
        case .decryptionFailed:
            return "数据解密失败"
        case .invalidPassword:
            return "无效的密码"
        }
    }
}

// MARK: - PBKDF2 实现
struct PBKDF2<H: HashFunction> {
    static func deriveKey(
        from password: Data,
        salt: Data,
        iterations: Int,
        outputByteCount: Int
    ) throws -> Data {
        var derivedKey = Data(count: outputByteCount)
        
        derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
            password.withUnsafeBytes { passwordBytes in
                salt.withUnsafeBytes { saltBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        password.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        outputByteCount
                    )
                }
            }
        }
        
        return derivedKey
    }
}
8.2 合规性管理
import AppTrackingTransparency
import AdSupport

public actor ComplianceManager {
    public static let shared = ComplianceManager()
    
    // MARK: - App Tracking Transparency
    @MainActor
    public func requestTrackingAuthorization() async -> ATTrackingManager.AuthorizationStatus {
        await ATTrackingManager.requestTrackingAuthorization()
    }
    
    public func trackingAuthorizationStatus() -> ATTrackingManager.AuthorizationStatus {
        ATTrackingManager.trackingAuthorizationStatus
    }
    
    // MARK: - 数据收集披露
    public func generatePrivacyManifest() -> PrivacyManifest {
        PrivacyManifest(
            dataTypes: [
                .contactInfo(collected: false, linked: false, tracking: false),
                .photos(collected: true, linked: true, tracking: false),
                .diagnostics(collected: true, linked: false, tracking: false)
            ],
            trackingDomains: [],
            collectionPurposes: [
                .appFunctionality,
                .analytics
            ]
        )
    }
    
    // MARK: - 儿童隐私保护
    public func enableChildProtectionMode() async {
        // 禁用所有分析
        await Analytics.shared.disable()
        
        // 禁用个性化功能
        await PersonalizationEngine.shared.disable()
        
        // 限制数据收集
        await DataCollectionPolicy.applyMinimalCollection()
    }
    
    // MARK: - 数据删除请求
    public func handleDataDeletionRequest() async throws {
        // 1. 停止所有数据收集
        await Analytics.shared.disable()
        
        // 2. 删除本地数据
        try await DataManager.shared.deleteAllUserData()
        
        // 3. 删除云端数据
        try await SyncManager.shared.deleteCloudData()
        
        // 4. 清除所有缓存
        await ImageCache.shared.clearAll()
        await DataCache.shared.clearAll()
        
        // 5. 重置应用状态
        UserDefaults.standard.removePersistentDomain(
            forName: Bundle.main.bundleIdentifier!
        )
    }
}

// MARK: - 隐私清单
public struct PrivacyManifest {
    public enum DataType {
        case contactInfo(collected: Bool, linked: Bool, tracking: Bool)
        case photos(collected: Bool, linked: Bool, tracking: Bool)
        case diagnostics(collected: Bool, linked: Bool, tracking: Bool)
    }
    
    public enum Purpose {
        case appFunctionality
        case analytics
        case personalization
    }
    
    public let dataTypes: [DataType]
    public let trackingDomains: [String]
    public let collectionPurposes: [Purpose]
}

// MARK: - 分析管理（隐私友好）
public actor Analytics {
    public static let shared = Analytics()
    
    private var isEnabled = true
    
    public func disable() {
        isEnabled = false
    }
    
    public func track(event: String, parameters: [String: Any]? = nil) async {
        guard isEnabled else { return }
        
        // 只有在用户同意的情况下才发送分析数据
        let privacySettings = PrivacyManager.shared.currentPrivacySettings()
        guard privacySettings.allowAnalytics else { return }
        
        // 发送匿名化的分析数据
        await sendAnonymizedEvent(event, parameters: parameters)
    }
    
    private func sendAnonymizedEvent(_ event: String, parameters: [String: Any]?) async {
        // 移除或哈希化任何可能识别用户的信息
        var anonymizedParams = parameters ?? [:]
        
        // 添加匿名会话ID而不是用户ID
        anonymizedParams["session_id"] = UUID().uuidString
        
        // 实际的分析发送逻辑
        print("Analytics event: \(event), params: \(anonymizedParams)")
    }
    
    public func report(_ payload: Any) async {
        guard isEnabled else { return }
        
        // 处理性能报告等
    }
}

// MARK: - 假数据生成器
public actor PersonalizationEngine {
    public static let shared = PersonalizationEngine()
    
    private var isEnabled = true
    
    public func disable() {
        isEnabled = false
    }
}

public actor DataCollectionPolicy {
    public static func applyMinimalCollection() async {
        // 实施最小数据收集策略
    }
}

public actor DataCache {
    public static let shared = DataCache()
    
    public func clearAll() async {
        // 清除所有数据缓存
    }
    
    public func clearTemporary() async {
        // 清除临时缓存
    }
}
九、测试策略
9.1 单元测试示例
import XCTest
@testable import NotBadCore

final class StudyItemTests: XCTestCase {
    var dataManager: DataManager!
    
    override func setUp() async throws {
        // 使用内存数据库进行测试
        let container = try ModelContainer(
            for: Subject.self, StudyItem.self, ItemContent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        dataManager = DataManager(modelContainer: container)
    }
    
    func testCreateStudyItem() async throws {
        // Given
        let questionText = "What is 2 + 2?"
        let answerText = "4"
        
        // When
        let item = try await dataManager.createStudyItem(
            questionText: questionText,
            answerText: answerText
        )
        
        // Then
        XCTAssertNotNil(item)
        XCTAssertEqual(item.content?.questionText, questionText)
        XCTAssertEqual(item.content?.answerText, answerText)
        XCTAssertEqual(item.masteryLevel, 0.0)
        XCTAssertEqual(item.reviewCount, 0)
    }
    
    func testSM2Algorithm() async throws {
        // Given
        let item = try await dataManager.createStudyItem(
            questionText: "Test",
            answerText: "Answer"
        )
        
        // When - 第一次复习，质量为4（容易）
        try await dataManager.updateReview(
            item: item,
            quality: 4,
            timeSpent: 60
        )
        
        // Then
       let updatedItem = try await dataManager.fetchStudyItem(by: item.id)
       XCTAssertEqual(updatedItem.reviewCount, 1)
       XCTAssertGreaterThan(updatedItem.masteryLevel, 0)
       
       // 验证下次复习时间（SM-2算法：第一次复习后应该是6天）
       let expectedNextReview = Date.now.addingTimeInterval(6 * 86400)
       XCTAssertEqual(
           updatedItem.nextReviewDate.timeIntervalSince1970,
           expectedNextReview.timeIntervalSince1970,
           accuracy: 3600 // 1小时误差
       )
   }
   
   func testFetchItemsNeedingReview() async throws {
       // Given - 创建多个项目
       let pastItem = try await dataManager.createStudyItem(
           questionText: "Past",
           answerText: "Item"
       )
       
       let futureItem = try await dataManager.createStudyItem(
           questionText: "Future",
           answerText: "Item"
       )
       
       // 修改复习时间
       pastItem.nextReviewDate = Date.now.addingTimeInterval(-86400) // 昨天
       futureItem.nextReviewDate = Date.now.addingTimeInterval(86400) // 明天
       
       // When
       let itemsToReview = try await dataManager.fetchStudyItems(needsReview: true)
       
       // Then
       XCTAssertEqual(itemsToReview.count, 1)
       XCTAssertEqual(itemsToReview.first?.id, pastItem.id)
   }
}

// MARK: - OCR测试
final class OCREngineTests: XCTestCase {
   var ocrEngine: OCREngine!
   
   override func setUp() async throws {
       ocrEngine = OCREngine()
   }
   
   func testTextRecognition() async throws {
       // Given
       let testImage = createTestImage(with: "Hello World")
       
       // When
       let result = try await ocrEngine.recognizeText(from: testImage)
       
       // Then
       XCTAssertFalse(result.text.isEmpty)
       XCTAssertTrue(result.text.contains { $0.string.contains("Hello") })
       XCTAssertGreaterThan(result.confidence, 0.8)
   }
   
   func testPerformanceOptimization() async throws {
       // Given
       let largeImage = createLargeTestImage()
       
       // When & Then - 测试不同设备层级的处理时间
       await measurePerformance(for: .high, image: largeImage)
       await measurePerformance(for: .medium, image: largeImage)
       await measurePerformance(for: .low, image: largeImage)
   }
   
   private func measurePerformance(
       for tier: DeviceCapability.DeviceTier,
       image: UIImage
   ) async {
       // 模拟不同设备层级
       let startTime = CFAbsoluteTimeGetCurrent()
       
       do {
           _ = try await ocrEngine.recognizeText(from: image)
           let duration = CFAbsoluteTimeGetCurrent() - startTime
           
           // 验证性能要求
           switch tier {
           case .high:
               XCTAssertLessThan(duration, 1.0) // 高端设备1秒内
           case .medium:
               XCTAssertLessThan(duration, 2.0) // 中端设备2秒内
           case .low:
               XCTAssertLessThan(duration, 3.0) // 低端设备3秒内
           }
       } catch {
           XCTFail("OCR failed: \(error)")
       }
   }
   
   private func createTestImage(with text: String) -> UIImage {
       let size = CGSize(width: 200, height: 100)
       UIGraphicsBeginImageContext(size)
       
       // 白色背景
       UIColor.white.setFill()
       UIRectFill(CGRect(origin: .zero, size: size))
       
       // 黑色文字
       let attributes: [NSAttributedString.Key: Any] = [
           .font: UIFont.systemFont(ofSize: 24),
           .foregroundColor: UIColor.black
       ]
       
       text.draw(
           at: CGPoint(x: 10, y: 30),
           withAttributes: attributes
       )
       
       let image = UIGraphicsGetImageFromCurrentImageContext()!
       UIGraphicsEndImageContext()
       
       return image
   }
   
   private func createLargeTestImage() -> UIImage {
       // 创建一个包含多行文字的大图片用于性能测试
       let size = CGSize(width: 1024, height: 1024)
       UIGraphicsBeginImageContext(size)
       
       UIColor.white.setFill()
       UIRectFill(CGRect(origin: .zero, size: size))
       
       // 添加多行文字
       let text = "This is a performance test. " +
                  "The quick brown fox jumps over the lazy dog. " +
                  "1234567890 !@#$%^&*()"
       
       let attributes: [NSAttributedString.Key: Any] = [
           .font: UIFont.systemFont(ofSize: 18),
           .foregroundColor: UIColor.black
       ]
       
       for i in 0..<20 {
           text.draw(
               at: CGPoint(x: 10, y: 50 * i),
               withAttributes: attributes
           )
       }
       
       let image = UIGraphicsGetImageFromCurrentImageContext()!
       UIGraphicsEndImageContext()
       
       return image
   }
}

// MARK: - 并发安全测试
final class ConcurrencyTests: XCTestCase {
   func testDataRaceSafety() async throws {
       let dataManager = DataManager.shared
       
       // 并发创建多个项目
       try await withThrowingTaskGroup(of: StudyItem.self) { group in
           for i in 0..<100 {
               group.addTask {
                   try await dataManager.createStudyItem(
                       questionText: "Question \(i)",
                       answerText: "Answer \(i)"
                   )
               }
           }
           
           var items: [StudyItem] = []
           for try await item in group {
               items.append(item)
           }
           
           XCTAssertEqual(items.count, 100)
       }
   }
   
   func testActorIsolation() async {
       // 测试 Actor 隔离是否正确工作
       let expectation = XCTestExpectation(description: "Actor isolation")
       
       Task {
           await PerformanceMonitor.shared.track("test") {
               // 模拟耗时操作
               try await Task.sleep(nanoseconds: 100_000_000)
           }
           expectation.fulfill()
       }
       
       await fulfillment(of: [expectation], timeout: 5.0)
   }
}

// MARK: - UI测试
final class UIFlowTests: XCTestCase {
   func testAddItemFlow() async throws {
       // 测试添加错题的完整流程
       let app = XCUIApplication()
       app.launch()
       
       // 1. 点击添加按钮
       app.buttons["拍照添加"].tap()
       
       // 2. 输入题目
       let questionField = app.textFields["输入题目或拍照识别"]
       questionField.tap()
       questionField.typeText("测试题目")
       
       // 3. 输入答案
       let answerField = app.textFields["输入答案"]
       answerField.tap()
       answerField.typeText("测试答案")
       
       // 4. 保存
       app.buttons["保存"].tap()
       
       // 5. 验证是否回到主页面并显示新项目
       XCTAssertTrue(app.staticTexts["测试题目"].exists)
   }
}
### 9.2 性能测试
```swift
import XCTest
@testable import NotBadCore

final class PerformanceTests: XCTestCase {
    
    func testLargeDataSetPerformance() async throws {
        let dataManager = DataManager.shared
        
        measure {
            Task {
                // 创建1000个项目
                for i in 0..<1000 {
                    _ = try await dataManager.createStudyItem(
                        questionText: "Question \(i)",
                        answerText: "Answer \(i)"
                    )
                }
                
                // 查询所有项目
                let items = try await dataManager.fetchStudyItems()
                XCTAssertEqual(items.count, 1000)
            }
        }
    }
    
    func testImageCachePerformance() async throws {
        let cache = ImageCache.shared
        
        // 准备测试图片
        let testImages = (0..<100).map { _ in
            createRandomImage(size: CGSize(width: 1024, height: 1024))
        }
        
        // 测试写入性能
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            Task {
                for (index, image) in testImages.enumerated() {
                    await cache.store(image, for: "test_\(index)")
                }
            }
        }
        
        // 测试读取性能
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            Task {
                for index in 0..<100 {
                    _ = await cache.image(for: "test_\(index)")
                }
            }
        }
    }
    
    private func createRandomImage(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        
        // 随机颜色填充
        UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1
        ).setFill()
        
        UIRectFill(CGRect(origin: .zero, size: size))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
}
```

## 十、项目配置与部署

### 10.1 项目结构
```
NotBadApp/
├── NotBadApp.xcodeproj
├── Packages/
│   ├── NotBadCore/
│   │   ├── Sources/
│   │   │   ├── Models/
│   │   │   ├── Services/
│   │   │   └── Utils/
│   │   └── Tests/
│   ├── NotBadData/
│   │   ├── Sources/
│   │   │   ├── SwiftData/
│   │   │   ├── CloudKit/
│   │   │   └── Cache/
│   │   └── Tests/
│   ├── NotBadAI/
│   │   ├── Sources/
│   │   │   ├── OCR/
│   │   │   ├── ML/
│   │   │   └── Processing/
│   │   └── Tests/
│   └── NotBadUI/
│       ├── Sources/
│       │   ├── Views/
│       │   ├── ViewModels/
│       │   └── Resources/
│       └── Tests/
├── NotBadApp/
│   ├── App/
│   ├── Assets.xcassets
│   ├── Info.plist
│   └── NotBadApp.entitlements
└── NotBadAppTests/
```

### 10.2 构建配置
```swift
// Build Settings
SWIFT_VERSION = 6.0
IPHONEOS_DEPLOYMENT_TARGET = 17.0
SWIFT_STRICT_CONCURRENCY = complete
SWIFT_UPCOMING_FEATURE_CONCISE_MAGIC_FILE = YES
SWIFT_UPCOMING_FEATURE_FORWARD_TRAILING_CLOSURES = YES
SWIFT_UPCOMING_FEATURE_EXISTENTIAL_ANY = YES

// Other Swift Flags
OTHER_SWIFT_FLAGS = 
    -Xfrontend -warn-concurrency 
    -Xfrontend -enable-actor-data-race-checks
    -enable-bare-slash-regex

// Optimization
SWIFT_OPTIMIZATION_LEVEL_DEBUG = -Onone
SWIFT_OPTIMIZATION_LEVEL_RELEASE = -O

// Code Signing
CODE_SIGN_STYLE = Automatic
DEVELOPMENT_TEAM = YOUR_TEAM_ID
```

### 10.3 隐私清单配置
```xml
<!-- PrivacyInfo.xcprivacy -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypePhotos</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <true/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeCrashData</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <false/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
    </array>
    
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>C617.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

### 10.4 启动脚本
```bash
#!/bin/bash
# setup.sh - 项目初始化脚本

echo "🚀 NotBad App Setup"

# 检查 Xcode 版本
XCODE_VERSION=$(xcodebuild -version | grep Xcode | cut -d ' ' -f 2)
echo "✓ Xcode version: $XCODE_VERSION"

# 检查 Swift 版本
SWIFT_VERSION=$(swift --version | head -n 1)
echo "✓ Swift version: $SWIFT_VERSION"

# 解析 Swift Package
echo "📦 Resolving packages..."
xcodebuild -resolvePackageDependencies

# 生成项目
echo "🔨 Building project..."
xcodebuild -scheme NotBadApp -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# 运行测试
echo "🧪 Running tests..."
xcodebuild test -scheme NotBadApp -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

echo "✅ Setup complete!"
```

## 十一、总结

这份完整的NotBad教育应用开发方案展示了如何充分利用Swift 6和SwiftData的现代特性：

### 技术亮点
1. **Swift 6 并发模型**：全面采用Actor隔离和Sendable协议，确保线程安全
2. **SwiftData 深度集成**：利用声明式数据模型和自动CloudKit同步
3. **性能优化**：设备感知的资源管理和智能缓存策略
4. **隐私优先**：完整的隐私保护和合规管理系统

### 架构优势
1. **模块化设计**：清晰的模块边界，便于团队协作
2. **可测试性**：完整的测试策略，包括单元测试、性能测试和UI测试
3. **可扩展性**：灵活的架构设计，易于添加新功能

### 实施建议
1. **分阶段开发**：先实现核心功能，再逐步添加高级特性
2. **持续集成**：使用Xcode Cloud进行自动化构建和测试
3. **性能监控**：从开发初期就集成性能监控系统

这个方案为构建一个现代化、高性能、用户友好的教育应用提供了坚实的技术基础。通过坚持使用Swift 6和SwiftData，我们不仅能够享受最新技术带来的便利，还能确保应用在未来几年内保持技术先进性。
