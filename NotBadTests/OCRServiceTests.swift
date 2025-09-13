import XCTest
@testable import NotBad

final class VisionOCRServiceTests: XCTestCase {
    
    var ocrService: VisionOCRService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        ocrService = VisionOCRService()
    }
    
    override func tearDownWithError() throws {
        ocrService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Test Data Creation
    
    func createSampleImageData() -> Data {
        // 创建一个包含文字的简单测试图像
        let size = CGSize(width: 300, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // 白色背景
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // 添加黑色文字
            let text = "数学题：2 + 3 = ?"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            
            let textRect = CGRect(x: 20, y: 30, width: 260, height: 40)
            text.draw(in: textRect, withAttributes: attributes)
        }
        
        return image.jpegData(compressionQuality: 1.0) ?? Data()
    }
    
    func createInvalidImageData() -> Data {
        return "This is not image data".data(using: .utf8) ?? Data()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testRecognizeTextWithValidImage() async throws {
        // Given
        let imageData = createSampleImageData()
        
        // When
        let result = try await ocrService.recognizeText(from: imageData)
        
        // Then
        XCTAssertFalse(result.recognizedText.isEmpty, "识别出的文字不应为空")
        XCTAssertGreaterThan(result.confidence, 0.0, "置信度应大于0")
        XCTAssertGreaterThan(result.metadata.processingTime, 0, "处理时间应大于0")
        XCTAssertEqual(result.metadata.language, "zh-Hans", "语言应为中文简体")
    }
    
    func testRecognizeTextWithInvalidImageData() async {
        // Given
        let invalidData = createInvalidImageData()
        
        // When & Then
        do {
            _ = try await ocrService.recognizeText(from: invalidData)
            XCTFail("应该抛出错误")
        } catch let error as OCRError {
            XCTAssertEqual(error, .invalidImageData, "应该抛出图片数据无效错误")
        } catch {
            XCTFail("抛出了不期望的错误类型: \(error)")
        }
    }
    
    func testReprocessImageFunctionality() async throws {
        // Given
        let imageData = createSampleImageData()
        
        // When
        let results = try await ocrService.reprocessImage(imageData)
        
        // Then
        XCTAssertFalse(results.isEmpty, "重处理结果不应为空")
        XCTAssertGreaterThanOrEqual(results.count, 1, "至少应有一个结果")
        
        // 验证每个结果都有效
        for result in results {
            XCTAssertFalse(result.recognizedText.isEmpty, "每个结果的文字都不应为空")
            XCTAssertGreaterThan(result.confidence, 0.0, "每个结果的置信度都应大于0")
        }
    }
    
    // MARK: - Validation Tests
    
    func testValidateResultWithValidData() {
        // Given
        let validResult = OCRResult(
            recognizedText: "有效的识别文字",
            confidence: 0.8,
            boundingBoxes: [],
            metadata: OCRMetadata()
        )
        
        // When
        let isValid = ocrService.validateResult(validResult)
        
        // Then
        XCTAssertTrue(isValid, "有效结果应通过验证")
    }
    
    func testValidateResultWithLowConfidence() {
        // Given
        let lowConfidenceResult = OCRResult(
            recognizedText: "低置信度文字",
            confidence: 0.3, // 低于最小阈值
            boundingBoxes: [],
            metadata: OCRMetadata()
        )
        
        // When
        let isValid = ocrService.validateResult(lowConfidenceResult)
        
        // Then
        XCTAssertFalse(isValid, "低置信度结果不应通过验证")
    }
    
    func testValidateResultWithEmptyText() {
        // Given
        let emptyTextResult = OCRResult(
            recognizedText: "   ", // 空白文字
            confidence: 0.9,
            boundingBoxes: [],
            metadata: OCRMetadata()
        )
        
        // When
        let isValid = ocrService.validateResult(emptyTextResult)
        
        // Then
        XCTAssertFalse(isValid, "空文字结果不应通过验证")
    }
    
    // MARK: - Language Support Tests
    
    func testGetSupportedLanguages() {
        // When
        let languages = ocrService.getSupportedLanguages()
        
        // Then
        XCTAssertFalse(languages.isEmpty, "支持的语言列表不应为空")
        XCTAssertTrue(languages.contains("zh-Hans"), "应支持简体中文")
        XCTAssertTrue(languages.contains("en-US"), "应支持英文")
    }
    
    // MARK: - Error Handling Tests
    
    func testOCRErrorCases() {
        // Test all OCR error cases
        let allErrors = OCRError.allCases
        
        for error in allErrors {
            XCTAssertFalse(error.localizedDescription.isEmpty, 
                          "错误 \(error) 应有本地化描述")
        }
        
        // Test specific error descriptions
        XCTAssertEqual(OCRError.invalidImage.localizedDescription, "图像格式无效或损坏")
        XCTAssertEqual(OCRError.recognitionFailed.localizedDescription, "文字识别失败")
        XCTAssertEqual(OCRError.lowConfidence.localizedDescription, "识别置信度过低")
    }
    
    // MARK: - OCR Result Model Tests
    
    func testOCRResultInitialization() {
        // Test with minimal parameters
        let minimalResult = OCRResult(
            recognizedText: "测试文字",
            confidence: 0.75
        )
        
        XCTAssertEqual(minimalResult.recognizedText, "测试文字")
        XCTAssertEqual(minimalResult.confidence, 0.75)
        XCTAssertTrue(minimalResult.boundingBoxes.isEmpty)
        
        // Test with full parameters
        let textBlock = OCRTextBlock(
            text: "块文字",
            confidence: 0.8,
            boundingBox: CGRect(x: 0, y: 0, width: 100, height: 50),
            range: NSRange(location: 0, length: 3)
        )
        
        let fullResult = OCRResult(
            recognizedText: "完整测试",
            confidence: 0.9,
            boundingBoxes: [textBlock],
            metadata: OCRMetadata(language: "zh-Hant")
        )
        
        XCTAssertEqual(fullResult.boundingBoxes.count, 1)
        XCTAssertEqual(fullResult.metadata.language, "zh-Hant")
    }
    
    func testOCRTextBlockProperties() {
        // Given
        let boundingBox = CGRect(x: 10, y: 20, width: 150, height: 30)
        let range = NSRange(location: 0, length: 5)
        
        // When
        let textBlock = OCRTextBlock(
            text: "测试块",
            confidence: 0.85,
            boundingBox: boundingBox,
            range: range
        )
        
        // Then
        XCTAssertEqual(textBlock.text, "测试块")
        XCTAssertEqual(textBlock.confidence, 0.85)
        XCTAssertEqual(textBlock.boundingBox, boundingBox)
        XCTAssertEqual(textBlock.range, range)
    }
    
    func testOCRMetadataDefaults() {
        // When
        let metadata = OCRMetadata()
        
        // Then
        XCTAssertEqual(metadata.processingTime, 0)
        XCTAssertEqual(metadata.imageSize, .zero)
        XCTAssertEqual(metadata.language, "zh-Hans")
        
        // Processing time should be recent
        let timeDifference = abs(metadata.processedAt.timeIntervalSinceNow)
        XCTAssertLessThan(timeDifference, 1.0, "处理时间应该是当前时间")
    }
    
    // MARK: - Performance Tests
    
    func testOCRPerformance() throws {
        let imageData = createSampleImageData()
        
        measure {
            let expectation = XCTestExpectation(description: "OCR Performance")
            
            Task {
                do {
                    _ = try await ocrService.recognizeText(from: imageData)
                    expectation.fulfill()
                } catch {
                    XCTFail("性能测试中出现错误: \(error)")
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
}
