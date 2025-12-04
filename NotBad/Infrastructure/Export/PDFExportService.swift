//
//  PDFExportService.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import UIKit
import PDFKit

// MARK: - PDFExportService

/// PDF 导出服务
///
/// 将错题导出为学校试卷风格的可打印 PDF 文件。
///
/// ## 架构设计
///
/// 采用 Renderer Pattern 将绘制职责分离到独立的渲染器：
/// - `PDFPageComposer` - 页面编排主类
/// - `PDFHeaderRenderer` - 试卷头部
/// - `PDFSectionRenderer` - 学科分类标题
/// - `PDFItemRenderer` - 单个错题
/// - `PDFFooterRenderer` - 页脚和边框
///
/// ## 使用示例
///
/// ```swift
/// let data = PDFExportService.shared.exportToPDF(
///     items: reviewItems,
///     title: "期末错题集",
///     includeImages: true
/// )
/// ```
@MainActor
final class PDFExportService: PDFExportServiceProtocol {
    
    // MARK: - Singleton
    
    static let shared = PDFExportService()
    private init() {}
    
    // MARK: - Dependencies
    
    private let composer = PDFPageComposer()
    
    // MARK: - Export Methods
    
    /// 导出错题为 PDF（学校试卷风格）
    /// - Parameters:
    ///   - items: 要导出的错题列表
    ///   - title: PDF 标题
    ///   - includeImages: 是否包含图片
    ///   - includeNotes: 是否包含笔记
    ///   - showAnswerArea: 是否显示答题区域
    /// - Returns: PDF 数据
    func exportToPDF(
        items: [ReviewItem],
        title: String = "错题集",
        includeImages: Bool = true,
        includeNotes: Bool = false,
        showAnswerArea: Bool = true
    ) -> Data {
        composer.compose(
            items: items,
            title: title,
            includeImages: includeImages,
            includeNotes: includeNotes,
            showAnswerArea: showAnswerArea
        )
    }
}
