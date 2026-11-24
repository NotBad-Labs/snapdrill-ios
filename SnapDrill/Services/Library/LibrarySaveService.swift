import Foundation
import SwiftData
import UIKit

/// Strategy when deleting a Subject that already owns mistakes (PRD §8.6, AC-09).
enum SubjectDeletionStrategy: Sendable {
    case moveToUncategorized
    case deleteWithMistakes
}

/// Errors surfaced when re-cropping an existing mistake fails instead of failing silently (M-07).
enum RecropError: Error, LocalizedError, Equatable, Sendable {
    case missingSourceImage
    case invalidCropRegion
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .missingSourceImage:
            return String(localized: "Original page photo is unavailable for re-cropping.")
        case .invalidCropRegion:
            return String(localized: "Selected crop region is invalid.")
        case .encodingFailed:
            return String(localized: "Could not encode the updated cropped image.")
        }
    }
}

/// Coordinates atomic persistence of mistakes, image files, CloudKit binary sync assets, re-cropping, and safe deletions.
@MainActor
final class LibrarySaveService {
    private let imageStore: MistakeImageStore
    private let inkRemover: InkRemoving
    private let textRecognizer: @Sendable (Data) async -> String

    init(
        imageStore: MistakeImageStore = MistakeImageStore(),
        inkRemover: InkRemoving = CoreMLCapableInkRemover(),
        textRecognizer: @escaping @Sendable (Data) async -> String = { data in
            await OCRIndexingService.recognizeText(in: data)
        }
    ) {
        self.imageStore = imageStore
        self.inkRemover = inkRemover
        self.textRecognizer = textRecognizer
    }

    /// Saves N cropped preview items atomically into SwiftData and disk; rolls back items, newly inserted tags,
    /// context changes, and disk files if saving fails (AC-03, AC-09, M2).
    @discardableResult
    func commitSave(
        preview: CaptureSavePreview,
        subject: Subject,
        in context: ModelContext
    ) throws -> [MistakeItem] {
        var writtenRelativePaths: [String] = []
        var insertedItems: [MistakeItem] = []
        var newlyInsertedTags: [MistakeTag] = []
        var savedPages: [Int: (path: String, data: Data)] = [:]

        do {
            let batchPrefix = UUID().uuidString.prefix(8)

            for item in preview.items {
                let itemID = UUID()

                let pageSaved: (path: String, data: Data)?
                if let existing = savedPages[item.pageIndex] {
                    pageSaved = existing
                } else if let rawPageData = item.pageImageData {
                    let result = try imageStore.saveJPEGWithData(
                        rawPageData,
                        relativePath: "page/\(batchPrefix)-p\(item.pageIndex).jpg",
                        maxBytes: 350 * 1024
                    )
                    writtenRelativePaths.append(result.relativePath)
                    let stored = (path: result.relativePath, data: result.compressedData)
                    savedPages[item.pageIndex] = stored
                    pageSaved = stored
                } else {
                    pageSaved = nil
                }

                let origResult = try imageStore.saveJPEGWithData(
                    item.originalImageData,
                    relativePath: "orig/\(itemID.uuidString).jpg",
                    maxBytes: 420 * 1024
                )
                writtenRelativePaths.append(origResult.relativePath)

                let cleanResult = try imageStore.saveJPEGWithData(
                    item.cleanedImageData,
                    relativePath: "clean/\(itemID.uuidString).jpg",
                    maxBytes: 420 * 1024
                )
                writtenRelativePaths.append(cleanResult.relativePath)

                let resolvedTags = resolveOrCreateTags(
                    named: item.tagNames,
                    in: context,
                    newlyInsertedTags: &newlyInsertedTags
                )

                var savedAnswerPaths: [String] = []
                var savedAnswerSlots: [Data?] = []
                for (ansIndex, rawAnswerData) in item.answerImageDatas.prefix(MistakeLimits.maxAnswerImages).enumerated() {
                    let ansResult = try imageStore.saveJPEGWithData(
                        rawAnswerData,
                        relativePath: "ans/\(itemID.uuidString)-\(ansIndex)-\(UUID().uuidString.prefix(6)).jpg",
                        maxBytes: 450 * 1024
                    )
                    writtenRelativePaths.append(ansResult.relativePath)
                    savedAnswerPaths.append(ansResult.relativePath)
                    savedAnswerSlots.append(ansResult.compressedData)
                }

                let mistake = MistakeItem(
                    id: itemID,
                    createdAt: .now,
                    sourceTitle: item.sourceTitle,
                    notes: item.notes,
                    answerText: item.answerText,
                    answerImagePaths: savedAnswerPaths,
                    causes: item.causes,
                    customCauseNames: item.customCauseNames,
                    mastery: .unknown,
                    ocrText: item.ocrText,
                    originalImagePath: origResult.relativePath,
                    cleanedImagePath: cleanResult.relativePath,
                    pageImagePath: pageSaved?.path,
                    cropRectNormalized: item.cropRectNormalized,
                    handwritingRemovalSucceeded: item.handwritingRemovalSucceeded,
                    originalImageData: origResult.compressedData,
                    cleanedImageData: cleanResult.compressedData,
                    pageImageData: pageSaved?.data,
                    subject: subject
                )
                mistake.setAnswerImageSlots(savedAnswerSlots)
                mistake.tagList = Array(resolvedTags.prefix(MistakeLimits.maxTagsPerMistake))
                context.insert(mistake)
                insertedItems.append(mistake)
            }

            try context.save()
            return insertedItems
        } catch {
            // Roll back all inserted items, newly created tags, pending SwiftData mutations, and written files
            for item in insertedItems {
                context.delete(item)
            }
            for tag in newlyInsertedTags {
                context.delete(tag)
            }
            context.rollback()
            for relPath in writtenRelativePaths {
                imageStore.deleteFile(relativePath: relPath)
            }
            throw error
        }
    }

