import Foundation
import UIKit

/// Production capture pipeline orchestrating off-MainActor GPS stripping, edge detection, enhancement,
/// multi-box cropping, OCR, and ink removal (PRD §8.2, AC-01~AC-04).
struct CapturePipelineLive: CapturePipelineServing {
    let maxPhotoCount: Int = MistakeLimits.maxPhotosPerSession
    let maxBoxesPerPage: Int = MistakeLimits.maxBoxesPerPage

    private let sanitizer: PhotoDataSanitizing
    private let edgeDetector: DocumentDetecting
    private let enhancer: ImageEnhancing
    private let inkRemover: InkRemoving
    private let smartDetector: SmartQuestionDetecting
    private let textRecognizer: @Sendable (Data) async -> String

    init(
        sanitizer: PhotoDataSanitizing = PhotoDataSanitizer(),
        edgeDetector: DocumentDetecting = DocumentEdgeDetector(),
        enhancer: ImageEnhancing = ImageEnhancementService(),
        inkRemover: InkRemoving = CoreMLCapableInkRemover(),
        smartDetector: SmartQuestionDetecting = SmartQuestionDetector(),
        textRecognizer: @escaping @Sendable (Data) async -> String = { data in
            await OCRIndexingService.recognizeText(in: data)
        }
    ) {
        self.sanitizer = sanitizer
        self.edgeDetector = edgeDetector
        self.enhancer = enhancer
        self.inkRemover = inkRemover
        self.smartDetector = smartDetector
        self.textRecognizer = textRecognizer
    }

    func beginSession(importedImageData: [Data]) async throws -> CaptureSession {
        guard !importedImageData.isEmpty else {
            throw CapturePipelineError.emptySession
        }
        guard importedImageData.count <= maxPhotoCount else {
            throw CapturePipelineError.tooManyPhotos(limit: maxPhotoCount)
        }

        let sanitizer = self.sanitizer
        let edgeDetector = self.edgeDetector
        let enhancer = self.enhancer

        var pages: [CapturePage] = []
        pages.reserveCapacity(importedImageData.count)

        for rawData in importedImageData {
            let cleanRaw = try await Task.detached(priority: .userInitiated) { () -> Data in
                guard let sanitized = sanitizer.sanitize(rawData, maxDimension: 2200) else {
                    throw CapturePipelineError.invalidImageData
                }
                return sanitized
            }.value

            let corners = await edgeDetector.detectCorners(in: cleanRaw)
            let (corrected, enhanced) = await Task.detached(priority: .userInitiated) {
                let corr = edgeDetector.applyPerspectiveCorrection(to: cleanRaw, corners: corners)
                let enh = enhancer.apply(.enhanced, to: corr)
                return (corr, enh)
            }.value

            pages.append(
                CapturePage(
                    rawImageData: cleanRaw,
                    correctedImageData: corrected,
                    enhancedImageData: enhanced,
                    corners: corners,
                    enhancementMode: .enhanced,
                    boxes: [CaptureCropBox()]
                )
            )
        }

        return CaptureSession(pages: pages, activeStep: 1)
    }

    func updateCorners(_ corners: QuadCorners, pageID: UUID, in session: CaptureSession) async throws -> CaptureSession {
        var updated = session
        guard let idx = updated.pages.firstIndex(where: { $0.id == pageID }) else { return session }
        guard corners.isConvexAndValid else { return session }

        var page = updated.pages[idx]
        page.corners = corners
        let rawData = page.rawImageData
        let mode = page.enhancementMode
        let edgeDetector = self.edgeDetector
        let enhancer = self.enhancer

        let (corrected, enhanced) = await Task.detached(priority: .userInitiated) {
            let corr = edgeDetector.applyPerspectiveCorrection(to: rawData, corners: corners)
            let enh = enhancer.apply(mode, to: corr)
            return (corr, enh)
        }.value

        page.correctedImageData = corrected
        page.enhancedImageData = enhanced
        updated.pages[idx] = page
        return updated
    }

    func setEnhancement(mode: ImageEnhancementMode, pageID: UUID, in session: CaptureSession) async throws -> CaptureSession {
        var updated = session
        guard let idx = updated.pages.firstIndex(where: { $0.id == pageID }) else { return session }
        var page = updated.pages[idx]
        page.enhancementMode = mode
        let correctedData = page.correctedImageData
        let enhancer = self.enhancer

        let enhanced = await Task.detached(priority: .userInitiated) {
            enhancer.apply(mode, to: correctedData)
        }.value

        page.enhancedImageData = enhanced
        updated.pages[idx] = page
        return updated
    }

