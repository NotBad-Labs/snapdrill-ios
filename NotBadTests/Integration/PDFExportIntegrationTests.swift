//
//  PDFExportIntegrationTests.swift
//  NotBadTests
//
//  PDF 导出服务真实场景集成测试
//

import XCTest
import PDFKit
@testable import NotBad

/// PDF 导出集成测试
///
/// 测试真实 PDF 生成功能
@MainActor
final class PDFExportIntegrationTests: XCTestCase {
    
    // MARK: - Properties
    
    private var service: PDFExportService!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        service = PDFExportService.shared
    }
    
    // MARK: - Basic Export Tests
    
    /// 测试导出空列表
    func testExportEmptyList() {
        let data = service.exportToPDF(items: [], title: "空测试")
        
        XCTAssertFalse(data.isEmpty, "应该生成 PDF 数据")
        XCTAssertTrue(isValidPDF(data), "应该是有效的 PDF")
        
        print("空列表 PDF 大小: \(data.count / 1024) KB")
    }
    
    /// 测试导出单个无图片条目

    func testExportSingleItemWithoutImage() {
        let item = TestReviewItemFactory.create(
            title: "测试题目：求一元二次方程的根",
            subject: .math
        )
        
        let data = service.exportToPDF(items: [item], title: "单题测试")
        
        XCTAssertFalse(data.isEmpty)
        XCTAssertTrue(isValidPDF(data))
        
        print("单条目 PDF 大小: \(data.count / 1024) KB")
    }
    
    /// 测试导出单个带图片条目

    func testExportSingleItemWithImage() {
        let item = TestReviewItemFactory.createWithImage(
            imageSize: .medium,
            title: "带图片的测试题目",
            subject: .physics
        )
        
        let data = service.exportToPDF(items: [item], title: "图片测试", includeImages: true)
        
        XCTAssertFalse(data.isEmpty)
        XCTAssertTrue(isValidPDF(data))
        
        print("带图片 PDF 大小: \(data.count / 1024) KB")
    }
    
    // MARK: - Batch Export Tests
    
    /// 测试导出 10 条记录

    func testExport10Items() {
        let items = TestReviewItemFactory.createMixedBatch(count: 10, imageRatio: 0.5)
        
        let data = service.exportToPDF(items: items, title: "10题测试卷")
        
        XCTAssertFalse(data.isEmpty)
        XCTAssertTrue(isValidPDF(data))
        
        // 验证 PDF 页数合理
        if let pdf = PDFDocument(data: data) {
            print("10 条记录生成 \(pdf.pageCount) 页 PDF")
            XCTAssertGreaterThanOrEqual(pdf.pageCount, 1)
        }
        
        print("10 条记录 PDF 大小: \(data.count / 1024) KB")
    }
    
    /// 测试导出 50 条记录

    func testExport50Items() {
        let items = TestReviewItemFactory.createMixedBatch(count: 50, imageRatio: 0.3)
        
        let data = service.exportToPDF(items: items, title: "50题综合测试")
        
        XCTAssertFalse(data.isEmpty)
        XCTAssertTrue(isValidPDF(data))
        
        if let pdf = PDFDocument(data: data) {
            print("50 条记录生成 \(pdf.pageCount) 页 PDF")
        }
        
        print("50 条记录 PDF 大小: \(data.count / 1024) KB")
    }
    
    /// 测试导出 100 条记录（压力测试）

    func testExport100Items() {
        let items = TestReviewItemFactory.createRealisticDataset(count: 100)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let data = service.exportToPDF(items: items, title: "期末复习大纲")
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertFalse(data.isEmpty)
        XCTAssertTrue(isValidPDF(data))
        
        if let pdf = PDFDocument(data: data) {
            print("100 条记录生成 \(pdf.pageCount) 页 PDF，耗时 \(elapsed * 1000) ms")
        }
        
        print("100 条记录 PDF 大小: \(data.count / 1024) KB")
        
        // 100 条数据导出应该在 10 秒内完成
        XCTAssertLessThan(elapsed, 10.0, "导出应该在 10 秒内完成")
    }
    
    // MARK: - Options Tests
    
    /// 测试不同导出选项

    func testExportWithDifferentOptions() {
        let items = TestReviewItemFactory.createBatchWithImages(count: 5, imageSize: .small)
        
        // 不含图片
        let dataWithoutImages = service.exportToPDF(
            items: items,
            title: "无图版",
            includeImages: false
        )
        
        // 含图片
        let dataWithImages = service.exportToPDF(
            items: items,
            title: "有图版",
            includeImages: true
        )
        
        // 含笔记和答题区
        let dataFull = service.exportToPDF(
            items: items,
            title: "完整版",
            includeImages: true,
            includeNotes: true,
            showAnswerArea: true
        )
        
        print("无图版: \(dataWithoutImages.count / 1024) KB")
        print("有图版: \(dataWithImages.count / 1024) KB")
        print("完整版: \(dataFull.count / 1024) KB")
        
        // 有图版应该比无图版大
        XCTAssertGreaterThan(dataWithImages.count, dataWithoutImages.count)
    }
    
    // MARK: - Subject Grouping Tests
    
    /// 测试多学科分组导出

    func testExportMultipleSubjects() {
        var items: [ReviewItem] = []
        
        // 创建多学科数据
        for subject in [Subject.math, .physics, .chemistry, .chinese, .english] {
            items.append(contentsOf: TestReviewItemFactory.createBatch(count: 3, subject: subject))
        }
        
        let data = service.exportToPDF(items: items, title: "多学科综合")
        
        XCTAssertTrue(isValidPDF(data))
        
        if let pdf = PDFDocument(data: data) {
            print("5 学科 × 3 题 = 15 题，生成 \(pdf.pageCount) 页 PDF")
        }
    }
    
    // MARK: - Performance Tests
    
    /// 测试导出性能

    func testExportPerformance() {
        let items = TestReviewItemFactory.createBatchWithImages(count: 20, imageSize: .medium)
        
        measure {
            _ = service.exportToPDF(items: items, title: "性能测试")
        }
    }
    
    /// 测试大图片导出性能

    func testLargeImageExportPerformance() {
        // 创建包含大图片的条目
        var items: [ReviewItem] = []
        for i in 0..<5 {
            let item = TestReviewItemFactory.createWithImage(
                imageSize: .large,
                title: "大图片题目 \(i + 1)"
            )
            items.append(item)
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let data = service.exportToPDF(items: items, title: "大图片测试")
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        print("5 张大图片导出耗时: \(elapsed * 1000) ms")
        print("PDF 大小: \(data.count / 1024) KB")
        
        // 大图片导出应该在 5 秒内完成
        XCTAssertLessThan(elapsed, 5.0)
    }
    
    // MARK: - Memory Tests
    
    /// 测试导出过程的内存使用

    func testExportMemoryUsage() {
        let items = TestReviewItemFactory.createBatchWithImages(count: 30, imageSize: .medium)
        
        let beforeMemory = PerformanceTestHelpers.currentMemoryUsage()
        
        let data = service.exportToPDF(items: items, title: "内存测试")
        
        let afterMemory = PerformanceTestHelpers.currentMemoryUsage()
        let growth = afterMemory > beforeMemory ? afterMemory - beforeMemory : 0
        
        print("30 条记录导出内存增长: \(growth / (1024 * 1024)) MB")
        print("PDF 大小: \(data.count / 1024) KB")
        
        // 保持引用
        XCTAssertFalse(data.isEmpty)
    }
    
    // MARK: - Helpers
    
    /// 验证是否是有效的 PDF 数据
    private func isValidPDF(_ data: Data) -> Bool {
        // PDF 文件以 %PDF 开头
        guard data.count >= 4 else { return false }
        let header = data.prefix(4)
        return header == Data([0x25, 0x50, 0x44, 0x46]) // %PDF
    }
}
