//
//  OCRServiceTests.swift
//  NotBadTests
//
//  Phase 6: OCR 服务测试
//

import Testing
import Foundation
import UIKit
@testable import NotBad

// MARK: - MockOCRService Tests

@Suite("MockOCRService 测试")
@MainActor
struct MockOCRServiceTests {
    
    // MARK: - 初始化测试
    
    @Test("初始状态正确")
    func initialState() {
        let service = MockOCRService()
        
        #expect(service.mockResult == "Mock recognized text")
        #expect(service.shouldThrowError == false)
        #expect(service.recognizeTextCallCount == 0)
        #expect(service.recognizeTextWithConfidenceCallCount == 0)
    }
    
    // MARK: - recognizeText 测试
    
    @Test("recognizeText 返回 Mock 结果")
    func recognizeTextReturnsMockResult() async throws {
        let service = MockOCRService()
        service.mockResult = "自定义识别结果"
        let image = UIImage()
        
        let result = try await service.recognizeText(from: image)
        
        #expect(result == "自定义识别结果")
        #expect(service.recognizeTextCallCount == 1)
        #expect(service.lastImage != nil)
    }
    
    @Test("recognizeText 可以触发错误")
    func recognizeTextCanThrowError() async {
        let service = MockOCRService()
        service.shouldThrowError = true
        service.errorToThrow = .recognitionFailed
        let image = UIImage()
        
        do {
            _ = try await service.recognizeText(from: image)
            Issue.record("应该抛出错误")
        } catch {
            #expect(error is OCRError)
        }
    }
    
    @Test("recognizeText 支持模拟延迟")
    func recognizeTextWithDelay() async throws {
        let service = MockOCRService()
        service.simulatedDelay = 0.1
        let image = UIImage()
        
        let start = Date()
        _ = try await service.recognizeText(from: image)
        let elapsed = Date().timeIntervalSince(start)
        
        #expect(elapsed >= 0.1)
    }
    
    // MARK: - recognizeTextWithConfidence 测试
    
    @Test("recognizeTextWithConfidence 返回 OCRResult")
    func recognizeTextWithConfidenceReturnsResult() async throws {
        let service = MockOCRService()
        let image = UIImage()
        
        let result = try await service.recognizeTextWithConfidence(from: image)
        
        #expect(result.confidence > 0)
        #expect(service.recognizeTextWithConfidenceCallCount == 1)
    }
    
    @Test("recognizeTextWithConfidence 可以自定义结果")
    func recognizeTextWithConfidenceCustomResult() async throws {
        let service = MockOCRService()
        let customResult = OCRResult(
            text: "自定义文本",
            lines: [OCRLine(text: "自定义文本", confidence: 0.99, boundingBox: .zero)],
            confidence: 0.99
        )
        service.mockResultWithConfidence = customResult
        let image = UIImage()
        
        let result = try await service.recognizeTextWithConfidence(from: image)
        
        #expect(result.text == "自定义文本")
        #expect(result.confidence == 0.99)
    }
    
    // MARK: - Reset 测试
    
    @Test("reset 重置所有状态")
    func resetClearsAllState() async throws {
        let service = MockOCRService()
        service.mockResult = "自定义"
        service.shouldThrowError = true
        service.simulatedDelay = 1.0
        
        let image = UIImage()
        service.shouldThrowError = false
        _ = try await service.recognizeText(from: image)
        
        service.reset()
        
        #expect(service.mockResult == "Mock recognized text")
        #expect(service.shouldThrowError == false)
        #expect(service.simulatedDelay == 0)
        #expect(service.recognizeTextCallCount == 0)
        #expect(service.lastImage == nil)
    }
}

// MARK: - OCRServiceProtocol Conformance Tests

@Suite("OCRServiceProtocol 协议测试")
@MainActor
struct OCRServiceProtocolTests {
    
    @Test("OCRService 符合 OCRServiceProtocol")
    func ocrServiceConformsToProtocol() {
        let service: any OCRServiceProtocol = OCRService.shared
        #expect(service is OCRService)
    }
    
    @Test("MockOCRService 符合 OCRServiceProtocol")
    func mockOCRServiceConformsToProtocol() {
        let service: any OCRServiceProtocol = MockOCRService()
        #expect(service is MockOCRService)
    }
    
    @Test("可以通过协议调用方法")
    func canCallMethodsThroughProtocol() async throws {
        let service: any OCRServiceProtocol = MockOCRService()
        let image = UIImage()
        
        let result = try await service.recognizeText(from: image)
        
        #expect(!result.isEmpty)
    }
}