    func addBox(on pageID: UUID, rect: CGRect?, in session: CaptureSession) async throws -> CaptureSession {
        var updated = session
        guard let idx = updated.pages.firstIndex(where: { $0.id == pageID }) else { return session }
        guard updated.pages[idx].boxes.count < maxBoxesPerPage else {
            throw CapturePipelineError.tooManyBoxesPerPage(limit: maxBoxesPerPage)
        }

        let offset = CGFloat(updated.pages[idx].boxes.count % 4) * 0.08
        let defaultRect = rect ?? CGRect(x: 0.08, y: min(0.62, 0.14 + offset), width: 0.84, height: 0.28)
        updated.pages[idx].boxes.append(CaptureCropBox(normalizedRect: defaultRect))
        return updated
    }

    func updateBox(_ box: CaptureCropBox, on pageID: UUID, in session: CaptureSession) async throws -> CaptureSession {
        var updated = session
        guard let pageIdx = updated.pages.firstIndex(where: { $0.id == pageID }),
              let boxIdx = updated.pages[pageIdx].boxes.firstIndex(where: { $0.id == box.id }) else {
            return session
        }
        var sanitizedBox = box
        sanitizedBox.normalizedRect = box.normalizedRect.clampedToUnitSquare()
        updated.pages[pageIdx].boxes[boxIdx] = sanitizedBox
        return updated
    }

    func removeBox(boxID: UUID, on pageID: UUID, in session: CaptureSession) async throws -> CaptureSession {
        var updated = session
        guard let pageIdx = updated.pages.firstIndex(where: { $0.id == pageID }) else { return session }
        guard updated.pages[pageIdx].boxes.count > 1 else { return session }
        updated.pages[pageIdx].boxes.removeAll { $0.id == boxID }
        return updated
    }

    func suggestQuestionBoxes(on pageID: UUID, in session: CaptureSession) async throws -> CaptureSession {
        var updated = session
        guard let pageIdx = updated.pages.firstIndex(where: { $0.id == pageID }) else { return session }
        let boxes = await smartDetector.suggestBoxes(
            in: updated.pages[pageIdx].enhancedImageData,
            maxBoxes: maxBoxesPerPage
        )
        updated.pages[pageIdx].boxes = boxes
        return updated
    }

    func buildSavePreview(for session: CaptureSession, mode: InkRemovalMode) async throws -> CaptureSavePreview {
        guard !session.pages.isEmpty else {
            throw CapturePipelineError.emptySession
        }

        var items: [CaptureSaveItem] = []

        for (pageIndex, page) in session.pages.enumerated() {
            for (boxIndex, box) in page.boxes.enumerated() {
                let pageData = page.enhancedImageData
                let rect = box.normalizedRect
                let croppedData = await Task.detached(priority: .userInitiated) {
                    Self.cropImageData(pageData, normalizedRect: rect) ?? pageData
                }.value

                let (cleanedData, succeeded) = await inkRemover.removeInk(from: croppedData, mode: mode)
                let ocrText = await textRecognizer(cleanedData)

                items.append(
                    CaptureSaveItem(
                        id: box.id,
                        pageIndex: pageIndex,
                        boxIndex: boxIndex,
                        originalImageData: croppedData,
                        cleanedImageData: cleanedData,
                        handwritingRemovalSucceeded: succeeded,
                        ocrText: ocrText,
                        pageImageData: pageData,
                        cropRectNormalized: rect
                    )
                )
            }
        }

        return CaptureSavePreview(items: items, inkRemovalMode: mode)
    }

    func reprocessItem(_ item: CaptureSaveItem, mode: InkRemovalMode) async -> CaptureSaveItem {
        var updated = item
        let (cleanedData, succeeded) = await inkRemover.removeInk(from: item.originalImageData, mode: mode)
        updated.cleanedImageData = cleanedData
        updated.handwritingRemovalSucceeded = succeeded
        return updated
    }

    // MARK: - Cropping Helper

    static func cropImageData(_ data: Data, normalizedRect: CGRect) -> Data? {
        guard let uiImage = UIImage(data: data),
              let cgImage = uiImage.cgImage else {
            return nil
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
              let croppedCG = cgImage.cropping(to: pixelRect) else {
            return nil
        }

        return UIImage(cgImage: croppedCG).jpegData(compressionQuality: 0.88)
    }
}
