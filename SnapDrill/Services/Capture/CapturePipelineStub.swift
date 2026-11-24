import Foundation

/// Lightweight deterministic stub useful in unit tests and SwiftUI previews.
struct CapturePipelineStub: CapturePipelineServing {
    let maxPhotoCount: Int = MistakeLimits.maxPhotosPerSession
    let maxBoxesPerPage: Int = MistakeLimits.maxBoxesPerPage

    func beginSession(importedImageData: [Data]) async throws -> CaptureSession {
        guard !importedImageData.isEmpty else { throw CapturePipelineError.emptySession }
        guard importedImageData.count <= maxPhotoCount else {
            throw CapturePipelineError.tooManyPhotos(limit: maxPhotoCount)
        }
        let pages = importedImageData.map { CapturePage(rawImageData: $0) }
        return CaptureSession(pages: pages, activeStep: 1)
    }

    func updateCorners(_ corners: QuadCorners, pageID: UUID, in session: CaptureSession) async throws -> CaptureSession {
        var updated = session
        if let idx = updated.pages.firstIndex(where: { $0.id == pageID }) {
            updated.pages[idx].corners = corners
        }
        return updated
    }

    func setEnhancement(mode: ImageEnhancementMode, pageID: UUID, in session: CaptureSession) async throws -> CaptureSession {
        var updated = session
        if let idx = updated.pages.firstIndex(where: { $0.id == pageID }) {
            updated.pages[idx].enhancementMode = mode
        }
        return updated
    }

    func addBox(on pageID: UUID, rect: CGRect?, in session: CaptureSession) async throws -> CaptureSession {
        var updated = session
        guard let idx = updated.pages.firstIndex(where: { $0.id == pageID }) else { return session }
        guard updated.pages[idx].boxes.count < maxBoxesPerPage else {
            throw CapturePipelineError.tooManyBoxesPerPage(limit: maxBoxesPerPage)
        }
        updated.pages[idx].boxes.append(CaptureCropBox(normalizedRect: rect ?? CGRect(x: 0.1, y: 0.5, width: 0.8, height: 0.3)))
        return updated
    }

    func updateBox(_ box: CaptureCropBox, on pageID: UUID, in session: CaptureSession) async throws -> CaptureSession {
        var updated = session
        if let p = updated.pages.firstIndex(where: { $0.id == pageID }),
           let b = updated.pages[p].boxes.firstIndex(where: { $0.id == box.id }) {
            updated.pages[p].boxes[b] = box
        }
        return updated
    }

    func removeBox(boxID: UUID, on pageID: UUID, in session: CaptureSession) async throws -> CaptureSession {
        var updated = session
        if let p = updated.pages.firstIndex(where: { $0.id == pageID }), updated.pages[p].boxes.count > 1 {
            updated.pages[p].boxes.removeAll { $0.id == boxID }
        }
        return updated
    }

    func suggestQuestionBoxes(on pageID: UUID, in session: CaptureSession) async throws -> CaptureSession {
        session
    }

    func buildSavePreview(for session: CaptureSession, mode: InkRemovalMode) async throws -> CaptureSavePreview {
        guard !session.pages.isEmpty else { throw CapturePipelineError.emptySession }
        var items: [CaptureSaveItem] = []
        for (pIdx, page) in session.pages.enumerated() {
            for (bIdx, box) in page.boxes.enumerated() {
                items.append(
                    CaptureSaveItem(
                        id: box.id,
                        pageIndex: pIdx,
                        boxIndex: bIdx,
                        originalImageData: page.enhancedImageData,
                        cleanedImageData: page.enhancedImageData,
                        handwritingRemovalSucceeded: mode != .off,
                        ocrText: "",
                        pageImageData: page.enhancedImageData,
                        cropRectNormalized: box.normalizedRect
                    )
                )
            }
        }
        return CaptureSavePreview(items: items, inkRemovalMode: mode)
    }

    func reprocessItem(_ item: CaptureSaveItem, mode: InkRemovalMode) async -> CaptureSaveItem {
        item
    }
}
