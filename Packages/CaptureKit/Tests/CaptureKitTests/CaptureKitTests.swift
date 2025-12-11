import XCTest
import Vision
@testable import CaptureKit

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

// MARK: - ImageStorageService Tests

final class ImageStorageServiceTests: XCTestCase {
    
    var storage: ImageStorageService!
    
    override func setUp() async throws {
        try await super.setUp()
        storage = ImageStorageService(
            directoryProvider: { FileManager.default.temporaryDirectory },
            subdirectory: "TestImages",
            maxCacheSize: 5  // 测试用小容量缓存
        )
        await storage.clearAll()
    }
    
    override func tearDown() async throws {
        await storage?.clearAll()
        storage = nil
        try await super.tearDown()
    }
    
    // MARK: - Save & Load Data
    
    func testSaveAndLoadData() async throws {
        let id = UUID()
        let testData = "Hello, CaptureKit!".data(using: .utf8)!
        
        let fileName = try await storage.saveData(testData, id: id)
        XCTAssertEqual(fileName, "\(id.uuidString).jpg")
        
        let loadedData = await storage.loadData(named: fileName)
        XCTAssertEqual(loadedData, testData)
    }
    
    func testSaveCreatesFile() async throws {
        let id = UUID()
        let testData = Data([0x00, 0x01, 0x02])
        
        let fileName = try await storage.saveData(testData, id: id)
        
        let exists = await storage.exists(named: fileName)
        XCTAssertTrue(exists)
    }
    
    // MARK: - Delete
    
    func testDelete() async throws {
        let id = UUID()
        let testData = Data([0x00])
        
        let fileName = try await storage.saveData(testData, id: id)
        let existsBefore = await storage.exists(named: fileName)
        XCTAssertTrue(existsBefore)
        
        await storage.deleteImage(named: fileName)
        let existsAfter = await storage.exists(named: fileName)
        XCTAssertFalse(existsAfter)
    }
    
    func testDeleteNonExistent() async {
        await storage.deleteImage(named: "nonexistent.jpg")
        await storage.deleteImage(named: nil)
        await storage.deleteImage(named: "")
    }
    
    func testBatchDelete() async throws {
        let ids = (0..<5).map { _ in UUID() }
        var fileNames: [String?] = []
        for id in ids {
            let name = try? await storage.saveData(Data([0x00]), id: id)
            fileNames.append(name)
        }
        
        await storage.deleteImages(named: fileNames)
        
        for fileName in fileNames {
            let exists = await storage.exists(named: fileName)
            XCTAssertFalse(exists)
        }
    }
    
    // MARK: - Exists & FileURL
    
    func testExistsReturnsFalseForNil() async {
        let nilCheck = await storage.exists(named: nil)
        let emptyCheck = await storage.exists(named: "")
        XCTAssertFalse(nilCheck)
        XCTAssertFalse(emptyCheck)
    }
    
