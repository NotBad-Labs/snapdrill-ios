import Testing
import UIKit
@testable import SnapDrill

@Test func mistakeImageStoreRoundTrip() throws {
    let jpeg = tinyTestJPEGData()
    let relative = try MistakeImageStore.writeJPEG(jpeg, fileName: "roundtrip-test.jpg")
    let loaded = MistakeImageStore.loadImage(relativePath: relative)
    #expect(loaded != nil)
    let url = try MistakeImageStore.fileURL(relativePath: relative)
    try? FileManager.default.removeItem(at: url)
}

private func tinyTestJPEGData() -> Data {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24))
    let image = renderer.image { ctx in
        UIColor.orange.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 24, height: 24))
    }
    return image.jpegData(compressionQuality: 0.85) ?? Data()
}