    /// Re-crops strictly from the full preserved page image (never falls back to already-cropped question image) (PRD §8.3, AC-05, M2).
    func recropMistake(
        _ mistake: MistakeItem,
        normalizedRect: CGRect,
        mode: InkRemovalMode,
        in context: ModelContext
    ) async throws {
        guard let sourceData = mistake.strictPageImageData(imageStore: imageStore) else {
            throw RecropError.missingSourceImage
        }
        guard let croppedData = CapturePipelineLive.cropImageData(sourceData, normalizedRect: normalizedRect) else {
            throw RecropError.invalidCropRegion
        }

        let (cleanedData, succeeded) = await inkRemover.removeInk(from: croppedData, mode: mode)
        let ocrText = await textRecognizer(cleanedData)

        let suffix = UUID().uuidString.prefix(8)
        let newOrig = try imageStore.saveJPEGWithData(
            croppedData,
            relativePath: "orig/\(mistake.id.uuidString)-\(suffix).jpg",
            maxBytes: 420 * 1024
        )
        let newClean: (relativePath: String, compressedData: Data)
        do {
            newClean = try imageStore.saveJPEGWithData(
                cleanedData,
                relativePath: "clean/\(mistake.id.uuidString)-\(suffix).jpg",
                maxBytes: 420 * 1024
            )
        } catch {
            imageStore.deleteFile(relativePath: newOrig.relativePath)
            throw error
        }

        let oldOrig = mistake.originalImagePath
        let oldClean = mistake.cleanedImagePath

        mistake.originalImagePath = newOrig.relativePath
        mistake.cleanedImagePath = newClean.relativePath
        mistake.originalImageData = newOrig.compressedData
        mistake.cleanedImageData = newClean.compressedData
        mistake.cropRectNormalized = normalizedRect.clampedToUnitSquare()
        mistake.handwritingRemovalSucceeded = succeeded
        if !ocrText.isEmpty {
            mistake.ocrText = ocrText
        }

        do {
            try context.save()
        } catch {
            context.rollback()
            imageStore.deleteFile(relativePath: newOrig.relativePath)
            imageStore.deleteFile(relativePath: newClean.relativePath)
            throw error
        }

        if oldOrig != newOrig.relativePath, oldOrig != mistake.pageImagePath {
            imageStore.deleteFile(relativePath: oldOrig)
        }
        if oldClean != newClean.relativePath {
            imageStore.deleteFile(relativePath: oldClean)
        }
    }

