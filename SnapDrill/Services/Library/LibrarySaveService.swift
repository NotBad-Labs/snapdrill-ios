import Foundation
import SwiftData
import UIKit

/// Strategy when deleting a Subject that already owns mistakes (PRD §8.6, AC-09).
enum SubjectDeletionStrategy: Sendable {
    case moveToUncategorized
    case deleteWithMistakes
}

/// Coordinates atomic persistence of mistakes, image files, re-cropping, and safe deletions.
@MainActor
final class LibrarySaveService {
    private let imageStore: MistakeImageStore
    private let inkRemover: InkRemoving

    init(
        imageStore: MistakeImageStore = MistakeImageStore(),
        inkRemover: InkRemoving = CoreMLCapableInkRemover()
    ) {
        self.imageStore = imageStore
        self.inkRemover = inkRemover
    }

    /// Saves N cropped preview items atomically into SwiftData and disk; rolls back files on failure (AC-03, AC-09).
    @discardableResult
    func commitSave(
        preview: CaptureSavePreview,
        subject: Subject,
        in context: ModelContext
    ) throws -> [MistakeItem] {
        var writtenRelativePaths: [String] = []
        var insertedItems: [MistakeItem] = []

        do {
            for item in preview.items {
                let itemID = UUID()
                let origRelPath = try imageStore.saveJPEG(
                    item.originalImageData,
                    relativePath: "orig/\(itemID.uuidString).jpg"
                )
                writtenRelativePaths.append(origRelPath)

                let cleanRelPath = try imageStore.saveJPEG(
                    item.cleanedImageData,
                    relativePath: "clean/\(itemID.uuidString).jpg"
                )
                writtenRelativePaths.append(cleanRelPath)

                let resolvedTags = resolveOrCreateTags(named: item.tagNames, in: context)

                let mistake = MistakeItem(
                    id: itemID,
                    createdAt: .now,
                    sourceTitle: item.sourceTitle,
                    notes: item.notes,
                    answerText: item.answerText,
                    causes: item.causes,
                    customCauseNames: item.customCauseNames,
                    mastery: .unknown,
                    ocrText: item.ocrText,
                    originalImagePath: origRelPath,
                    cleanedImagePath: cleanRelPath,
                    handwritingRemovalSucceeded: item.handwritingRemovalSucceeded,
                    subject: subject
                )
                mistake.tags = Array(resolvedTags.prefix(MistakeLimits.maxTagsPerMistake))
                context.insert(mistake)
                insertedItems.append(mistake)
            }

            try context.save()
            return insertedItems
        } catch {
            // Roll back any inserted SwiftData models & disk images to avoid half-written corrupted records
            for item in insertedItems {
                context.delete(item)
            }
            for relPath in writtenRelativePaths {
                imageStore.deleteFile(relativePath: relPath)
            }
            throw error
        }
    }

    /// Re-crops an existing mistake's image and regenerates both original and handwriting-removed images (PRD §8.3, AC-05).
    func recropMistake(
        _ mistake: MistakeItem,
        normalizedRect: CGRect,
        mode: InkRemovalMode,
        in context: ModelContext
    ) async throws {
        guard let sourceData = imageStore.loadData(relativePath: mistake.originalImagePath),
              let sourceImage = UIImage(data: sourceData),
              let cgImage = sourceImage.cgImage else {
            return
        }

        let w = CGFloat(cgImage.width)
        let h = CGFloat(cgImage.height)
        let clamped = normalizedRect.clampedToUnitSquare()
        let pixelRect = CGRect(
            x: (clamped.origin.x * w).rounded(.down),
            y: (clamped.origin.y * h).rounded(.down),
            width: max(16, (clamped.width * w).rounded(.down)),
            height: max(16, (clamped.height * h).rounded(.down))
        ).intersection(CGRect(x: 0, y: 0, width: w, height: h))

        guard !pixelRect.isNull,
              let croppedCG = cgImage.cropping(to: pixelRect),
              let croppedData = UIImage(cgImage: croppedCG).jpegData(compressionQuality: 0.88) else {
            return
        }

        let (cleanedData, succeeded) = await inkRemover.removeInk(from: croppedData, mode: mode)
        let ocrText = await OCRIndexingService.recognizeText(in: cleanedData)

        let suffix = UUID().uuidString.prefix(8)
        let newOrigRel = try imageStore.saveJPEG(croppedData, relativePath: "orig/\(mistake.id.uuidString)-\(suffix).jpg")
        let newCleanRel = try imageStore.saveJPEG(cleanedData, relativePath: "clean/\(mistake.id.uuidString)-\(suffix).jpg")

        let oldOrig = mistake.originalImagePath
        let oldClean = mistake.cleanedImagePath

        mistake.originalImagePath = newOrigRel
        mistake.cleanedImagePath = newCleanRel
        mistake.handwritingRemovalSucceeded = succeeded
        if !ocrText.isEmpty {
            mistake.ocrText = ocrText
        }
        try context.save()

        imageStore.deleteFile(relativePath: oldOrig)
        imageStore.deleteFile(relativePath: oldClean)
    }

