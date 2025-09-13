import XCTest
@testable import NotBad

final class OCRUseCaseTests: XCTestCase {
    
    var mockOCRService: MockOCRService!
    var processImageUseCase: ProcessImageUseCaseImpl!
    var reprocessImageUseCase: ReprocessImageUseCaseImpl!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockOCRService = MockOCRService()
        processImageUseCase = ProcessImageUseCaseImpl(ocrService: mockOCRService)
        reprocessImageUseCase = ReprocessImageUseCaseImpl(ocrService: mockOCRService)
    }
    
    override func tearDownWithError() throws {
        mockOCRService = nil
        processImageUseCase = nil
        reprocessImageUseCase = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Process Image Use Case Tests
    
    func testProcessImageWithHighQualityResult() async throws {
        // Given
        let imageData = Data("test image".utf8)
        let request = ProcessImageRequest(
            imageData: imageData,
            qualityThreshold: 0.7
        )
        
        mockOCRService.mockOCRResult = OCRResult(
            recognizedText: "数学题：2 + 3 = 5",
            confidence: 0.9,
            metadata: OCRMetadata(processingTime: 1.5)
        )
        
        // When
        let response = try await processImageUseCase.execute(request)
        
        // Then
        XCTAssertEqual(response.recognizedText, "数学题：2 + 3 = 5")
        XCTAssertEqual(response.confidence, 0.9)
        XCTAssertEqual(response.processingTime, 1.5)
        XCTAssertNil(response.suggestionForImprovement, "高质量结果不应有改进建议")
    }
    
    func testProcessImageWithLowQualityResult() async throws {
        // Given
        let imageData = Data("test image".utf8)
        let request = ProcessImageRequest(
            imageData: imageData,
            qualityThreshold: 0.7
        )
        
        mockOCRService.mockOCRResult = OCRResult(
            recognizedText: "数学题：2 + 3 =",
            confidence: 0.4,
            metadata: OCRMetadata(processingTime: 2.0)
        )
        
        // When
        let response = try await processImageUseCase.execute(request)
        
        // Then
        XCTAssertEqual(response.recognizedText, "数学题：2 + 3 =")
        XCTAssertEqual(response.confidence, 0.4)
        XCTAssertNotNil(response.suggestionForImprovement, "低质量结果应有改进建议")
        XCTAssertTrue(response.suggestionForImprovement?.contains("建议") ?? false)
    }
    
    func testProcessImageWithVeryLowConfidence() async throws {
        // Given
        let imageData = Data("test image".utf8)
        let request = ProcessImageRequest(imageData: imageData)
        
        mockOCRService.mockOCRResult = OCRResult(
            recognizedText: "???",
            confidence: 0.2,
            metadata: OCRMetadata(processingTime: 1.0)
        )
        
        // When
        let response = try await processImageUseCase.execute(request)
        
        // Then
        XCTAssertEqual(response.confidence, 0.2)
        XCTAssertNotNil(response.suggestionForImprovement)
        XCTAssertTrue(response.suggestionForImprovement?.contains("重新拍照") ?? false)
    }
    
    // MARK: - Reprocess Image Use Case Tests
    
    func testReprocessImageWithMultipleResults() async throws {
        // Given
        let imageData = Data("test image".utf8)
        let request = ReprocessImageRequest(
            imageData: imageData,
            userFeedback: "识别不准确"
        )
        
        mockOCRService.mockReprocessResults = [
            OCRResult(
                recognizedText: "数学题：2 + 3 = 5",
                confidence: 0.8,
                metadata: OCRMetadata(processingTime: 1.0, language: "zh-Hans")
            ),
            OCRResult(
                recognizedText: "数学题：2 + 3 = 5",
                confidence: 0.9,
                metadata: OCRMetadata(processingTime: 1.2, language: "zh-Hans_contrast_enhanced")
            ),
            OCRResult(
                recognizedText: "Math: 2 + 3 = 5",
                confidence: 0.7,
                metadata: OCRMetadata(processingTime: 1.1, language: "zh-Hans_grayscale")
            )
        ]
        
        // When
        let response = try await reprocessImageUseCase.execute(request)
        
        // Then
        XCTAssertEqual(response.results.count, 3, "应有3个处理结果")
        XCTAssertNotNil(response.recommendedResult, "应有推荐结果")
        XCTAssertEqual(response.recommendedResult?.confidence, 0.9, "推荐结果应是置信度最高的")
        XCTAssertFalse(response.improvementSuggestions.isEmpty, "应有改进建议")
    }
    
    func testReprocessImageWithUserFeedback() async throws {
        // Given
        let imageData = Data("test image".utf8)
        let request = ReprocessImageRequest(
            imageData: imageData,
            userFeedback: "图片很模糊，漏掉了一些文字"
        )
        
        mockOCRService.mockReprocessResults = [
            OCRResult(
                recognizedText: "部分文字",
                confidence: 0.5,
                metadata: OCRMetadata(processingTime: 1.0)
            )
        ]
        
        // When
        let response = try await reprocessImageUseCase.execute(request)
        
        // Then
        XCTAssertFalse(response.improvementSuggestions.isEmpty)
        
        let suggestionsText = response.improvementSuggestions.joined(separator: " ")
        XCTAssertTrue(suggestionsText.contains("模糊") || suggestionsText.contains("光线"), 
                     "应包含关于模糊的建议")
        XCTAssertTrue(suggestionsText.contains("分段") || suggestionsText.contains("漏掉"), 
                     "应包含关于漏掉文字的建议")
    }
    
    func testReprocessImageWithNoUserFeedback() async throws {
        // Given
        let imageData = Data("test image".utf8)
        let request = ReprocessImageRequest(imageData: imageData)
        
        mockOCRService.mockReprocessResults = [
            OCRResult(
                recognizedText: "完整的文字识别",
                confidence: 0.8,
                metadata: OCRMetadata(processingTime: 1.0)
            )
        ]
        
        // When
        let response = try await reprocessImageUseCase.execute(request)
        
        // Then
        XCTAssertFalse(response.improvementSuggestions.isEmpty, "即使没有用户反馈也应有通用建议")
    }
    
    // MARK: - Error Handling Tests
    
    func testProcessImageWithOCRError() async {
        // Given
        let request = ProcessImageRequest(imageData: Data())
        mockOCRService.shouldThrowError = true
        mockOCRService.errorToThrow = OCRError.invalidImage
        
        // When & Then
        do {
            _ = try await processImageUseCase.execute(request)
            XCTFail("应该抛出错误")
        } catch let error as OCRError {
            XCTAssertEqual(error, .invalidImageData)
        } catch {
            XCTFail("抛出了不期望的错误类型")
        }
    }
    
    func testReprocessImageWithOCRError() async {
        // Given
        let request = ReprocessImageRequest(imageData: Data())
        mockOCRService.shouldThrowError = true
        mockOCRService.errorToThrow = OCRError.recognitionFailed
        
        // When & Then
        do {
            _ = try await reprocessImageUseCase.execute(request)
            XCTFail("应该抛出错误")
        } catch let error as OCRError {
            XCTAssertEqual(error, .recognitionFailed)
        } catch {
            XCTFail("抛出了不期望的错误类型")
        }
    }
}

// MARK: - Mock OCR Service
final class MockOCRService: OCRServiceProtocol {
    
    var mockOCRResult: OCRResult?
    var mockReprocessResults: [OCRResult] = []
    var shouldThrowError = false
    var errorToThrow: Error = OCRError.recognitionFailed
    
    func recognizeText(from imageData: Data) async throws -> OCRResult {
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockOCRResult ?? OCRResult(
            recognizedText: "默认识别文字",
            confidence: 0.75
        )
    }
    
    func reprocessImage(_ imageData: Data) async throws -> [OCRResult] {
        if shouldThrowError {
            throw errorToThrow
        }
        
        if mockReprocessResults.isEmpty {
            return [
                OCRResult(recognizedText: "重处理结果1", confidence: 0.8),
                OCRResult(recognizedText: "重处理结果2", confidence: 0.7)
            ]
        }
        
        return mockReprocessResults
    }
    
    func validateResult(_ result: OCRResult) -> Bool {
        return result.confidence >= 0.5 && !result.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func getSupportedLanguages() -> [String] {
        return ["zh-Hans", "zh-Hant", "en-US"]
    }
}
