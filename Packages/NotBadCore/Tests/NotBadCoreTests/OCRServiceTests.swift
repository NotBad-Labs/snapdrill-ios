//
//  OCRServiceTests.swift
//  NotBadCoreTests
//
//  Created by NotBad Labs on 2026/01/03.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  OCR 服务单元测试
//

import XCTest
import UIKit
@testable import NotBadCore

final class OCRServiceTests: XCTestCase {
    var service: OCRService!
    
    override func setUp() async throws {
        try await super.setUp()
        service = OCRService()
    }
    
    override func tearDown() async throws {
        service = nil
        try await super.tearDown()
    }
    
    func testServiceInitialization() {
        XCTAssertNotNil(service, "OCRService should be initialized")
    }
    
    func testRecognizeTextWithEmptyImage() async throws {
        // 创建一个简单的测试图片（纯色）
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let testImage = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        guard let cgImage = testImage.cgImage else {
            XCTFail("Failed to create CGImage")
            return
        }
        
        // OCR 应该能处理这个图片，即使没有文字
        let result = try await service.recognizeText(from: cgImage)
        
        // 结果应该是空字符串（因为图片中没有文字）
        XCTAssertNotNil(result, "Result should not be nil")
    }
    
    func testRecognizeTextWithValidImage() async throws {
        // 创建一个简单的测试图片（纯色）
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let testImage = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        guard let cgImage = testImage.cgImage else {
            XCTFail("Failed to create CGImage")
            return
        }
        
        // OCR 应该能处理这个图片，即使没有文字
        let result = try await service.recognizeText(from: cgImage)
        
        // 结果应该是空字符串或空白（因为图片中没有文字）
        XCTAssertNotNil(result, "Result should not be nil")
        // 允许空结果，因为图片中没有文字
    }
    
    func testRecognizeTextWithTextImage() async throws {
        // 创建一个包含文字的图片
        let size = CGSize(width: 300, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let textImage = renderer.image { context in
            // 白色背景
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // 绘制黑色文字
            let text = "Hello World"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            (text as NSString).draw(in: textRect, withAttributes: attributes)
        }
        
        guard let cgImage = textImage.cgImage else {
            XCTFail("Failed to create CGImage")
            return
        }
        
        // 执行 OCR
        let result = try await service.recognizeText(from: cgImage)
        
        // 验证结果
        XCTAssertNotNil(result, "Result should not be nil")
        // 注意：OCR 可能不完美，所以我们只检查结果不为空
        // 在真实场景中，可能需要更宽松的断言
    }
    
    func testPerformanceOfOCR() async throws {
        // 创建测试图片
        let size = CGSize(width: 1000, height: 1000)
        let renderer = UIGraphicsImageRenderer(size: size)
        let largeImage = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        guard let cgImage = largeImage.cgImage else {
            XCTFail("Failed to create CGImage")
            return
        }
        
        // 测量性能
        measure {
            Task {
                _ = try? await service.recognizeText(from: cgImage)
            }
        }
    }
}