    /// Saves manual eraser edits safely, purging old cleaned file only after SwiftData commit succeeds.
    func saveManualCleanedImage(_ image: UIImage, for mistake: MistakeItem, in context: ModelContext) throws {
        guard let jpeg = image.jpegData(compressionQuality: 0.90) else {
            throw ImageStoreError.imageEncodingFailed
        }
        let suffix = UUID().uuidString.prefix(8)
        let saved = try imageStore.saveJPEGWithData(
            jpeg,
            relativePath: "clean/\(mistake.id.uuidString)-\(suffix).jpg",
            maxBytes: 450 * 1024
        )
        let oldClean = mistake.cleanedImagePath
        mistake.cleanedImagePath = saved.relativePath
        mistake.cleanedImageData = saved.compressedData
        mistake.handwritingRemovalSucceeded = true

        do {
            try context.save()
        } catch {
            context.rollback()
            imageStore.deleteFile(relativePath: saved.relativePath)
            throw error
        }

        if oldClean != saved.relativePath {
            imageStore.deleteFile(relativePath: oldClean)
        }
    }

    /// Saves an answer attachment image (up to maxAnswerImages) and syncs CloudKit binary slots without compacting away unhydrated slots.
    func appendAnswerImage(_ image: UIImage, to mistake: MistakeItem, in context: ModelContext) throws {
        guard mistake.answerImagePaths.count < MistakeLimits.maxAnswerImages else { return }
        guard let jpeg = image.jpegData(compressionQuality: 0.85) else {
            throw ImageStoreError.imageEncodingFailed
        }
        let saved = try imageStore.saveJPEGWithData(
            jpeg,
            relativePath: "ans/\(mistake.id.uuidString)-\(UUID().uuidString.prefix(8)).jpg",
            maxBytes: 450 * 1024
        )

        var preservedSlots: [Data?] = (0..<mistake.answerImagePaths.count).map { idx in
            mistake.resolvedAnswerImageData(at: idx, imageStore: imageStore)
        }
        preservedSlots.append(saved.compressedData)
        mistake.answerImagePaths.append(saved.relativePath)
        mistake.setAnswerImageSlots(preservedSlots)

        do {
            try context.save()
        } catch {
            context.rollback()
            imageStore.deleteFile(relativePath: saved.relativePath)
            throw error
        }
    }

    /// Re-synchronizes answerImageData0..2 slots strictly by path index, preserving CloudKit externalStorage
    /// bytes when local ans/ files have not been hydrated yet on a secondary device (Blocker B2).
    func syncAnswerImageSlots(for mistake: MistakeItem) {
        let slots: [Data?] = mistake.answerImagePaths
            .prefix(MistakeLimits.maxAnswerImages)
            .enumerated()
            .map { idx, path in
                imageStore.loadData(relativePath: path) ?? mistake.answerImageSlotData(at: idx)
            }
        mistake.setAnswerImageSlots(slots)
    }

    /// Commits staged answer photo additions/removals atomically to disk and CloudKit slots (Blocker B2).
    func applyAnswerImageEdits(
        slots: [(path: String?, data: Data?)],
        to mistake: MistakeItem
    ) throws -> [String] {
        var finalPaths: [String] = []
        var finalSlotDatas: [Data?] = []
        var newlyWrittenPaths: [String] = []

        do {
            for slot in slots.prefix(MistakeLimits.maxAnswerImages) {
                if let existingPath = slot.path {
                    let originalIdx = mistake.answerImagePaths.firstIndex(of: existingPath)
                    let resolvedData = slot.data
                        ?? imageStore.loadData(relativePath: existingPath)
                        ?? originalIdx.flatMap { mistake.answerImageSlotData(at: $0) }
                    finalPaths.append(existingPath)
                    finalSlotDatas.append(resolvedData)
                } else if let rawData = slot.data, let uiImg = UIImage(data: rawData),
                          let jpeg = uiImg.jpegData(compressionQuality: 0.85) {
                    let saved = try imageStore.saveJPEGWithData(
                        jpeg,
                        relativePath: "ans/\(mistake.id.uuidString)-\(UUID().uuidString.prefix(8)).jpg",
                        maxBytes: 450 * 1024
                    )
                    newlyWrittenPaths.append(saved.relativePath)
                    finalPaths.append(saved.relativePath)
                    finalSlotDatas.append(saved.compressedData)
                }
            }
        } catch {
            for relPath in newlyWrittenPaths {
                imageStore.deleteFile(relativePath: relPath)
            }
            throw error
        }

        mistake.answerImagePaths = finalPaths
        mistake.setAnswerImageSlots(finalSlotDatas)
        return newlyWrittenPaths
    }

