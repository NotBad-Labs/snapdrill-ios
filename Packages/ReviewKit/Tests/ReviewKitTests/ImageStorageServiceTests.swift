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
    
    @MainActor
    @Test("Cleanup orphaned images removes only unreferenced files")
    func testCleanupOrphanedImages() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReviewKitOrphanTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let config = ReviewKitConfiguration(customContainerURL: tempDir)
        let service = ImageStorageService(configuration: config)
        let image = makeTestImage()
        
        // 保存 3 张图片
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        
        _ = try await service.saveImage(image, for: id1)
        _ = try await service.saveImage(image, for: id2)
        _ = try await service.saveImage(image, for: id3)
        
        // 只保留 id1 和 id2
        let validIds: Set<UUID> = [id1, id2]
        let deletedCount = await service.cleanupOrphanedImages(validIds: validIds)
        
        #expect(deletedCount == 1) // id3 应该被删除
        
        let exists1 = await service.imageExists(named: "\(id1.uuidString).jpg")
        let exists2 = await service.imageExists(named: "\(id2.uuidString).jpg")
        let exists3 = await service.imageExists(named: "\(id3.uuidString).jpg")
        
        #expect(exists1 == true)
        #expect(exists2 == true)
        #expect(exists3 == false)
    }
    
    @MainActor
    @Test("Batch delete images")
    func testBatchDeleteImages() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReviewKitBatchTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let config = ReviewKitConfiguration(customContainerURL: tempDir)
        let service = ImageStorageService(configuration: config)
        let image = makeTestImage()
        
        // 保存多张图片
        let ids = (0..<5).map { _ in UUID() }
        for id in ids {
            _ = try await service.saveImage(image, for: id)
        }
        
        // 批量删除
        let fileNames = ids.map { "\($0.uuidString).jpg" }
        await service.deleteImages(named: fileNames)
        
        // 验证全部删除
        for id in ids {
            let exists = await service.imageExists(named: "\(id.uuidString).jpg")
            #expect(exists == false)
        }
    }
    
    @MainActor
    @Test("Image count and size calculation")
    func testImageCountAndSize() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReviewKitCountTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let config = ReviewKitConfiguration(customContainerURL: tempDir)
        let service = ImageStorageService(configuration: config)
        let image = makeTestImage()
        
        // 初始应为 0
        let initialCount = await service.imageCount
        #expect(initialCount == 0)
        
        // 保存 3 张图片
        for _ in 0..<3 {
            _ = try await service.saveImage(image, for: UUID())
        }
        
        let afterSave = await service.imageCount
        #expect(afterSave == 3)
        
        // 大小应大于 0
        let size = await service.formattedSize
        #expect(!size.isEmpty)
    }
    
    @MainActor
    @Test("Delete all images")
    func testDeleteAllImages() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReviewKitDeleteAllTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let config = ReviewKitConfiguration(customContainerURL: tempDir)
        let service = ImageStorageService(configuration: config)
        let image = makeTestImage()
        
        // 保存多张图片
        for _ in 0..<5 {
            _ = try await service.saveImage(image, for: UUID())
        }
        
        let beforeDelete = await service.imageCount
        #expect(beforeDelete == 5)
        
        // 删除全部
        await service.deleteAllImages()
        
        let afterDelete = await service.imageCount
        #expect(afterDelete == 0)
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
