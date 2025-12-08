import XCTest
@testable import ImageKit

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

final class ImageStorageServiceTests: XCTestCase {
    
    var storage: ImageStorageService!
    
    override func setUp() {
        super.setUp()
        // 使用测试专用目录
        storage = ImageStorageService(subdirectory: "TestImages")
    }
    
    override func tearDown() {
        // 清理测试数据
        storage.clearAll()
        super.tearDown()
    }
    
    // MARK: - Save & Load Data
    
    func testSaveAndLoadData() {
        let id = UUID()
        let testData = "Hello, ImageKit!".data(using: .utf8)!
        
        // 保存
        let fileName = storage.save(data: testData, with: id)
        XCTAssertNotNil(fileName)
        XCTAssertEqual(fileName, "\(id.uuidString).jpg")
        
        // 加载
        let loadedData = storage.loadData(fileName: fileName)
        XCTAssertNotNil(loadedData)
        XCTAssertEqual(loadedData, testData)
    }
    
    func testSaveCreatesFile() {
        let id = UUID()
        let testData = Data([0x00, 0x01, 0x02])
        
        let fileName = storage.save(data: testData, with: id)
        
        XCTAssertTrue(storage.exists(fileName: fileName))
    }
    
    // MARK: - Delete
    
    func testDelete() {
        let id = UUID()
        let testData = Data([0x00])
        
        let fileName = storage.save(data: testData, with: id)
        XCTAssertTrue(storage.exists(fileName: fileName))
        
        storage.delete(fileName: fileName)
        XCTAssertFalse(storage.exists(fileName: fileName))
    }
    
    func testDeleteNonExistent() {
        // 删除不存在的文件不应崩溃
        storage.delete(fileName: "nonexistent.jpg")
        storage.delete(fileName: nil)
        storage.delete(fileName: "")
    }
    
    func testBatchDelete() {
        let ids = (0..<5).map { _ in UUID() }
        let fileNames = ids.map { id in
            storage.save(data: Data([0x00]), with: id)
        }
        
        storage.delete(fileNames: fileNames)
        
        for fileName in fileNames {
            XCTAssertFalse(storage.exists(fileName: fileName))
        }
    }
    
    // MARK: - Exists & FileURL
    
    func testExistsReturnsFalseForNil() {
        XCTAssertFalse(storage.exists(fileName: nil))
        XCTAssertFalse(storage.exists(fileName: ""))
    }
    
