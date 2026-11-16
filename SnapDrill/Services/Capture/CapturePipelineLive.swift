import Foundation
import SwiftData
import UIKit

/// Slice 2：相册/GPS 剥离/增强/入库；相机与 VisionKit 后续在同类型扩展。
/// `ModelContext` 仅在 `@MainActor` 保存闭包中使用；类型标 `@unchecked Sendable` 以满足 pipeline 合同。
struct CapturePipelineLive: CapturePipelineServing, @unchecked Sendable {
    let maxPhotoCount = 10
    let maxBoxesPerPage = 10

    private let sanitizer: any PhotoDataSanitizing
    private let saveHandler: (CaptureSavePreview, UUID) async throws -> Int

    init(
        sanitizer: any PhotoDataSanitizing = DefaultPhotoDataSanitizer(),
        saveHandler: @escaping (CaptureSavePreview, UUID) async throws -> Int
    ) {
        self.sanitizer = sanitizer
        self.saveHandler = saveHandler
    }

    @MainActor
    static func make(modelContext: ModelContext) -> CapturePipelineLive {
        CapturePipelineLive(
            saveHandler: { preview, subjectID in
                try await MainActor.run {
                    try LibrarySaveService.commit(preview: preview, subjectID: subjectID, context: modelContext)
                }
            }
        )
    }

    func beginSession(importedImageData: [Data]) async throws -> CaptureSession {
        guard !importedImageData.isEmpty else { throw CapturePipelineError.emptySession }
        guard importedImageData.count <= maxPhotoCount else {
            throw CapturePipelineError.tooManyPhotos(limit: maxPhotoCount)
        }
        let stripped = importedImageData.map { sanitizer.stripGPSMetadata(from: $0) }
        let pages = stripped.map { CapturePage(imageData: $0) }
        return CaptureSession(pages: pages)
    }

    func applyDocumentCorrection(session: CaptureSession) async throws -> CaptureSession {
        session
    }

    func setEnhancement(mode: ImageEnhancementMode, pageID: UUID, in session: CaptureSession) async throws -> CaptureSession {
        var next = session
        guard let index = next.pages.firstIndex(where: { $0.id == pageID }) else { return session }
        var page = next.pages[index]
        page.enhancementMode = mode
        if let enhanced = UIImage(data: page.imageData).flatMap({ ImageEnhancementService.apply(mode, to: $0) }) {
            page.imageData = enhanced.jpegData(compressionQuality: 0.88) ?? page.imageData
        }
        next.pages[index] = page
        return next
    }

    func addBox(on pageID: UUID, in session: CaptureSession) async throws -> CaptureSession {
        var next = session
        guard let index = next.pages.firstIndex(where: { $0.id == pageID }) else { return session }
        guard next.pages[index].boxes.count < maxBoxesPerPage else {
            throw CapturePipelineError.tooManyBoxesPerPage(limit: maxBoxesPerPage)
        }
        next.pages[index].boxes.append(CaptureCropBox())
        return next
    }

    func updateBox(_ box: CaptureCropBox, on pageID: UUID, in session: CaptureSession) async throws -> CaptureSession {
        var next = session
        guard let pageIndex = next.pages.firstIndex(where: { $0.id == pageID }),
              let boxIndex = next.pages[pageIndex].boxes.firstIndex(where: { $0.id == box.id })
        else { return session }
        next.pages[pageIndex].boxes[boxIndex] = box
        return next
    }

    func buildSavePreview(for session: CaptureSession) async throws -> CaptureSavePreview {
        guard session.totalBoxCount > 0 else { throw CapturePipelineError.emptySession }
        var items: [CaptureSaveItem] = []
        for (pageIndex, page) in session.pages.enumerated() {
            for box in page.boxes {
                guard let image = UIImage(data: page.imageData) else { continue }
                let crop = CaptureImageUtilities.crop(image, normalized: box.normalizedRect) ?? image
                let data = crop.jpegData(compressionQuality: 0.88) ?? page.imageData
                let outcome = await HandwritingRemovalService.process(image: crop)
                switch outcome {
                case .cleaned(let cleaned):
                    items.append(
                        CaptureSaveItem(
                            pageIndex: pageIndex,
                            boxID: box.id,
                            originalImageData: data,
                            cleanedImageData: cleaned.jpegData(compressionQuality: 0.88) ?? data,
                            handwritingRemovalSucceeded: true
                        )
                    )
                case .fallbackEnhancedOriginal(let enhanced, _):
                    items.append(
                        CaptureSaveItem(
                            pageIndex: pageIndex,
                            boxID: box.id,
                            originalImageData: data,
                            cleanedImageData: enhanced.jpegData(compressionQuality: 0.88) ?? data,
                            handwritingRemovalSucceeded: false
                        )
                    )
                }
            }
        }
        return CaptureSavePreview(items: items)
    }

    func commitSave(preview: CaptureSavePreview, subjectID: UUID) async throws -> Int {
        try await saveHandler(preview, subjectID)
    }
}