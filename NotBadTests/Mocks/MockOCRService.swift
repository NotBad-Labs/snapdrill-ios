//
//  MockOCRService.swift
//  NotBadTests
//
//  OCR 服务的 Mock 实现
//

import UIKit
@testable import NotBad

// MARK: - MockOCRService

/// OCR 服务的 Mock 实现
///
/// 用于单元测试，可以控制识别结果和错误情况。
///
/// ## 使用示例
///
/// ```swift
/// @Test("OCR 识别成功")
/// @MainActor
/// func testOCRSuccess() async {
///     let mock = MockOCRService()
///     mock.mockResult = "测试文本"
///     
///     let result = try await mock.recognizeText(from: UIImage())
///     
///     #expect(result == "测试文本")
/// }
/// ```
@MainActor
final class MockOCRService: OCRServiceProtocol {
    
    // MARK: - Mock Configuration
    
    /// 模拟的识别结果文本
    var mockResult: String = "Mock recognized text"
    
    /// 模拟的识别结果（带置信度）
    var mockResultWithConfidence: OCRResult?
    
    /// 是否应该抛出错误
    var shouldThrowError = false
    
    /// 要抛出的错误类型
    var errorToThrow: OCRError = .recognitionFailed
    
    /// 模拟的识别延迟（秒）
    var simulatedDelay: TimeInterval = 0
    
    // MARK: - Call Tracking
    
    /// recognizeText 被调用的次数
    var recognizeTextCallCount = 0
    
    /// recognizeTextWithConfidence 被调用的次数
    var recognizeTextWithConfidenceCallCount = 0
    
    /// 最后传入的图片
    var lastImage: UIImage?
    
    // MARK: - Recognition Methods
    
    /// 从图片中识别文字
    func recognizeText(from image: UIImage) async throws -> String {
        recognizeTextCallCount += 1
        lastImage = image
        
        // 模拟延迟
        if simulatedDelay > 0 {
            try? await Task.sleep(for: .seconds(simulatedDelay))
        }
        
        // 模拟错误
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockResult
    }
    
    /// 从图片中识别文字（带置信度）
    func recognizeTextWithConfidence(from image: UIImage) async throws -> OCRResult {
        recognizeTextWithConfidenceCallCount += 1
        lastImage = image
        
        // 模拟延迟
        if simulatedDelay > 0 {
            try? await Task.sleep(for: .seconds(simulatedDelay))
        }
        
        // 模拟错误
        if shouldThrowError {
            throw errorToThrow
        }
        
        // 返回自定义结果或默认结果
        return mockResultWithConfidence ?? OCRResult(
            text: mockResult,
            lines: [OCRLine(text: mockResult, confidence: 0.95, boundingBox: .zero)],
            confidence: 0.95
        )
    }
    
    // MARK: - Reset
    
    /// 重置所有状态
    func reset() {
        mockResult = "Mock recognized text"
        mockResultWithConfidence = nil
        shouldThrowError = false
        errorToThrow = .recognitionFailed
        simulatedDelay = 0
        recognizeTextCallCount = 0
        recognizeTextWithConfidenceCallCount = 0
        lastImage = nil
    }
}