    func testFileURL() {
        let fileName = "test.jpg"
        let url = storage.fileURL(for: fileName)
        
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.path.contains("TestImages"))
        XCTAssertTrue(url!.path.hasSuffix("test.jpg"))
    }
    
    func testFileURLNil() {
        XCTAssertNil(storage.fileURL(for: nil))
        XCTAssertNil(storage.fileURL(for: ""))
    }
    
    // MARK: - Load Edge Cases
    
    func testLoadNilFileName() {
        XCTAssertNil(storage.load(fileName: nil))
        XCTAssertNil(storage.loadData(fileName: nil))
    }
    
    func testLoadEmptyFileName() {
        XCTAssertNil(storage.load(fileName: ""))
        XCTAssertNil(storage.loadData(fileName: ""))
    }
    
    func testLoadNonExistent() {
        XCTAssertNil(storage.load(fileName: "nonexistent.jpg"))
    }
    
    // MARK: - Stats
    
    func testTotalSize() {
        let id = UUID()
        let testData = Data(repeating: 0x00, count: 1024) // 1KB
        
        _ = storage.save(data: testData, with: id)
        
        let size = storage.totalSize()
        XCTAssertGreaterThanOrEqual(size, 1024)
    }
    
    func testImageCount() {
        XCTAssertEqual(storage.imageCount, 0)
        
        for i in 0..<3 {
            _ = storage.save(data: Data([UInt8(i)]), with: UUID())
        }
        
        XCTAssertEqual(storage.imageCount, 3)
    }
    
    func testFormattedSize() {
        let formatted = storage.formattedSize
        XCTAssertFalse(formatted.isEmpty)
        // 应该返回类似 "0 bytes" 或 "Zero KB" 的格式
    }
    
    // MARK: - Clear All
    
    func testClearAll() {
        for _ in 0..<5 {
            _ = storage.save(data: Data([0x00]), with: UUID())
        }
        
        XCTAssertEqual(storage.imageCount, 5)
        
        storage.clearAll()
        
        XCTAssertEqual(storage.imageCount, 0)
    }
    
    // MARK: - Custom Subdirectory
    
    func testCustomSubdirectory() {
        let customStorage = ImageStorageService(subdirectory: "CustomImages")
        let id = UUID()
        
        let fileName = customStorage.save(data: Data([0x00]), with: id)
        
        XCTAssertTrue(customStorage.imagesDirectory.path.contains("CustomImages"))
        XCTAssertTrue(customStorage.exists(fileName: fileName))
        
        customStorage.clearAll()
    }
    
    // MARK: - Real Image Tests
    
    #if canImport(AppKit)
    func testSaveAndLoadRealImage() {
        let id = UUID()
        
        // 创建真实测试图片
        let size = NSSize(width: 200, height: 200)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.blue.setFill()
        NSRect(origin: .zero, size: size).fill()
        NSColor.white.setFill()
        NSRect(x: 50, y: 50, width: 100, height: 100).fill()
        image.unlockFocus()
        
        // 保存
        let fileName = storage.save(image: image, with: id)
        XCTAssertNotNil(fileName)
        
        // 加载
        let loaded = storage.load(fileName: fileName)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.size.width ?? 0, 200, accuracy: 1)
    }
    
    func testDownsampleLargeImage() {
        let id = UUID()
        
        // 创建超大图片 (3000x3000)
        let size = NSSize(width: 3000, height: 3000)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        
        // 保存（应该被降采样）
        let fileName = storage.save(image: image, with: id)
        XCTAssertNotNil(fileName)
        
        // 检查文件大小合理（降采样后应该小很多）
        if let fileURL = storage.fileURL(for: fileName),
           let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let fileSize = attributes[.size] as? Int {
            // 3000x3000 原图压缩后可能很大，降采样到 2048 后应该更小
            XCTAssertLessThan(fileSize, 5_000_000, "降采样后文件应该小于 5MB")
        }
    }
    #elseif canImport(UIKit)
    func testSaveAndLoadRealImage() {
        let id = UUID()
        
        // 创建真实测试图片
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor.white.setFill()
            context.fill(CGRect(x: 50, y: 50, width: 100, height: 100))
        }
        
        // 保存
        let fileName = storage.save(image: image, with: id)
        XCTAssertNotNil(fileName)
        
        // 加载
        let loaded = storage.load(fileName: fileName)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.size.width ?? 0, 200, accuracy: 1)
    }
    
    func testDownsampleLargeImage() {
        let id = UUID()
        
        // 创建超大图片 (3000x3000)
        let size = CGSize(width: 3000, height: 3000)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        // 保存（应该被降采样）
        let fileName = storage.save(image: image, with: id)
        XCTAssertNotNil(fileName)
        
        // 检查文件大小合理
        if let fileURL = storage.fileURL(for: fileName),
           let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let fileSize = attributes[.size] as? Int {
            XCTAssertLessThan(fileSize, 5_000_000, "降采样后文件应该小于 5MB")
        }
    }
    #endif
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentAccess() async {
        let ids = (0..<20).map { _ in UUID() }
        let testStorage = self.storage! // Capture locally for Sendable
        
        // 并发保存
        await withTaskGroup(of: String?.self) { group in
            for id in ids {
                group.addTask { @Sendable in
                    testStorage.save(data: Data(repeating: 0x00, count: 100), with: id)
                }
            }
        }
        
        // 验证所有文件都存在
        for id in ids {
            XCTAssertTrue(storage.exists(fileName: "\(id.uuidString).jpg"))
        }
        
        // 并发删除
        await withTaskGroup(of: Void.self) { group in
            for id in ids {
                group.addTask { @Sendable in
                    testStorage.delete(fileName: "\(id.uuidString).jpg")
                }
            }
        }
        
        // 验证所有文件都已删除
        for id in ids {
            XCTAssertFalse(storage.exists(fileName: "\(id.uuidString).jpg"))
        }
    }
}
