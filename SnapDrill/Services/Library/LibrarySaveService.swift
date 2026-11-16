import Foundation
import SwiftData

/// Capture `commitSave` 的 SwiftData 实现（Slice 2）；UI 仍只经 `CapturePipelineServing`。
@MainActor
enum LibrarySaveService {
    static func commit(preview: CaptureSavePreview, subjectID: UUID, context: ModelContext) throws -> Int {
        guard preview.questionCount > 0 else { throw CapturePipelineError.emptySession }

        var subjectDescriptor = FetchDescriptor<Subject>(
            predicate: #Predicate { $0.id == subjectID }
        )
        subjectDescriptor.fetchLimit = 1
        guard let subject = try context.fetch(subjectDescriptor).first else {
            throw CapturePipelineError.subjectRequired
        }

        var saved = 0
        for item in preview.items {
            let mistake = MistakeItem(subject: subject)
            let originalName = "\(mistake.id.uuidString)_original.jpg"
            let cleanedName = "\(mistake.id.uuidString)_cleaned.jpg"
            mistake.originalImagePath = try MistakeImageStore.writeJPEG(item.originalImageData, fileName: originalName)
            mistake.cleanedImagePath = try MistakeImageStore.writeJPEG(item.cleanedImageData, fileName: cleanedName)
            mistake.handwritingRemovalSucceeded = item.handwritingRemovalSucceeded
            context.insert(mistake)
            saved += 1
        }
        try context.save()
        return saved
    }
}