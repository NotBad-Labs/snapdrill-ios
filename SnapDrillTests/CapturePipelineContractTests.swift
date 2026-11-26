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
        let size = CGSize(width: 800, height: 1000)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        let sheetData = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .medium),
                .foregroundColor: UIColor.black
            ]
            NSString(string: "1. Calculate the derivative of f(x) = x^3 + 2x.").draw(at: CGPoint(x: 60, y: 120), withAttributes: attrs)
            NSString(string: "2. Solve the system: x + y = 7 and 2x - y = 2.").draw(at: CGPoint(x: 60, y: 580), withAttributes: attrs)
        }.jpegData(compressionQuality: 0.9)!

        // Immediate timeout gracefully falls back promptly without blocking on Vision perform
        let start = ContinuousClock.now
        let tightTimeoutDetector = SmartQuestionDetector(timeoutSeconds: 0.001)
        let timedOutBoxes = await tightTimeoutDetector.suggestBoxes(in: sheetData, maxBoxes: 10)
        let elapsed = ContinuousClock.now - start
        XCTAssertEqual(timedOutBoxes.count, 1)
        XCTAssertLessThan(elapsed, .seconds(0.8))

        // Normal timeout detects question clusters within normalized unit bounds
        let normalDetector = SmartQuestionDetector(timeoutSeconds: 2.5)
        let boxes = await normalDetector.suggestBoxes(in: sheetData, maxBoxes: 10)
        XCTAssertFalse(boxes.isEmpty)
        XCTAssertLessThanOrEqual(boxes.count, 10)
        for box in boxes {
            XCTAssertGreaterThanOrEqual(box.normalizedRect.minX, 0.0)
            XCTAssertGreaterThanOrEqual(box.normalizedRect.minY, 0.0)
            XCTAssertLessThanOrEqual(box.normalizedRect.maxX, 1.0)
            XCTAssertLessThanOrEqual(box.normalizedRect.maxY, 1.0)
        }
    }

    func testCaptureDraftStoreValidatesCorruptPreviewAndCleansStagingFiles() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("CaptureDraftStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = CaptureDraftStore(directoryURL: tempDir)
        let pageImg = makeSolidImageData(color: .white, size: CGSize(width: 200, height: 200), drawRedStroke: true)
        let page = CapturePage(rawImageData: pageImg)
        let item = CaptureSaveItem(
            id: page.boxes[0].id,
            pageIndex: 0,
            boxIndex: 0,
            originalImageData: pageImg,
            cleanedImageData: pageImg,
            handwritingRemovalSucceeded: true,
            ocrText: "Q1"
        )
        let session = CaptureSession(
            pages: [page],
            activeStep: 3,
            savedPreview: CaptureSavePreview(items: [item], inkRemovalMode: .autoAll)
        )

        try await store.saveDraft(session)

        // Corrupt cleaned preview asset with non-image bytes
        let cleanFile = tempDir
            .appendingPathComponent("assets", isDirectory: true)
            .appendingPathComponent("item-\(item.id.uuidString)-clean.bin")
        try Data([0x00, 0x01, 0x02]).write(to: cleanFile, options: [.atomic])

        let loaded = await store.loadDraft()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.activeStep, 2)
        XCTAssertNil(loaded?.savedPreview)
        XCTAssertEqual(loaded?.pages.count, 1)

        // Create leftover staging/tmp artifacts and verify clearDraft removes them
        let staleStaging = tempDir.appendingPathComponent("assets-staging-stale", isDirectory: true)
        try FileManager.default.createDirectory(at: staleStaging, withIntermediateDirectories: true)
        let staleTmp = tempDir.appendingPathComponent("pending_capture_draft-stale.tmp.json")
        try Data("{}".utf8).write(to: staleTmp)

        await store.clearDraft()
        XCTAssertFalse(FileManager.default.fileExists(atPath: staleStaging.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: staleTmp.path))
    }

    // MARK: - Live camera smoothing

    func testQuadSmootherStabilizesSteadyDetectionsAndResetsOnLoss() {
        let page = QuadCorners(
            topLeft: CGPoint(x: 0.1, y: 0.1),
            topRight: CGPoint(x: 0.9, y: 0.1),
            bottomRight: CGPoint(x: 0.9, y: 0.9),
            bottomLeft: CGPoint(x: 0.1, y: 0.9)
        )
        var smoother = QuadSmoother()
        XCTAssertFalse(smoother.isStable)

        for _ in 0..<5 {
            smoother.update(with: page)
        }
        XCTAssertFalse(smoother.isStable)
        smoother.update(with: page)
        XCTAssertTrue(smoother.isStable)

        // A large jump is blended (not snapped) and resets stability.
        var shifted = page
        shifted.topLeft.x += 0.2
        shifted.bottomLeft.x += 0.2
        smoother.update(with: shifted)
        XCTAssertFalse(smoother.isStable)
        let blendedX = smoother.currentQuad?.topLeft.x ?? 0
        XCTAssertGreaterThan(blendedX, 0.1)
        XCTAssertLessThan(blendedX, 0.3)

        // Losing the page for several frames clears the tracked quad.
        for _ in 0..<5 {
            smoother.update(with: nil)
        }
        XCTAssertNil(smoother.currentQuad)
        XCTAssertFalse(smoother.isStable)
    }

    func testTiledSegmentationPlannerCoversFullHighResImageWithOverlap() {
        let tiles = TiledInkSegmentationPlanner.planTiles(imageWidth: 1400, imageHeight: 900, tileSize: 512, overlap: 64)
        XCTAssertEqual(tiles.count, 6)

        var covered = [Bool](repeating: false, count: 1400 * 900)
        for tile in tiles {
            XCTAssertGreaterThanOrEqual(tile.pixelRect.minX, 0)
            XCTAssertGreaterThanOrEqual(tile.pixelRect.minY, 0)
            XCTAssertLessThanOrEqual(tile.pixelRect.maxX, 1400)
            XCTAssertLessThanOrEqual(tile.pixelRect.maxY, 900)
            XCTAssertEqual(tile.pixelRect.width, 512)
            XCTAssertEqual(tile.pixelRect.height, 512)
            for y in Int(tile.pixelRect.minY)..<Int(tile.pixelRect.maxY) {
                for x in Int(tile.pixelRect.minX)..<Int(tile.pixelRect.maxX) {
                    covered[y * 1400 + x] = true
                }
            }
        }
        XCTAssertTrue(covered.allSatisfy { $0 })

        let single = TiledInkSegmentationPlanner.planTiles(imageWidth: 400, imageHeight: 300)
        XCTAssertEqual(single.count, 1)
        XCTAssertEqual(single.first?.pixelRect, CGRect(x: 0, y: 0, width: 400, height: 300))

        // Interior seam weights fade toward tile borders; outer image edges stay fully weighted.
        let seam = TiledInkSegmentationPlanner.featherWeight(
            localX: 0, localY: 256, tileWidth: 512, tileHeight: 512, overlap: 64,
            isLeftEdge: false, isRightEdge: false, isTopEdge: true, isBottomEdge: true
        )
        let outer = TiledInkSegmentationPlanner.featherWeight(
            localX: 0, localY: 256, tileWidth: 512, tileHeight: 512, overlap: 64,
            isLeftEdge: true, isRightEdge: false, isTopEdge: true, isBottomEdge: true
        )
        XCTAssertLessThan(seam, 0.1)
        XCTAssertEqual(outer, 1.0, accuracy: 0.001)
    }

    func testSegmentationMaskCompositorErasesBlackHandwritingWhilePreservingBlackPrint() throws {
        let width = 300
        let height = 200
        let printedRect = CGRect(x: 30, y: 40, width: 200, height: 14)
        let handwrittenRect = CGRect(x: 30, y: 120, width: 200, height: 14)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { ctx in
            UIColor(red: 0.97, green: 0.96, blue: 0.94, alpha: 1).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
            UIColor(white: 0.05, alpha: 1).setFill()
            ctx.fill(printedRect)
            ctx.fill(handwrittenRect)
        }
        let cgImage = try XCTUnwrap(image.cgImage)

        var handwritingProb = [Float](repeating: 0, count: width * height)
        var printedProb = [Float](repeating: 0, count: width * height)
        for y in 0..<height {
            for x in 0..<width {
                let point = CGPoint(x: x, y: y)
                if printedRect.contains(point) {
                    printedProb[y * width + x] = 0.95
                } else if handwrittenRect.contains(point) {
                    handwritingProb[y * width + x] = 0.95
                }
            }
        }

        let result = try XCTUnwrap(
            SegmentationMaskCompositor.composite(
                source: cgImage,
                handwritingProb: handwritingProb,
                printedProb: printedProb
            )
        )
        XCTAssertGreaterThan(result.erasedPixelCount, 2000)

        let out = try XCTUnwrap(result.image.cgImage)
        func sample(_ x: Int, _ y: Int) -> (r: Int, g: Int, b: Int) {
            var pixel = [UInt8](repeating: 0, count: 4)
            let ctx = CGContext(
                data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            )!
            ctx.draw(out, in: CGRect(x: -x, y: -(out.height - 1 - y), width: out.width, height: out.height))
            return (Int(pixel[0]), Int(pixel[1]), Int(pixel[2]))
        }

        let erased = sample(120, 127)
        XCTAssertGreaterThan(erased.r, 220)
        XCTAssertGreaterThan(erased.g, 220)
        XCTAssertGreaterThan(erased.b, 220)

        let kept = sample(120, 47)
        XCTAssertLessThan(kept.r, 50)
        XCTAssertLessThan(kept.g, 50)
        XCTAssertLessThan(kept.b, 50)
    }
}
