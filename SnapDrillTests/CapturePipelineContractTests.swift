import ImageIO
import UIKit
import XCTest
@testable import SnapDrill

final class CapturePipelineContractTests: XCTestCase {
    private func makeSolidImageData(color: UIColor = .white, size: CGSize = CGSize(width: 400, height: 300), drawRedStroke: Bool = false) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        let img = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            if drawRedStroke {
                UIColor(red: 0.88, green: 0.14, blue: 0.14, alpha: 1.0).setFill()
                // Place strokes inside BOTH default box (y: 0.12...0.46) and lower second box (y: 0.55...0.90)
                ctx.fill(CGRect(x: 40, y: size.height * 0.24, width: size.width - 80, height: 24))
                ctx.fill(CGRect(x: 40, y: size.height * 0.65, width: size.width - 80, height: 24))
            }
        }
        return img.jpegData(compressionQuality: 0.9)!
    }

    private func makeImageDataWithGPS() -> Data {
        let baseData = makeSolidImageData()
        guard let src = CGImageSourceCreateWithData(baseData as CFData, nil),
              let cg = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
            return baseData
        }
        let mutable = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(mutable, "public.jpeg" as CFString, 1, nil) else {
            return baseData
        }
        let gpsDict: [CFString: Any] = [
            kCGImagePropertyGPSLatitude: 31.2304,
            kCGImagePropertyGPSLatitudeRef: "N",
            kCGImagePropertyGPSLongitude: 121.4737,
            kCGImagePropertyGPSLongitudeRef: "E"
        ]
        let props: [CFString: Any] = [kCGImagePropertyGPSDictionary: gpsDict]
        CGImageDestinationAddImage(dest, cg, props as CFDictionary)
        CGImageDestinationFinalize(dest)
        return mutable as Data
    }

    func testPhotoDataSanitizerStripsGPSMetadata() throws {
        let dirtyData = makeImageDataWithGPS()
        let srcBefore = CGImageSourceCreateWithData(dirtyData as CFData, nil)!
        let propsBefore = CGImageSourceCopyPropertiesAtIndex(srcBefore, 0, nil) as? [CFString: Any]
        XCTAssertNotNil(propsBefore?[kCGImagePropertyGPSDictionary])

        let sanitizer = PhotoDataSanitizer()
        let cleanData = try XCTUnwrap(sanitizer.sanitize(dirtyData, maxDimension: 2200))

        let srcAfter = CGImageSourceCreateWithData(cleanData as CFData, nil)!
        let propsAfter = CGImageSourceCopyPropertiesAtIndex(srcAfter, 0, nil) as? [CFString: Any]
        XCTAssertNil(propsAfter?[kCGImagePropertyGPSDictionary])
    }

    func testQuadConvexValidationAndCanvasGeometryHelpers() {
        XCTAssertTrue(QuadCorners.fullFrame.isConvexAndValid)

        // Bowtie / crossed quad must be rejected
        let bowtie = QuadCorners(
            topLeft: CGPoint(x: 0.1, y: 0.1),
            topRight: CGPoint(x: 0.9, y: 0.9),
            bottomRight: CGPoint(x: 0.9, y: 0.1),
            bottomLeft: CGPoint(x: 0.1, y: 0.9)
        )
        XCTAssertFalse(bowtie.isConvexAndValid)

        // Canvas coordinate transform for corner and crop handles
        let frame = CGRect(x: 20, y: 40, width: 300, height: 400)
        let norm = PerspectiveCornerMath.normalizedPoint(fromCanvasPoint: CGPoint(x: 170, y: 240), in: frame)
        XCTAssertEqual(norm.x, 0.5, accuracy: 0.001)
        XCTAssertEqual(norm.y, 0.5, accuracy: 0.001)

        let baseRect = CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
        let resizedTL = CropBoxGeometry.resizedRect(from: baseRect, corner: .topLeft, toNormalizedPoint: CGPoint(x: 0.1, y: 0.1))
        XCTAssertEqual(resizedTL.minX, 0.1, accuracy: 0.001)
        XCTAssertEqual(resizedTL.maxX, 0.8, accuracy: 0.001)
        let resizedBR = CropBoxGeometry.resizedRect(from: baseRect, corner: .bottomRight, toNormalizedPoint: CGPoint(x: 0.9, y: 0.85))
        XCTAssertEqual(resizedBR.maxX, 0.9, accuracy: 0.001)
        XCTAssertEqual(resizedBR.maxY, 0.85, accuracy: 0.001)
    }

    func testNoisyHighResCompressionFitsDualImageUnderOneMegabyteBudget() throws {
        let size = CGSize(width: 2400, height: 1800)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        let img = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let cg = ctx.cgContext
            // Dense high-frequency grid texture
            UIColor.white.setFill()
            cg.fill(CGRect(origin: .zero, size: size))
            for y in stride(from: 0, to: Int(size.height), by: 6) {
                UIColor(hue: CGFloat(y % 360) / 360.0, saturation: 0.6, brightness: 0.7, alpha: 1.0).setFill()
                cg.fill(CGRect(x: 0, y: y, width: Int(size.width), height: 2))
            }
        }
        let raw = try XCTUnwrap(img.jpegData(compressionQuality: 1.0))
        let compressed = MistakeImageStore.compressToBudget(raw, maxBytes: 420 * 1024)
        XCTAssertLessThanOrEqual(compressed.count, 420 * 1024)
    }

    func testPipelineEnforcesPhotoAndBoxLimitsAndOrdering() async throws {
        let pipeline = CapturePipelineStub()
        let sample = makeSolidImageData()

        do {
            _ = try await pipeline.beginSession(importedImageData: [])
            XCTFail("Expected emptySession error")
        } catch let error as CapturePipelineError {
            XCTAssertEqual(error, .emptySession)
        }

        do {
            _ = try await pipeline.beginSession(importedImageData: Array(repeating: sample, count: 11))
            XCTFail("Expected tooManyPhotos error")
        } catch let error as CapturePipelineError {
            XCTAssertEqual(error, .tooManyPhotos(limit: 10))
        }

        var session = try await pipeline.beginSession(importedImageData: [sample, sample])
        XCTAssertEqual(session.pages.count, 2)
        XCTAssertEqual(session.totalBoxCount, 2)

        let page0ID = session.pages[0].id
        for _ in 0..<9 {
            session = try await pipeline.addBox(on: page0ID, rect: nil, in: session)
        }
        XCTAssertEqual(session.pages[0].boxes.count, 10)

        do {
            _ = try await pipeline.addBox(on: page0ID, rect: nil, in: session)
            XCTFail("Expected tooManyBoxesPerPage error")
        } catch let error as CapturePipelineError {
            XCTAssertEqual(error, .tooManyBoxesPerPage(limit: 10))
        }

        let preview = try await pipeline.buildSavePreview(for: session, mode: .autoAll)
        XCTAssertEqual(preview.questionCount, 11)
        XCTAssertEqual(preview.items.first?.pageIndex, 0)
        XCTAssertEqual(preview.items.first?.boxIndex, 0)
        XCTAssertEqual(preview.items.last?.pageIndex, 1)
        XCTAssertEqual(preview.items.last?.boxIndex, 0)
    }

    func testLivePipelineBeginSessionAndMultiBoxCropping() async throws {
        let pipeline = CapturePipelineLive(
            textRecognizer: { _ in "mock ocr" }
        )
        // Page contains colored ink strokes so .autoAll succeeds honestly while storing page metadata for re-crop
        let imgData = makeSolidImageData(color: .white, size: CGSize(width: 800, height: 600), drawRedStroke: true)

        var session = try await pipeline.beginSession(importedImageData: [imgData])
        let pageID = session.pages[0].id
        session = try await pipeline.addBox(
            on: pageID,
            rect: CGRect(x: 0.05, y: 0.55, width: 0.9, height: 0.35),
            in: session
        )

        let preview = try await pipeline.buildSavePreview(for: session, mode: .autoAll)
        XCTAssertEqual(preview.questionCount, 2)
        XCTAssertTrue(preview.items.allSatisfy { $0.handwritingRemovalSucceeded })
        XCTAssertTrue(preview.items.allSatisfy { $0.pageImageData != nil && $0.cropRectNormalized != nil })
        XCTAssertEqual(preview.items.first?.ocrText, "mock ocr")
    }

    func testLandscapeDocumentEdgeDetectionReturnsValidConvexQuad() async throws {
        let size = CGSize(width: 1200, height: 700)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        let landscapePhoto = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let cg = ctx.cgContext
            // Dark desk background
            UIColor(white: 0.14, alpha: 1.0).setFill()
            cg.fill(CGRect(origin: .zero, size: size))
            // Clear inset landscape paper sheet
            UIColor(red: 0.97, green: 0.96, blue: 0.94, alpha: 1.0).setFill()
            cg.fill(CGRect(x: 120, y: 90, width: 960, height: 520))
        }.jpegData(compressionQuality: 0.92)!

        let detector = DocumentEdgeDetector()
        let corners = await detector.detectCorners(in: landscapePhoto)
        XCTAssertTrue(corners.isConvexAndValid)
        XCTAssertGreaterThan(corners.topLeft.x, 0.04)
        XCTAssertLessThan(corners.topRight.x, 0.96)
    }

    func testSmartQuestionDetectorRunsOffMainActorAndRespectsTimeout() async {
        let size = CGSize(width: 600, height: 800)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        let sheetData = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }.jpegData(compressionQuality: 0.9)!

        // Immediate timeout gracefully falls back to a valid default crop box without blocking MainActor
        let tightTimeoutDetector = SmartQuestionDetector(timeoutSeconds: 0.0001)
        let timedOutBoxes = await tightTimeoutDetector.suggestBoxes(in: sheetData, maxBoxes: 10)
        XCTAssertEqual(timedOutBoxes.count, 1)

        // Normal timeout returns bounded valid crop boxes
        let normalDetector = SmartQuestionDetector(timeoutSeconds: 2.5)
        let boxes = await normalDetector.suggestBoxes(in: sheetData, maxBoxes: 10)
        XCTAssertFalse(boxes.isEmpty)
        XCTAssertLessThanOrEqual(boxes.count, 10)
    }
}
