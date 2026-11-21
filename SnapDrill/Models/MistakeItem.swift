import Foundation
import SwiftData

/// Field caps specified in PRD §8.6.
enum MistakeLimits {
    static let maxPhotosPerSession = 10
    static let maxBoxesPerPage = 10
    static let maxNotesCharacters = 1_000
    static let maxAnswerCharacters = 2_000
    static let maxAnswerImages = 3
    static let maxTagsPerMistake = 10
}

/// Built-in error cause classifications (PRD F-21).
enum MistakeCause: String, Codable, CaseIterable, Identifiable, Sendable {
    case careless
    case conceptUnclear
    case methodUnknown
    case calculationError
    case misreadQuestion
    case other

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .careless: return String(localized: "Careless")
        case .conceptUnclear: return String(localized: "Concept Unclear")
        case .methodUnknown: return String(localized: "Method Unknown")
        case .calculationError: return String(localized: "Calculation Error")
        case .misreadQuestion: return String(localized: "Misread Question")
        case .other: return String(localized: "Other")
        }
    }
}

/// Mastery progression state updated during review sessions (PRD F-26, F-41).
enum MasteryLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    case unknown
    case fuzzy
    case mastered

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .unknown: return String(localized: "Not Yet")
        case .fuzzy: return String(localized: "Fuzzy")
        case .mastered: return String(localized: "Mastered")
        }
    }

    var symbolName: String {
        switch self {
        case .unknown: return "circle.dotted"
        case .fuzzy: return "circle.lefthalf.filled"
        case .mastered: return "checkmark.circle.fill"
        }
    }
}

/// Persisted mistake record storing dual-version relative paths and metadata.
@Model
final class MistakeItem {
    var id: UUID
    var createdAt: Date
    var sourceTitle: String
    var notes: String
    var answerText: String
    var answerImagePaths: [String]
    var causesRaw: [String]
    var customCauseNames: [String]
    var masteryRaw: String
    var ocrText: String

    /// Relative path inside Documents/SnapDrillImages for the original cropped problem.
    var originalImagePath: String?
    /// Relative path inside Documents/SnapDrillImages for the handwriting-removed (or enhanced fallback) image.
    var cleanedImagePath: String?
    var handwritingRemovalSucceeded: Bool

    var reviewCount: Int
    var lastReviewedAt: Date?

    var subject: Subject?
    var tags: [MistakeTag] = []

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        sourceTitle: String = "",
        notes: String = "",
        answerText: String = "",
        answerImagePaths: [String] = [],
        causes: [MistakeCause] = [],
        customCauseNames: [String] = [],
        mastery: MasteryLevel = .unknown,
        ocrText: String = "",
        originalImagePath: String? = nil,
        cleanedImagePath: String? = nil,
        handwritingRemovalSucceeded: Bool = false,
        reviewCount: Int = 0,
        lastReviewedAt: Date? = nil,
        subject: Subject? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.sourceTitle = sourceTitle
        self.notes = String(notes.prefix(MistakeLimits.maxNotesCharacters))
        self.answerText = String(answerText.prefix(MistakeLimits.maxAnswerCharacters))
        self.answerImagePaths = Array(answerImagePaths.prefix(MistakeLimits.maxAnswerImages))
        self.causesRaw = causes.map(\.rawValue)
        self.customCauseNames = customCauseNames
        self.masteryRaw = mastery.rawValue
        self.ocrText = ocrText
        self.originalImagePath = originalImagePath
        self.cleanedImagePath = cleanedImagePath
        self.handwritingRemovalSucceeded = handwritingRemovalSucceeded
        self.reviewCount = reviewCount
        self.lastReviewedAt = lastReviewedAt
        self.subject = subject
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
