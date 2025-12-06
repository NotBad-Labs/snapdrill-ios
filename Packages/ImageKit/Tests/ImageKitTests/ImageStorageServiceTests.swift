import XCTest
@testable import ImageKit

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
}
