import Foundation
import Testing
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
@testable import ReviewKit

@Suite("ImageStorageService Tests")
struct ImageStorageServiceTests {
    
    @MainActor
    @Test("Save / load / delete image with custom container")
    func testSaveLoadDeleteImage() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReviewKitImageTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let config = ReviewKitConfiguration(
            appGroupIdentifier: "group.com.notbad.shared",
            databaseFileName: "Test.sqlite",
            imagesDirectoryName: "Images",
            customContainerURL: tempDir
        )
        let service = ImageStorageService(configuration: config)
        let image = makeTestImage()
        let id = UUID()
        
        let fileName = try await service.saveImage(image, for: id)
        let loaded = await service.loadImage(named: fileName)
        #expect(loaded != nil)
        
        // Add a small delay to ensure file system metadata is updated
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        let exists = await service.imageExists(named: fileName)
        #expect(exists)
        
        await service.deleteImage(named: fileName)
        let existsAfter = await service.imageExists(named: fileName)
        #expect(existsAfter == false)
    }
}

// MARK: - Helpers

private func makeTestImage() -> PlatformImage {
    #if canImport(UIKit)
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
    return renderer.image { context in
        UIColor.red.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
    }
    #elseif canImport(AppKit)
    let size = NSSize(width: 2, height: 2)
    let image = NSImage(size: size)
    image.lockFocus()
    NSColor.red.setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
    image.unlockFocus()
    return image
    #endif
}
