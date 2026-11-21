import ImageIO
import UIKit
import XCTest
@testable import SnapDrill

final class CapturePipelineContractTests: XCTestCase {
    private func makeSolidImageData(color: UIColor = .white, size: CGSize = CGSize(width: 400, height: 300)) -> Data {
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
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
        let imgData = makeSolidImageData(color: .white, size: CGSize(width: 800, height: 600))

        var session = try await pipeline.beginSession(importedImageData: [imgData])
        let pageID = session.pages[0].id
        session = try await pipeline.addBox(
            on: pageID,
            rect: CGRect(x: 0.1, y: 0.55, width: 0.8, height: 0.35),
            in: session
        )

        let preview = try await pipeline.buildSavePreview(for: session, mode: .autoAll)
        XCTAssertEqual(preview.questionCount, 2)
        XCTAssertTrue(preview.items.allSatisfy { $0.handwritingRemovalSucceeded })
        XCTAssertEqual(preview.items.first?.ocrText, "mock ocr")
    }
}