    func testFileURL() async {
        let fileName = "test.jpg"
        let url = await storage.fileURL(for: fileName)
        
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.path.contains("TestImages"))
        XCTAssertTrue(url!.path.hasSuffix("test.jpg"))
    }
    
    func testFileURLNil() async {
        let nilURL = await storage.fileURL(for: nil)
        let emptyURL = await storage.fileURL(for: "")
        XCTAssertNil(nilURL)
        XCTAssertNil(emptyURL)
    }
    
    // MARK: - Load Edge Cases
    
    func testLoadNilFileName() async {
        let image = await storage.loadImage(named: nil)
        let data = await storage.loadData(named: nil)
        XCTAssertNil(image)
        XCTAssertNil(data)
    }
    
    func testLoadEmptyFileName() async {
        let image = await storage.loadImage(named: "")
        let data = await storage.loadData(named: "")
        XCTAssertNil(image)
        XCTAssertNil(data)
    }
    
    func testLoadNonExistent() async {
        let image = await storage.loadImage(named: "nonexistent.jpg")
        XCTAssertNil(image)
    }
    
    // MARK: - Stats
    
    func testTotalSize() async throws {
        let id = UUID()
        let testData = Data(repeating: 0x00, count: 1024)
        
        _ = try await storage.saveData(testData, id: id)
        
        let sizeDescription = await storage.formattedSize
        XCTAssertFalse(sizeDescription.isEmpty)
    }
    
    func testImageCount() async throws {
        let initialCount = await storage.imageCount
        XCTAssertEqual(initialCount, 0)
        
        for i in 0..<3 {
            _ = try await storage.saveData(Data([UInt8(i)]), id: UUID())
        }
        
        let finalCount = await storage.imageCount
        XCTAssertEqual(finalCount, 3)
    }
    
    func testFormattedSize() async {
        let formatted = await storage.formattedSize
        XCTAssertFalse(formatted.isEmpty)
    }
    
    // MARK: - Clear All
    
    func testClearAll() async throws {
        for _ in 0..<5 {
            _ = try await storage.saveData(Data([0x00]), id: UUID())
        }
        
        let before = await storage.imageCount
        XCTAssertEqual(before, 5)
        
        await storage.clearAll()
        
        let after = await storage.imageCount
        XCTAssertEqual(after, 0)
    }
    
    // MARK: - Thread Safety
    
    func testConcurrentAccess() async throws {
        let ids = (0..<20).map { _ in UUID() }
        let testStorage = self.storage!
        
        await withTaskGroup(of: String?.self) { group in
            for id in ids {
                group.addTask { @Sendable in
                    try? await testStorage.saveData(Data(repeating: 0x00, count: 100), id: id)
                }
            }
        }
        
        for id in ids {
            let exists = await storage.exists(named: "\(id.uuidString).jpg")
            XCTAssertTrue(exists)
        }
        
        await withTaskGroup(of: Void.self) { group in
            for id in ids {
                group.addTask { @Sendable in
                    await testStorage.deleteImage(named: "\(id.uuidString).jpg")
                }
            }
        }
        
        for id in ids {
            let exists = await storage.exists(named: "\(id.uuidString).jpg")
            XCTAssertFalse(exists)
        }
    }
    
    // MARK: - Cache Tests
    
    func testCacheFunctionality() async throws {
        let id = UUID()
        let testData = Data([0x01, 0x02, 0x03])
        
        // 第一次保存
        let fileName = try await storage.saveData(testData, id: id)
        
        // 第一次加载（从磁盘）
        let data1 = await storage.loadData(named: fileName)
        XCTAssertEqual(data1, testData)
        
        // 第二次加载（应该从缓存）
        let data2 = await storage.loadData(named: fileName)
        XCTAssertEqual(data2, testData)
    }
    
    func testCacheEviction() async throws {
        // 创建超过缓存容量的文件（容量为 5）
        var fileNames: [String] = []
        for i in 0..<7 {
            let id = UUID()
            let data = Data([UInt8(i)])
            let fileName = try await storage.saveData(data, id: id)
            fileNames.append(fileName)
            _ = await storage.loadData(named: fileName)  // 触发缓存
        }
        
        // 验证所有文件仍然可以加载（从磁盘）
        for fileName in fileNames {
            let data = await storage.loadData(named: fileName)
            XCTAssertNotNil(data)
        }
    }
    
    func testClearCache() async throws {
        let id = UUID()
        let testData = Data([0xFF])
        let fileName = try await storage.saveData(testData, id: id)
        
        // 加载到缓存
        _ = await storage.loadData(named: fileName)
        
        // 清空缓存
        await storage.clearCache()
        
        // 验证仍能从磁盘加载
        let data = await storage.loadData(named: fileName)
        XCTAssertEqual(data, testData)
    }
}

// MARK: - OCR Tests

final class OCRServiceTests: XCTestCase {
    
    // MARK: - OCRResult Tests
    
    func testOCRResultEmpty() {
        let result = OCRResult.empty
        
        XCTAssertTrue(result.text.isEmpty)
        XCTAssertTrue(result.lines.isEmpty)
        XCTAssertEqual(result.confidence, 0)
    }
    
    func testOCRResultConfidenceDescription() {
        let highConfidence = OCRResult(text: "test", lines: [], confidence: 0.95)
        XCTAssertEqual(highConfidence.confidenceDescription, "识别置信度很高")
        
        let goodConfidence = OCRResult(text: "test", lines: [], confidence: 0.8)
        XCTAssertEqual(goodConfidence.confidenceDescription, "识别置信度良好")
        
        let mediumConfidence = OCRResult(text: "test", lines: [], confidence: 0.6)
        XCTAssertEqual(mediumConfidence.confidenceDescription, "识别置信度一般")
        
        let lowConfidence = OCRResult(text: "test", lines: [], confidence: 0.3)
        XCTAssertEqual(lowConfidence.confidenceDescription, "识别置信度较低，建议检查")
    }
    
    func testOCRResultIsHighConfidence() {
        let high = OCRResult(text: "test", lines: [], confidence: 0.85)
        XCTAssertTrue(high.isHighConfidence)
        
        let low = OCRResult(text: "test", lines: [], confidence: 0.7)
        XCTAssertFalse(low.isHighConfidence)
    }
    
    // MARK: - OCRLine Tests
    
    func testOCRLineCreation() {
        let line = OCRLine(
            text: "测试文本",
            confidence: 0.9,
            boundingBox: CGRect(x: 0, y: 0, width: 1, height: 0.1)
        )
        
        XCTAssertEqual(line.text, "测试文本")
        XCTAssertEqual(line.confidence, 0.9)
        XCTAssertEqual(line.boundingBox.width, 1)
    }
    
