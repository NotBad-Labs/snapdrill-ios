//
//  ModuleProtocols.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/9/5.
//
// MARK: - Domain Layer Protocols (核心业务协议)

import Foundation

// MARK: - 核心实体协议
protocol ReviewItemProtocol {
    var id: UUID { get }
    var content: ReviewContentProtocol { get set }
    var metadata: ReviewItemMetadataProtocol { get set }
    var studyHistory: [StudyRecordProtocol] { get set }
    var masteryLevel: MasteryLevel { get set }
}

protocol ReviewContentProtocol {
    var text: String? { get set }
    var imageData: Data? { get set }
    var subject: Subject { get set }
    var knowledgePoints: [String] { get set }
}

protocol ReviewItemMetadataProtocol {
    var ownerId: UUID { get set }
    var createdAt: Date { get set }
    var updatedAt: Date { get set }
    var parentShareStatus: ParentShareStatus { get set }
    var parentAccessRevokedAt: Date? { get set }
    var sharedWithClassIds: [UUID] { get set }
}

protocol StudyRecordProtocol {
    var id: UUID { get }
    var reviewItemId: UUID { get }
    var studiedAt: Date { get }
    var duration: TimeInterval { get }
    var result: StudyResult { get }
}

// MARK: - 枚举类型定义
enum MasteryLevel: String, CaseIterable {
    case notMastered = "not_mastered"
    case unclear = "unclear"
    case mastered = "mastered"
}

enum Subject: String, CaseIterable {
    case math = "math"
    case chinese = "chinese"
    case english = "english"
    case physics = "physics"
    case chemistry = "chemistry"
    case biology = "biology"
}

enum ParentShareStatus: String {
    case none = "none"
    case summary = "summary"
    case oneTime = "one_time"
    case itemLevel = "item_level"
}

enum StudyResult: String {
    case correct = "correct"
    case incorrect = "incorrect"
    case partial = "partial"
    case skipped = "skipped"
}

// MARK: - Repository 协议（数据访问层）
@MainActor
protocol ReviewItemRepositoryProtocol {
    func create(_ item: ReviewItemProtocol) async throws
    func findById(_ id: UUID) async throws -> ReviewItemProtocol?
    func findAll() async throws -> [ReviewItemProtocol]
    func update(_ item: ReviewItemProtocol) async throws
    func delete(_ id: UUID) async throws
    func findBySubject(_ subject: Subject) async throws -> [ReviewItemProtocol]
    func findByMasteryLevel(_ level: MasteryLevel) async throws -> [ReviewItemProtocol]
}

// MARK: - Service 协议（业务服务层）
@MainActor
protocol OCRServiceProtocol {
    func recognizeText(from image: Data) async throws -> OCRResult
    func reprocess(image: Data) async throws -> [OCRResult] // 支持多个候选结果
}

struct OCRResult {
    let text: String
    let confidence: Double
    let boundingBoxes: [CGRect]
}

enum OCRError: Error {
    case invalidImage
    case lowConfidence(confidence: Double)
    case processingFailed
}

@MainActor
protocol AIAnalysisServiceProtocol {
    func analyzeAndClassify(_ content: String) async throws -> AIAnalysisResult
    func generateDiagnosisReport(for items: [ReviewItemProtocol]) async throws -> DiagnosisReport
}

struct AIAnalysisResult {
    let subject: Subject
    let knowledgePoints: [String]
    let difficulty: Double
    let confidence: Double
}

struct DiagnosisReport {
    let weaknessAreas: [String]
    let recommendations: [String]
    let masteryProgress: [Subject: Double]
}

@MainActor
protocol SyncServiceProtocol {
    func syncToCloud() async throws
    func syncFromCloud() async throws
    func handleConflict(_ conflict: SyncConflict) async throws
}

struct SyncConflict {
    let localItem: ReviewItemProtocol
    let cloudItem: ReviewItemProtocol
    let conflictType: ConflictType
}

enum ConflictType {
    case lastWriteWins
    case userChoice
}

@MainActor
protocol ParentAccessServiceProtocol {
    func requestAccess(itemId: UUID, parentId: UUID) async throws
    func approveAccess(itemId: UUID, parentId: UUID) async throws
    func revokeAccess(itemId: UUID, parentId: UUID) async throws
    func getAccessLog(itemId: UUID) async throws -> [AccessRecord]
}

struct AccessRecord {
    let id: UUID
    let itemId: UUID
    let parentId: UUID
    let action: AccessAction
    let timestamp: Date
}

enum AccessAction: String {
    case requested = "requested"
    case approved = "approved"
    case revoked = "revoked"
    case viewed = "viewed"
}

@MainActor
protocol ClassManagementServiceProtocol {
    func createClass(name: String, teacherId: UUID) async throws -> UUID
    func generateInviteCode(classId: UUID) async throws -> String
    func assignHomework(classId: UUID, items: [UUID], dueDate: Date) async throws -> UUID
    func getAnonymizedStats(classId: UUID) async throws -> ClassStats
}

struct ClassStats {
    let totalStudents: Int
    let avgMasteryRate: Double
    let weaknessDistribution: [String: Int] // 知识点 -> 错误次数
    let completionRate: Double
}

// MARK: - Use Case 协议（应用层）
@MainActor
protocol CreateReviewItemUseCaseProtocol {
    func execute(image: Data?, text: String?, subject: Subject?) async throws -> ReviewItemProtocol
}

@MainActor
protocol StudySessionUseCaseProtocol {
    func startSession(items: [ReviewItemProtocol]) async throws -> UUID
    func completeItem(sessionId: UUID, itemId: UUID, result: StudyResult) async throws
    func endSession(sessionId: UUID) async throws -> StudySessionSummary
}

struct StudySessionSummary {
    let sessionId: UUID
    let totalItems: Int
    let correctItems: Int
    let duration: TimeInterval
    let masteryImprovement: [UUID: MasteryLevel] // itemId -> new mastery level
}

// MARK: - 指标计算协议
@MainActor
protocol MetricsCalculatorProtocol {
    func calculateMARU(for period: DateRange) async throws -> Int // L1 月度活跃录入用户
    func calculateMRU(for period: DateRange) async throws -> Int  // L2 月度重复用户
    func calculateMMU(for period: DateRange) async throws -> Int  // L3 月度掌握用户
}

struct DateRange {
    let start: Date
    let end: Date
}

// MARK: - 分析事件协议
protocol AnalyticsServiceProtocol {
    func track(_ event: AnalyticsEvent) async
    func flush() async // 批量上传事件
}

enum AnalyticsEvent {
    case reviewItemCreated(itemId: UUID, creationMethod: String, subject: String, hasImage: Bool)
    case studySessionCompleted(sessionId: UUID, duration: TimeInterval, itemsCompleted: Int)
    case itemMarkedMastered(itemId: UUID, masterySource: String)
    case reviewItemEdited(itemId: UUID, fieldsChanged: [String])
    case parentViewRequest(itemId: UUID, parentId: UUID)
    case parentAccessRevoked(itemId: UUID, parentId: UUID)
    case teacherClassCreated(classId: UUID, teacherId: UUID)
}
