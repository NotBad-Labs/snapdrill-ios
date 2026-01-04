//
//  PDFExportServiceTests.swift
//  NotBadCoreTests
//
//  Created by NotBad Architect on 2026/01/03.
//  Copyright © 2026 NotBad Team. All rights reserved.
//
//  PDF 导出服务单元测试
//

import XCTest
import UIKit
@testable import NotBadCore

final class PDFExportServiceTests: XCTestCase {
    var service: PDFExportService?
    
    override func setUp() {
        super.setUp()
        service = PDFExportService.shared
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    func testServiceInitialization() {
        guard let service = service else {
            XCTFail("Service should be initialized")
            return
        }
        XCTAssertNotNil(service, "PDFExportService should be initialized")
    }
    
    func testCreatePDFWithEmptyItems() {
        let emptyItems: [ReviewItem] = []
        
        let pdfData = service.createPDF(from: emptyItems) { _ in nil }
        
        // 即使没有项目，也应该生成 PDF（至少有标题页）
        XCTAssertNotNil(pdfData, "PDF data should be generated even with empty items")
        guard let data = pdfData else {
            XCTFail("PDF data should not be nil")
            return
        }
        XCTAssertFalse(data.isEmpty, "PDF data should not be empty")
    }
    
    func testCreatePDFWithSingleItem() {
        let testItem = ReviewItem(
            id: UUID(),
            content: "测试题目内容",
            subject: "数学",
            source: "期中考试",
            difficulty: 3,
            answerText: "测试答案",
            imagePath: nil,
            createdAt: Date(),
            lastReviewedAt: nil,
            nextReviewAt: Date()
        )
        
        let pdfData = service.createPDF(from: [testItem]) { _ in nil }
        
        XCTAssertNotNil(pdfData, "PDF data should be generated")
        guard let data = pdfData else {
            XCTFail("PDF data should not be nil")
            return
        }
        XCTAssertFalse(data.isEmpty, "PDF data should not be empty")
    }
    
    func testCreatePDFWithMultipleItems() {
        let items = (1...5).map { index in
            ReviewItem(
                id: UUID(),
                content: "测试题目 \(index)",
                subject: "数学",
                source: "测试",
                difficulty: index % 5 + 1,
                answerText: "答案 \(index)",
                imagePath: nil,
                createdAt: Date(),
                lastReviewedAt: nil,
                nextReviewAt: Date()
            )
        }
        
        let pdfData = service.createPDF(from: items) { _ in nil }
        
        XCTAssertNotNil(pdfData, "PDF data should be generated")
        guard let data = pdfData else {
            XCTFail("PDF data should not be nil")
            return
        }
        XCTAssertFalse(data.isEmpty, "PDF data should not be empty")
        // PDF 应该比单个项目的更大
    }
    
    func testCreatePDFWithImage() {
        // 创建测试图片
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let testImage = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        let testItem = ReviewItem(
            id: UUID(),
            content: "带图片的题目",
            subject: "物理",
            source: "测试",
            difficulty: 3,
            answerText: "答案",
            imagePath: "test_image.jpg",
            createdAt: Date(),
            lastReviewedAt: nil,
            nextReviewAt: Date()
        )
        
        let pdfData = service.createPDF(from: [testItem]) { path in
            return path == "test_image.jpg" ? testImage : nil
        }
        
        XCTAssertNotNil(pdfData, "PDF with image should be generated")
        guard let data = pdfData else {
            XCTFail("PDF data should not be nil")
            return
        }
        XCTAssertFalse(data.isEmpty, "PDF data should not be empty")
    }
    
    func testPDFPerformance() {
        let items = (1...20).map { index in
            ReviewItem(
                id: UUID(),
                content: "性能测试题目 \(index) - 这是一个较长的题目内容，用于测试 PDF 生成性能",
                subject: "综合",
                source: "性能测试",
                difficulty: index % 5 + 1,
                answerText: "详细答案 \(index)",
                imagePath: nil,
                createdAt: Date(),
                lastReviewedAt: nil,
                nextReviewAt: Date()
            )
        }
        
        measure {
            _ = service.createPDF(from: items) { _ in nil }
        }
    }
}
