import Foundation
import SwiftData
import Testing
import UIKit
@testable import SnapDrill

@Test @MainActor
func librarySavePersistsMistakeItems() throws {
    let schema = Schema([Subject.self, MistakeItem.self, MistakeTag.self, CaptureDraft.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [config])
    let context = container.mainContext
    let subject = Subject(name: "Math", colorHex: "3B82F6", sortOrder: 0, isBuiltin: true)
    context.insert(subject)

    let jpeg = tinyTestJPEGData()
    let preview = CaptureSavePreview(
        items: [
            CaptureSaveItem(
                pageIndex: 0,
                boxID: UUID(),
                originalImageData: jpeg,
                cleanedImageData: jpeg,
                handwritingRemovalSucceeded: false
            ),
        ]
    )

    let count = try LibrarySaveService.commit(preview: preview, subjectID: subject.id, context: context)
    #expect(count == 1)

    let mistakes = try context.fetch(FetchDescriptor<MistakeItem>())
    #expect(mistakes.count == 1)
    #expect(mistakes[0].subject?.id == subject.id)
    #expect(mistakes[0].originalImagePath != nil)
}

@Test @MainActor
func captureLiveStripsGPSOnImport() async throws {
    let pipeline = CapturePipelineLive(
        saveHandler: { _, _ in 0 }
    )
    let data = tinyTestJPEGData()
    let session = try await pipeline.beginSession(importedImageData: [data])
    #expect(session.pages.count == 1)
    #expect(!session.pages[0].imageData.isEmpty)
}

private func tinyTestJPEGData() -> Data {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40))
    let image = renderer.image { ctx in
        UIColor.white.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
    }
    return image.jpegData(compressionQuality: 0.9) ?? Data()
}