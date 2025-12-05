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
    
    // 旧版渲染器 (已废弃)
    // private let composer = PDFPageComposer()
    
    // 新版 SwiftUI 渲染器
    private let swiftUIExporter = SwiftUIPDFExporter()
    
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
        // 构建配置对象
        let config = PDFExportConfig(
            includeImages: includeImages,
            includeNotes: includeNotes,
            showAnswerArea: showAnswerArea
        )
        
        // 使用新的 SwiftUI 导出器
        if let data = swiftUIExporter.export(items: items, title: title, config: config) {
            return data
        }
        
        // 降级处理（理论上不应发生）
        return Data()
    }
    
    // MARK: - Exam Mode Export
    
    /// 导出为试卷模式 PDF
    ///
    /// 试卷模式特性：
    /// - 自动题号编排
    /// - 智能留白（根据题型调整答题区大小）
    /// - 隐藏答案/笔记（防作弊）
    /// - 正式的试卷头部（姓名、班级、得分栏）
    ///
    /// - Parameters:
    ///   - items: 要导出的错题列表
    ///   - title: 试卷标题
    /// - Returns: PDF 数据
    func exportAsExam(
        items: [ReviewItem],
        title: String = "模拟测验"
    ) -> Data {
        // 使用试卷模式预设
        if let data = swiftUIExporter.export(items: items, title: title, config: .examMode) {
            return data
        }
        return Data()
    }
    
    /// 导出为复习模式 PDF
    ///
    /// 复习模式特性：
    /// - 显示笔记和知识点
    /// - 不显示答题留白
    /// - 适合打印后阅读复习
    ///
    /// - Parameters:
    ///   - items: 要导出的错题列表
    ///   - title: 文档标题
    /// - Returns: PDF 数据
    func exportAsReview(
        items: [ReviewItem],
        title: String = "错题复习集"
    ) -> Data {
        // 使用复习模式预设
        if let data = swiftUIExporter.export(items: items, title: title, config: .reviewMode) {
            return data
        }
        return Data()
    }
}