    /// Deletes a Subject according to PRD §8.6 safety rules; refuses to delete the fallback uncategorized bucket.
    /// Deletes stored images ONLY after SwiftData save succeeds (M2).
    func deleteSubject(
        _ subject: Subject,
        strategy: SubjectDeletionStrategy,
        in context: ModelContext
    ) throws {
        guard !subject.isUncategorizedBucket else { return }

        let attachedMistakes = subject.mistakeList
        var pathsToDelete: [String] = []

        switch strategy {
        case .moveToUncategorized:
            let fallback = SubjectCatalog.fetchOrCreateUncategorized(in: context)
            for item in attachedMistakes {
                item.subject = fallback
            }
        case .deleteWithMistakes:
            let deletingIDs = Set(attachedMistakes.map(\.id))
            pathsToDelete = collectibleImagePaths(for: attachedMistakes, excludingIDs: deletingIDs, in: context)
            for item in attachedMistakes {
                context.delete(item)
            }
        }

        context.delete(subject)

        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }

        for path in pathsToDelete {
            imageStore.deleteFile(relativePath: path)
        }
    }

    /// Deletes a tag without deleting any MistakeItem records (PRD §8.6).
    func deleteTag(_ tag: MistakeTag, in context: ModelContext) throws {
        for mistake in tag.mistakeList {
            mistake.tagList.removeAll { $0.id == tag.id }
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

    /// Permanently removes a MistakeItem and purges unshared disk image files ONLY after SwiftData save succeeds (M2).
    func permanentlyDeleteMistake(_ mistake: MistakeItem, in context: ModelContext) throws {
        let pathsToDelete = collectibleImagePaths(for: [mistake], excludingIDs: [mistake.id], in: context)
        context.delete(mistake)

        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }

        for path in pathsToDelete {
            imageStore.deleteFile(relativePath: path)
        }
    }

    private func collectibleImagePaths(
        for targets: [MistakeItem],
        excludingIDs: Set<UUID>,
        in context: ModelContext
    ) -> [String] {
        let survivingItems = ((try? context.fetch(FetchDescriptor<MistakeItem>())) ?? [])
            .filter { !excludingIDs.contains($0.id) }
        var survivingSharedPaths = Set<String>()
        for surviving in survivingItems {
            if let page = surviving.pageImagePath { survivingSharedPaths.insert(page) }
            if let orig = surviving.originalImagePath { survivingSharedPaths.insert(orig) }
            if let clean = surviving.cleanedImagePath { survivingSharedPaths.insert(clean) }
            for ans in surviving.answerImagePaths { survivingSharedPaths.insert(ans) }
        }

        var result: [String] = []
        for mistake in targets {
            let candidates = [mistake.originalImagePath, mistake.cleanedImagePath, mistake.pageImagePath].compactMap { $0 }
                + mistake.answerImagePaths
            for path in candidates where !path.isEmpty && !survivingSharedPaths.contains(path) {
                result.append(path)
            }
        }
        return Array(Set(result))
    }

    private func resolveOrCreateTags(
        named names: [String],
        in context: ModelContext,
        newlyInsertedTags: inout [MistakeTag]
    ) -> [MistakeTag] {
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
                newlyInsertedTags.append(tag)
                result.append(tag)
            }
        }
        return result
    }
}