    /// Saves manual eraser edits over the mistake's cleaned image while preserving originalImagePath untouched.
    func saveManualCleanedImage(_ image: UIImage, for mistake: MistakeItem, in context: ModelContext) throws {
        guard let jpeg = image.jpegData(compressionQuality: 0.90) else {
            throw ImageStoreError.imageEncodingFailed
        }
        let suffix = UUID().uuidString.prefix(8)
        let relPath = try imageStore.saveJPEG(jpeg, relativePath: "clean/\(mistake.id.uuidString)-\(suffix).jpg")
        let oldClean = mistake.cleanedImagePath
        mistake.cleanedImagePath = relPath
        mistake.handwritingRemovalSucceeded = true
        try context.save()
        if oldClean != relPath {
            imageStore.deleteFile(relativePath: oldClean)
        }
    }

    /// Saves an answer attachment image (up to maxAnswerImages).
    func appendAnswerImage(_ image: UIImage, to mistake: MistakeItem, in context: ModelContext) throws {
        guard mistake.answerImagePaths.count < MistakeLimits.maxAnswerImages else { return }
        guard let jpeg = image.jpegData(compressionQuality: 0.85) else {
            throw ImageStoreError.imageEncodingFailed
        }
        let relPath = try imageStore.saveJPEG(jpeg, relativePath: "ans/\(mistake.id.uuidString)-\(UUID().uuidString.prefix(8)).jpg")
        mistake.answerImagePaths.append(relPath)
        try context.save()
    }

    /// Deletes a Subject according to PRD §8.6 safety rules; refuses to delete the fallback uncategorized bucket.
    func deleteSubject(
        _ subject: Subject,
        strategy: SubjectDeletionStrategy,
        in context: ModelContext
    ) throws {
        guard !subject.isUncategorizedBucket else { return }

        let attachedMistakes = subject.mistakes
        switch strategy {
        case .moveToUncategorized:
            let fallback = SubjectCatalog.fetchOrCreateUncategorized(in: context)
            for item in attachedMistakes {
                item.subject = fallback
            }
        case .deleteWithMistakes:
            for item in attachedMistakes {
                purgeImages(for: item)
                context.delete(item)
            }
        }

        context.delete(subject)
        try context.save()
    }

    /// Deletes a tag without deleting any MistakeItem records (PRD §8.6).
    func deleteTag(_ tag: MistakeTag, in context: ModelContext) throws {
        for mistake in tag.mistakes {
            mistake.tags.removeAll { $0.id == tag.id }
        }
        context.delete(tag)
        try context.save()
    }

    /// Deletes a custom cause name without deleting any MistakeItem records (PRD §8.6).
    func deleteCustomCause(_ cause: CustomCause, in context: ModelContext) throws {
        let name = cause.name
        let allMistakes = (try? context.fetch(FetchDescriptor<MistakeItem>())) ?? []
        for mistake in allMistakes where mistake.customCauseNames.contains(name) {
            mistake.customCauseNames.removeAll { $0 == name }
        }
        context.delete(cause)
        try context.save()
    }

    /// Permanently removes a MistakeItem and its stored image files after undo window expires.
    func permanentlyDeleteMistake(_ mistake: MistakeItem, in context: ModelContext) throws {
        purgeImages(for: mistake)
        context.delete(mistake)
        try context.save()
    }

    private func purgeImages(for mistake: MistakeItem) {
        imageStore.deleteFile(relativePath: mistake.originalImagePath)
        imageStore.deleteFile(relativePath: mistake.cleanedImagePath)
        for ansPath in mistake.answerImagePaths {
            imageStore.deleteFile(relativePath: ansPath)
        }
    }

    private func resolveOrCreateTags(named names: [String], in context: ModelContext) -> [MistakeTag] {
        let cleanedNames = Array(
            Set(
                names.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        ).sorted()
        guard !cleanedNames.isEmpty else { return [] }

        let existing = (try? context.fetch(FetchDescriptor<MistakeTag>())) ?? []
        var result: [MistakeTag] = []

        for name in cleanedNames {
            if let match = existing.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
                result.append(match)
            } else {
                let tag = MistakeTag(name: name)
                context.insert(tag)
                result.append(tag)
            }
        }
        return result
    }
}
