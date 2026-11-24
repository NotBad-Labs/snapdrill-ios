import CoreGraphics
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

/// CloudKit-compatible persisted mistake record storing both local file paths and @Attribute(.externalStorage) assets.
@Model
final class MistakeItem {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var sourceTitle: String = ""
    var notes: String = ""
    var answerText: String = ""
    var answerImagePaths: [String] = []
    var causesRaw: [String] = []
    var customCauseNames: [String] = []
    var masteryRaw: String = MasteryLevel.unknown.rawValue
    var ocrText: String = ""

    /// Relative paths inside Documents/SnapDrillImages for local fast I/O.
    var originalImagePath: String? = nil
    var cleanedImagePath: String? = nil
    var pageImagePath: String? = nil
    var cropRectNormalizedData: Data? = nil
    var handwritingRemovalSucceeded: Bool = false

    /// CloudKit CKAsset-backed binary replicas enabling cross-device image sync (AC-08).
    @Attribute(.externalStorage) var originalImageData: Data? = nil
    @Attribute(.externalStorage) var cleanedImageData: Data? = nil
    @Attribute(.externalStorage) var pageImageData: Data? = nil
    @Attribute(.externalStorage) var answerImageData0: Data? = nil
    @Attribute(.externalStorage) var answerImageData1: Data? = nil
    @Attribute(.externalStorage) var answerImageData2: Data? = nil

    var reviewCount: Int = 0
    var lastReviewedAt: Date? = nil

    var subject: Subject? = nil
    var tags: [MistakeTag]? = []

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
        pageImagePath: String? = nil,
        cropRectNormalized: CGRect? = nil,
        handwritingRemovalSucceeded: Bool = false,
        originalImageData: Data? = nil,
        cleanedImageData: Data? = nil,
        pageImageData: Data? = nil,
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
        self.pageImagePath = pageImagePath
        self.cropRectNormalizedData = Self.encodeRect(cropRectNormalized)
        self.handwritingRemovalSucceeded = handwritingRemovalSucceeded
        self.originalImageData = originalImageData
        self.cleanedImageData = cleanedImageData
        self.pageImageData = pageImageData
        self.reviewCount = reviewCount
        self.lastReviewedAt = lastReviewedAt
        self.subject = subject
    }

    var tagList: [MistakeTag] {
        get { tags ?? [] }
        set { tags = newValue }
    }

    var causes: [MistakeCause] {
        get { causesRaw.compactMap { MistakeCause(rawValue: $0) } }
        set { causesRaw = newValue.map(\.rawValue) }
    }

    var mastery: MasteryLevel {
        get { MasteryLevel(rawValue: masteryRaw) ?? .unknown }
        set { masteryRaw = newValue.rawValue }
    }

    var cropRectNormalized: CGRect? {
        get { Self.decodeRect(cropRectNormalizedData) }
        set { cropRectNormalizedData = Self.encodeRect(newValue) }
    }

    var syncedAnswerImageDatas: [Data] {
        [answerImageData0, answerImageData1, answerImageData2].compactMap { $0 }
    }

    func answerImageSlotData(at index: Int) -> Data? {
        switch index {
        case 0: return answerImageData0
        case 1: return answerImageData1
        case 2: return answerImageData2
        default: return nil
        }
    }

    func setAnswerImageSlots(_ slots: [Data?]) {
        let capped = Array(slots.prefix(MistakeLimits.maxAnswerImages))
        answerImageData0 = capped.indices.contains(0) ? capped[0] : nil
        answerImageData1 = capped.indices.contains(1) ? capped[1] : nil
        answerImageData2 = capped.indices.contains(2) ? capped[2] : nil
    }

    func setSyncedAnswerImageDatas(_ datas: [Data]) {
        setAnswerImageSlots(datas.map { Optional($0) })
    }

    func resolvedOriginalImageData(imageStore: MistakeImageStore) -> Data? {
        Self.resolveData(relativePath: originalImagePath, externalData: originalImageData, imageStore: imageStore)
    }

    func resolvedCleanedImageData(imageStore: MistakeImageStore) -> Data? {
        if let cleaned = Self.resolveData(relativePath: cleanedImagePath, externalData: cleanedImageData, imageStore: imageStore) {
            return cleaned
        }
        return resolvedOriginalImageData(imageStore: imageStore)
    }

    /// Strict full-page source resolver; NEVER falls back to cropped problem image (prevents double-cropping, M2).
    func strictPageImageData(imageStore: MistakeImageStore) -> Data? {
        Self.resolveData(relativePath: pageImagePath, externalData: pageImageData, imageStore: imageStore)
    }

    func resolvedPageImageData(imageStore: MistakeImageStore) -> Data? {
        strictPageImageData(imageStore: imageStore)
    }

    func resolvedAnswerImageData(at index: Int, imageStore: MistakeImageStore) -> Data? {
        guard index >= 0, index < MistakeLimits.maxAnswerImages else { return nil }
        let relPath = answerImagePaths.indices.contains(index) ? answerImagePaths[index] : nil
        let ext = answerImageSlotData(at: index)
        return Self.resolveData(relativePath: relPath, externalData: ext, imageStore: imageStore)
    }

    func resolvedAnswerImageDatas(imageStore: MistakeImageStore) -> [Data] {
        let externalSlots: [Data?] = [answerImageData0, answerImageData1, answerImageData2]
        let count = max(answerImagePaths.count, externalSlots.compactMap { $0 }.count)
        guard count > 0 else { return [] }

        var result: [Data] = []
        for idx in 0..<min(MistakeLimits.maxAnswerImages, count) {
            if let data = resolvedAnswerImageData(at: idx, imageStore: imageStore) {
                result.append(data)
            }
        }
        return result
    }

    private static func resolveData(
        relativePath: String?,
        externalData: Data?,
        imageStore: MistakeImageStore
    ) -> Data? {
        if let local = imageStore.loadData(relativePath: relativePath) {
            return local
        }
        if let externalData, !externalData.isEmpty {
            if let relativePath, !relativePath.isEmpty {
                try? imageStore.cacheRawDataIfMissing(externalData, relativePath: relativePath)
            }
            return externalData
        }
        return nil
    }

    private static func encodeRect(_ rect: CGRect?) -> Data? {
        guard let rect else { return nil }
        let coords = [Double(rect.origin.x), Double(rect.origin.y), Double(rect.size.width), Double(rect.size.height)]
        return try? JSONEncoder().encode(coords)
    }

    private static func decodeRect(_ data: Data?) -> CGRect? {
        guard let data,
              let coords = try? JSONDecoder().decode([Double].self, from: data),
              coords.count == 4 else {
            return nil
        }
        return CGRect(x: coords[0], y: coords[1], width: coords[2], height: coords[3])
    }
}
