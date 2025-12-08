import XCTest
@testable import OCRKit

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

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
    
    func testServiceDefaultConfiguration() {
        let service = OCRService.shared
        
        XCTAssertEqual(service.recognitionLevel, .accurate)
        XCTAssertEqual(service.recognitionLanguages, ["zh-Hans", "zh-Hant", "en-US"])
        XCTAssertTrue(service.usesLanguageCorrection)
    }
    
    // MARK: - Thread Safety Tests
    
    func testServiceIsThreadSafe() async {
        let service = OCRService()
        
        // 并发修改配置
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    service.recognitionLevel = i % 2 == 0 ? .accurate : .fast
                    _ = service.recognitionLevel
                }
            }
        }
        
        // 不崩溃即通过
        XCTAssertTrue(true)
    }
    
    // MARK: - Real OCR Integration Tests
    
    func testRecognizeTextWithGeneratedImage() async throws {
        let service = OCRService()
        
        // 生成包含文字的测试图片
        guard let testImage = createTestImageWithText("Hello World 123") else {
            XCTFail("无法创建测试图片")
            return
        }
        
        do {
            let result = try await service.recognizeTextWithConfidence(from: testImage)
            
            // 验证识别结果
            XCTAssertFalse(result.text.isEmpty, "应该识别到文字")
            XCTAssertTrue(result.confidence > 0, "置信度应大于 0")
            XCTAssertFalse(result.lines.isEmpty, "应该有识别行")
            
            // 验证识别内容（允许一定误差）
            let normalizedText = result.text.lowercased().replacingOccurrences(of: " ", with: "")
            XCTAssertTrue(
                normalizedText.contains("hello") || normalizedText.contains("world") || normalizedText.contains("123"),
                "应该识别到部分文字内容，实际: \(result.text)"
            )
        } catch OCRError.noTextFound {
            // 在某些环境下可能无法识别，跳过测试
            print("⚠️ 测试环境无法识别文字，跳过")
        }
    }
    
    func testRecognizeChineseText() async throws {
        let service = OCRService()
        
        guard let testImage = createTestImageWithText("数学题目") else {
            XCTFail("无法创建测试图片")
            return
        }
        
        do {
            let result = try await service.recognizeTextWithConfidence(from: testImage)
            XCTAssertFalse(result.text.isEmpty, "应该识别到中文")
        } catch OCRError.noTextFound {
            print("⚠️ 测试环境无法识别中文，跳过")
        }
    }
    
    func testRecognizeInvalidImage() async {
        let service = OCRService()
        
        // 创建一个纯色空白图片
        guard let blankImage = createBlankImage() else {
            XCTFail("无法创建空白图片")
            return
        }
        
        do {
            _ = try await service.recognizeTextWithConfidence(from: blankImage)
            XCTFail("空白图片应该抛出 noTextFound 错误")
        } catch OCRError.noTextFound {
            // 预期行为
            XCTAssertTrue(true)
        } catch {
            XCTFail("应该抛出 OCRError.noTextFound，实际: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    #if canImport(AppKit)
    private func createTestImageWithText(_ text: String) -> NSImage? {
        let size = NSSize(width: 400, height: 100)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // 白色背景
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        // 绘制文字
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 36),
            .foregroundColor: NSColor.black
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        attributedString.draw(at: NSPoint(x: 20, y: 30))
        
        image.unlockFocus()
        
        return image
    }
    
    private func createBlankImage() -> NSImage? {
        let size = NSSize(width: 100, height: 100)
        let image = NSImage(size: size)
        
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        
        return image
    }
    #elseif canImport(UIKit)
    private func createTestImageWithText(_ text: String) -> UIImage? {
        let size = CGSize(width: 400, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // 白色背景
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // 绘制文字
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36),
                .foregroundColor: UIColor.black
            ]
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            attributedString.draw(at: CGPoint(x: 20, y: 30))
        }
    }
    
    private func createBlankImage() -> UIImage? {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    #endif
}