    // MARK: - OCRError Tests
    
    func testOCRErrorDescriptions() {
        XCTAssertNotNil(OCRError.invalidImage.errorDescription)
        XCTAssertNotNil(OCRError.recognitionFailed.errorDescription)
        XCTAssertNotNil(OCRError.noTextFound.errorDescription)
        XCTAssertNotNil(OCRError.timeout.errorDescription)
    }
    
    func testOCRErrorRecoverySuggestions() {
        XCTAssertNotNil(OCRError.invalidImage.recoverySuggestion)
        XCTAssertNotNil(OCRError.recognitionFailed.recoverySuggestion)
        XCTAssertNotNil(OCRError.noTextFound.recoverySuggestion)
        XCTAssertNotNil(OCRError.timeout.recoverySuggestion)
    }
    
    // MARK: - Text Extraction Tests
    
    func testExtractTitle() {
        let service = OCRService()
        
        let title1 = service.extractTitle(from: "第一行标题\n第二行内容")
        XCTAssertEqual(title1, "第一行标题")
        
        let title2 = service.extractTitle(from: "")
        XCTAssertEqual(title2, "未命名错题")
        
        let title3 = service.extractTitle(from: "   \n  ")
        XCTAssertEqual(title3, "未命名错题")
        
        let longText = String(repeating: "测", count: 100)
        let title4 = service.extractTitle(from: longText)
        XCTAssertEqual(title4.count, 50)
    }
    
    func testExtractMathExpressions() {
        let service = OCRService()
        
        let text = "计算 1+2=3 和 x^2 的值，还有 √4 和 1/2"
        let expressions = service.extractMathExpressions(from: text)
        
        XCTAssertTrue(expressions.contains("1+2"))
        XCTAssertTrue(expressions.contains("x^2"))
        XCTAssertTrue(expressions.contains("√4"))
        XCTAssertTrue(expressions.contains("1/2"))
    }
    
    // MARK: - Service Configuration Tests
    
    func testServiceCustomConfiguration() async {
        let service = OCRService(
            recognitionLevel: .fast,
            languages: ["en-US"],
            usesLanguageCorrection: false,
            timeout: 10
        )
        
        let level = await service.recognitionLevel
        let languages = await service.recognitionLanguages
        let correction = await service.usesLanguageCorrection
        let timeout = await service.timeout
        
        XCTAssertEqual(level, .fast)
        XCTAssertEqual(languages, ["en-US"])
        XCTAssertFalse(correction)
        XCTAssertEqual(timeout, 10)
    }
    
    func testServiceDefaultConfiguration() async {
        let service = OCRService.shared
        
        let level = await service.recognitionLevel
        let languages = await service.recognitionLanguages
        let correction = await service.usesLanguageCorrection
        
        XCTAssertEqual(level, .accurate)
        XCTAssertEqual(languages, ["zh-Hans", "zh-Hant", "en-US"])
        XCTAssertTrue(correction)
    }
    
    // MARK: - Thread Safety Tests
    
    func testServiceIsThreadSafe() async {
        let service = OCRService()
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    await service.setRecognitionLevel(i % 2 == 0 ? .accurate : .fast)
                    _ = await service.recognitionLevel
                }
            }
        }
        
        XCTAssertTrue(true)
    }
}

extension OCRService {
    func setRecognitionLevel(_ level: VNRequestTextRecognitionLevel) {
        self.recognitionLevel = level
    }
}

// MARK: - CaptureService Tests

final class CaptureServiceTests: XCTestCase {
    
    func testCaptureServiceSharedInstance() {
        let service = CaptureService.shared
        XCTAssertNotNil(service)
    }
    
    func testCaptureResultCreation() {
        let result = CaptureResult(
            text: "测试内容",
            ocrResult: OCRResult(text: "测试内容", lines: [], confidence: 0.9),
            imageFileName: "test.jpg",
            suggestedTitle: "测试标题"
        )
        
        XCTAssertEqual(result.text, "测试内容")
        XCTAssertEqual(result.imageFileName, "test.jpg")
        XCTAssertEqual(result.suggestedTitle, "测试标题")
        XCTAssertEqual(result.ocrResult.confidence, 0.9)
    }
    
    func testCaptureErrorDescriptions() {
        XCTAssertNotNil(CaptureError.invalidImage.errorDescription)
        XCTAssertNotNil(CaptureError.saveFailed.errorDescription)
        XCTAssertNotNil(CaptureError.ocrFailed(.noTextFound).errorDescription)
    }
    
    func testStorageStatistics() async {
        let service = CaptureService.shared
        
        // 这些属性应该可以访问
        let _ = await service.storageSize
        let _ = await service.imageCount
        
        XCTAssertTrue(true)
    }
}
