import XCTest
@testable import OCRKit

final class OCRKitTests: XCTestCase {
    
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
    
    @MainActor
    func testExtractTitle() {
        let service = OCRService()
        
        // 正常情况
        let title1 = service.extractTitle(from: "第一行标题\n第二行内容")
        XCTAssertEqual(title1, "第一行标题")
        
        // 空文本
        let title2 = service.extractTitle(from: "")
        XCTAssertEqual(title2, "未命名错题")
        
        // 只有空白
        let title3 = service.extractTitle(from: "   \n  ")
        XCTAssertEqual(title3, "未命名错题")
        
        // 超长标题被截断
        let longText = String(repeating: "测", count: 100)
        let title4 = service.extractTitle(from: longText)
        XCTAssertEqual(title4.count, 50)
    }
    
    @MainActor
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
    
    @MainActor
    func testServiceCustomConfiguration() {
        let service = OCRService(
            recognitionLevel: .fast,
            languages: ["en-US"],
            usesLanguageCorrection: false
        )
        
        XCTAssertEqual(service.recognitionLevel, .fast)
        XCTAssertEqual(service.recognitionLanguages, ["en-US"])
        XCTAssertFalse(service.usesLanguageCorrection)
    }
    
    @MainActor
    func testServiceDefaultConfiguration() {
        let service = OCRService.shared
        
        XCTAssertEqual(service.recognitionLevel, .accurate)
        XCTAssertEqual(service.recognitionLanguages, ["zh-Hans", "zh-Hant", "en-US"])
        XCTAssertTrue(service.usesLanguageCorrection)
    }
}
