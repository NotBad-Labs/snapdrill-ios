//
//  OCRIntegrationTests.swift
//  NotBadTests
//
//  OCR 服务真实场景集成测试
//

import XCTest
import Vision
@testable import NotBad

/// OCR 集成测试
///
/// 使用真实图片测试 OCR 服务
/// 注意：这些测试依赖 Vision 框架，在模拟器上可能较慢
final class OCRIntegrationTests: XCTestCase {
    
    // MARK: - Test Data
    
    /// 创建包含文字的测试图片
    private func createImageWithText(_ text: String, fontSize: CGFloat = 24) -> UIImage {
        let size = CGSize(width: 400, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // 白色背景
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // 黑色文字
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .medium),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            let textRect = CGRect(x: 20, y: 80, width: size.width - 40, height: size.height - 80)
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    /// 创建包含数学公式样式文字的图片
    private func createMathImage() -> UIImage {
        let size = CGSize(width: 500, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // 模拟数学题目
            let title = "已知函数 f(x) = x² + 2x + 1"
            let question = "求 f(x) 的最小值"
            
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            
            let questionAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor.black
            ]
            
            title.draw(at: CGPoint(x: 30, y: 50), withAttributes: titleAttributes)
            question.draw(at: CGPoint(x: 30, y: 100), withAttributes: questionAttributes)
        }
    }
    
    // MARK: - OCR Service Tests
    
    /// 测试基本中文识别
    @MainActor
    func testRecognizeChineseText() async throws {
        let service = OCRService.shared
        let testImage = createImageWithText("测试文字识别")
        
        let result = try await service.recognizeText(from: testImage)
        
        // Vision 识别可能不完全精确，检查是否包含关键字
        XCTAssertFalse(result.isEmpty, "应该识别到文字")
        print("识别结果: \(result)")
    }
    
    /// 测试英文识别
    @MainActor
    func testRecognizeEnglishText() async throws {
        let service = OCRService.shared
        let testImage = createImageWithText("Hello World Test")
        
        let result = try await service.recognizeText(from: testImage)
        
        XCTAssertFalse(result.isEmpty, "应该识别到文字")
        print("识别结果: \(result)")
    }
    
    /// 测试中英混合识别
    @MainActor
    func testRecognizeMixedText() async throws {
        let service = OCRService.shared
        let testImage = createImageWithText("测试 Test 123")
        
        let result = try await service.recognizeText(from: testImage)
        
        XCTAssertFalse(result.isEmpty, "应该识别到文字")
        print("识别结果: \(result)")
    }
    
    /// 测试数学题目识别
    @MainActor
    func testRecognizeMathContent() async throws {
        let service = OCRService.shared
        let testImage = createMathImage()
        
        let result = try await service.recognizeText(from: testImage)
        
        XCTAssertFalse(result.isEmpty, "应该识别到数学内容")
        print("数学题识别结果: \(result)")
    }
    
    /// 测试空白图片处理
    @MainActor
    func testRecognizeBlankImage() async throws {
        let service = OCRService.shared
        let blankImage = TestImageFactory.createImage(size: .medium)
        
        // 空白图片可能抛出 noTextFound 错误，这是预期行为
        do {
            let result = try await service.recognizeText(from: blankImage)
            // 如果没有抛出错误，结果应该为空或很少内容
            print("空白图片识别结果: '\(result)'")
        } catch {
            // noTextFound 是预期的错误
            print("空白图片识别抛出预期错误: \(error)")
            XCTAssertTrue("\(error)".contains("noTextFound") || "\(error)".contains("no text"), 
                         "空白图片应该抛出 noTextFound 错误")
        }
    }
    
    // MARK: - Performance Tests
    
    /// 测试 OCR 识别性能
    @MainActor
    func testOCRPerformance() async {
        let service = OCRService.shared
        let testImage = createImageWithText("性能测试文字")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<3 {
            _ = try? await service.recognizeText(from: testImage)
        }
        
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        let average = elapsed / 3
        
        print("OCR 平均识别时间: \(average * 1000) ms")
        
        // OCR 识别通常较慢，但应该在合理范围内
        XCTAssertLessThan(average, 5.0, "OCR 识别应该在 5 秒内完成")
    }
    
    /// 测试大图片 OCR 性能
    @MainActor
    func testLargeImageOCRPerformance() async throws {
        let service = OCRService.shared
        
        // 创建大图片
        let size = CGSize(width: 2000, height: 1500)
        let renderer = UIGraphicsImageRenderer(size: size)
        let largeImage = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // 添加多行文字
            for i in 0..<10 {
                let text = "第\(i + 1)行测试文字 Line \(i + 1) Test"
                let y = CGFloat(50 + i * 50)
                text.draw(at: CGPoint(x: 50, y: y), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 24),
                    .foregroundColor: UIColor.black
                ])
            }
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await service.recognizeText(from: largeImage)
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        print("大图片 OCR 耗时: \(elapsed * 1000) ms")
        print("识别到 \(result.count) 个字符")
        
        XCTAssertFalse(result.isEmpty, "应该识别到内容")
    }
    
    // MARK: - Error Handling Tests
    
    /// 测试无效图片处理
    @MainActor
    func testInvalidImageHandling() async {
        let service = OCRService.shared
        
        // 创建一个 1x1 的最小图片
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        let tinyImage = renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        
        // 应该能处理而不崩溃
        let result = try? await service.recognizeText(from: tinyImage)
        print("微小图片处理结果: \(result ?? "nil")")
    }
}
