//
//  PDFExportServiceProtocol.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//  Phase 4: Service Layer Abstraction
//

import Foundation
import SwiftData
import ReviewKit

// MARK: - PDFExportServiceProtocol

/// PDF 导出服务协议
///
/// 定义 PDF 导出功能的抽象接口，支持依赖注入和测试。
///
/// ## 设计目的
///
/// 1. **解耦**：ViewModel 依赖协议而非具体实现
/// 2. **可测试**：可以注入 Mock 实现进行单元测试
/// 3. **可替换**：未来可以替换为其他 PDF 生成库
///
/// ## 使用示例
///
/// ```swift
/// // 生产环境
/// let service: PDFExportServiceProtocol = PDFExportService.shared
/// let data = service.exportToPDF(items: items, title: "我的错题集")
///
/// // 测试环境
/// let mockService = MockPDFExportService()
/// let data = mockService.exportToPDF(items: items, title: "测试")
/// ```
@MainActor
protocol PDFExportServiceProtocol: AnyObject, Sendable {

    /// 导出错题为 PDF
    ///
    /// 将错题列表导出为学校试卷风格的可打印 PDF 文件。
    ///
    /// - Parameters:
    ///   - items: 要导出的错题列表
    ///   - title: PDF 标题，默认为 "错题集"
    ///   - includeImages: 是否包含错题图片，默认 true
    ///   - includeNotes: 是否包含笔记，默认 false
    ///   - showAnswerArea: 是否显示答题区域，默认 true
    /// - Returns: PDF 数据
    func exportToPDF(
        items: [ReviewItemModel],
        title: String,
        includeImages: Bool,
        includeNotes: Bool,
        showAnswerArea: Bool
    ) -> Data
}
