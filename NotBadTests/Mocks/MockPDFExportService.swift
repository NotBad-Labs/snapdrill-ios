//
//  MockPDFExportService.swift
//  NotBadTests
//
//  PDF 导出服务的 Mock 实现
//

import Foundation
@testable import NotBad

// MARK: - MockPDFExportService

/// PDF 导出服务的 Mock 实现
///
/// 用于单元测试，可以控制导出结果和错误情况。
///
/// ## 使用示例
///
/// ```swift
/// @Test("PDF 导出成功")
/// @MainActor
/// func testPDFExportSuccess() async {
///     let mock = MockPDFExportService()
///     mock.mockPDFData = Data([0x25, 0x50, 0x44, 0x46]) // %PDF
///     
///     let result = mock.exportToPDF(items: items, title: "测试")
///     
///     #expect(result != nil)
/// }
/// ```
@MainActor
final class MockPDFExportService: PDFExportServiceProtocol {
    
    // MARK: - Mock Configuration
    
    /// 模拟的 PDF 数据
    var mockPDFData: Data = Data([0x25, 0x50, 0x44, 0x46]) // %PDF header
    
    // MARK: - Call Tracking
    
    /// exportToPDF 被调用的次数
    var exportToPDFCallCount = 0
    
    /// 最后传入的错题列表
    var lastItems: [ReviewItem]?
    
    /// 最后传入的标题
    var lastTitle: String?
    
    /// 最后传入的选项
    var lastIncludeImages: Bool?
    var lastIncludeNotes: Bool?
    var lastShowAnswerArea: Bool?
    
    // MARK: - Export Method
    
    /// 导出错题为 PDF
    func exportToPDF(
        items: [ReviewItem],
        title: String,
        includeImages: Bool,
        includeNotes: Bool,
        showAnswerArea: Bool
    ) -> Data {
        exportToPDFCallCount += 1
        lastItems = items
        lastTitle = title
        lastIncludeImages = includeImages
        lastIncludeNotes = includeNotes
        lastShowAnswerArea = showAnswerArea
        
        return mockPDFData
    }
    
    // MARK: - Reset
    
    /// 重置所有状态
    func reset() {
        mockPDFData = Data([0x25, 0x50, 0x44, 0x46])
        exportToPDFCallCount = 0
        lastItems = nil
        lastTitle = nil
        lastIncludeImages = nil
        lastIncludeNotes = nil
        lastShowAnswerArea = nil
    }
}
