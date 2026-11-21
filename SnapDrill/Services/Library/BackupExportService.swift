import Foundation
import SwiftData

/// Portable backup export manifest for full user data ownership (PRD F-54, free tier).
struct BackupManifest: Codable, Sendable {
    let exportedAt: Date
    let appVersion: String
    let subjects: [BackupSubject]
    let tags: [String]
    let customCauses: [String]
    let mistakes: [BackupMistake]

    struct BackupSubject: Codable, Sendable {
        let id: UUID
        let name: String
        let colorHex: String
        let sortOrder: Int
        let isUncategorizedBucket: Bool
    }

    struct BackupMistake: Codable, Sendable {
        let id: UUID
        let createdAt: Date
        let subjectID: UUID?
        let subjectName: String?
        let sourceTitle: String
        let notes: String
        let answerText: String
        let causes: [String]
        let customCauseNames: [String]
        let tagNames: [String]
        let mastery: String
        let ocrText: String
        let originalImagePath: String?
        let cleanedImagePath: String?
        let answerImagePaths: [String]
    }
}

/// Exports the full SnapDrill library (manifest.json + original/cleaned/answer images) into a portable .zip archive.
enum BackupExportService {
    @MainActor
    static func createBackupArchive(
        in context: ModelContext,
        imageStore: MistakeImageStore = MistakeImageStore(),
        outputDirectory: URL? = nil
    ) throws -> URL {
        let subjects = (try? context.fetch(FetchDescriptor<Subject>(sortBy: [SortDescriptor(\Subject.sortOrder)]))) ?? []
        let tags = (try? context.fetch(FetchDescriptor<MistakeTag>(sortBy: [SortDescriptor(\MistakeTag.name)]))) ?? []
        let customCauses = (try? context.fetch(FetchDescriptor<CustomCause>(sortBy: [SortDescriptor(\CustomCause.sortOrder)]))) ?? []
        let mistakes = (try? context.fetch(FetchDescriptor<MistakeItem>(sortBy: [SortDescriptor(\MistakeItem.createdAt, order: .reverse)]))) ?? []

        let manifest = BackupManifest(
            exportedAt: .now,
            appVersion: "1.0.0",
            subjects: subjects.map {
                BackupManifest.BackupSubject(
                    id: $0.id,
                    name: $0.name,
                    colorHex: $0.colorHex,
                    sortOrder: $0.sortOrder,
                    isUncategorizedBucket: $0.isUncategorizedBucket
                )
            },
            tags: tags.map(\.name),
            customCauses: customCauses.map(\.name),
            mistakes: mistakes.map {
                BackupManifest.BackupMistake(
                    id: $0.id,
                    createdAt: $0.createdAt,
                    subjectID: $0.subject?.id,
                    subjectName: $0.subject?.name,
                    sourceTitle: $0.sourceTitle,
                    notes: $0.notes,
                    answerText: $0.answerText,
                    causes: $0.causesRaw,
                    customCauseNames: $0.customCauseNames,
                    tagNames: $0.tags.map(\.name),
                    mastery: $0.masteryRaw,
                    ocrText: $0.ocrText,
                    originalImagePath: $0.originalImagePath,
                    cleanedImagePath: $0.cleanedImagePath,
                    answerImagePaths: $0.answerImagePaths
                )
            }
        )

        let fm = FileManager.default
        let stagingDir = fm.temporaryDirectory.appendingPathComponent("SnapDrill-Backup-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: stagingDir, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: stagingDir) }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let manifestData = try encoder.encode(manifest)
        try manifestData.write(to: stagingDir.appendingPathComponent("manifest.json"), options: [.atomic])

        let imagesDest = stagingDir.appendingPathComponent("images", isDirectory: true)
        if fm.fileExists(atPath: imageStore.rootDirectory.path) {
            try fm.copyItem(at: imageStore.rootDirectory, to: imagesDest)
        } else {
            try fm.createDirectory(at: imagesDest, withIntermediateDirectories: true)
        }

        let targetDir = outputDirectory ?? fm.temporaryDirectory
        try fm.createDirectory(at: targetDir, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let zipURL = targetDir.appendingPathComponent("SnapDrill-Backup-\(formatter.string(from: .now)).zip")
        if fm.fileExists(atPath: zipURL.path) {
            try fm.removeItem(at: zipURL)
        }

        var coordinatorError: NSError?
        var copyError: Error?
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(readingItemAt: stagingDir, options: .forUploading, error: &coordinatorError) { zippedURL in
            do {
                try fm.copyItem(at: zippedURL, to: zipURL)
            } catch {
                copyError = error
            }
        }

        if let coordinatorError { throw coordinatorError }
        if let copyError { throw copyError }
        return zipURL
    }
}
