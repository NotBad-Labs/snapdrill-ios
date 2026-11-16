import Foundation
import Testing
import UIKit
@testable import SnapDrill

@Test func capturePipelineRejectsOverflowPhotos() async throws {
    let pipeline = CapturePipelineStub()
    let payload = Array(repeating: Data([0xFF, 0xD8, 0xFF]), count: 11)
    do {
        _ = try await pipeline.beginSession(importedImageData: payload)
        Issue.record("Expected tooManyPhotos")
    } catch CapturePipelineError.tooManyPhotos(let limit) {
        #expect(limit == 10)
    }
}

@Test func capturePipelineSavePreviewCountsBoxes() async throws {
    let pipeline = CapturePipelineStub()
    let data = tinyTestJPEGData()
    var session = try await pipeline.beginSession(importedImageData: [data])
    session = try await pipeline.addBox(on: session.pages[0].id, in: session)
    let preview = try await pipeline.buildSavePreview(for: session)
    #expect(preview.questionCount == 2)
}

private func tinyTestJPEGData() -> Data {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40))
    let image = renderer.image { ctx in
        UIColor.white.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
    }
    return image.jpegData(compressionQuality: 0.9) ?? Data()
}