import Foundation
import SwiftData

enum MistakeCause: String, Codable, CaseIterable, Identifiable {
    case careless
    case conceptUnclear
    case methodUnknown
    case calculationError
    case misreadQuestion
    case other

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .careless: String(localized: "Careless")
        case .conceptUnclear: String(localized: "Concept unclear")
        case .methodUnknown: String(localized: "Don’t know the method")
        case .calculationError: String(localized: "Calculation error")
        case .misreadQuestion: String(localized: "Misread question")
        case .other: String(localized: "Other")
        }
    }
}

enum MasteryLevel: String, Codable, CaseIterable {
    case unknown
    case fuzzy
    case mastered
}

@Model
final class MistakeItem {
    var id: UUID
    var createdAt: Date
    var notes: String
    var answerText: String
    var causesRaw: [String]
    var masteryRaw: String
    /// 相对 Documents 的路径，原图
    var originalImagePath: String?
    /// 去手写图；失败时与增强原图相同（PRD §8.6）
    var cleanedImagePath: String?
    var handwritingRemovalSucceeded: Bool
    /// `UIDemoDataService` 注入的样例，可一键清除。
    var isDemoSample: Bool

    var subject: Subject?

    @Relationship(deleteRule: .nullify)
    var tags: [MistakeTag]

    init(subject: Subject?) {
        self.id = UUID()
        self.createdAt = .now
        self.notes = ""
        self.answerText = ""
        self.causesRaw = []
        self.masteryRaw = MasteryLevel.unknown.rawValue
        self.handwritingRemovalSucceeded = false
        self.isDemoSample = false
        self.subject = subject
        self.tags = []
    }

    var causes: [MistakeCause] {
        get { causesRaw.compactMap { MistakeCause(rawValue: $0) } }
        set { causesRaw = newValue.map(\.rawValue) }
    }

    var mastery: MasteryLevel {
        get { MasteryLevel(rawValue: masteryRaw) ?? .unknown }
        set { masteryRaw = newValue.rawValue }
    }
}