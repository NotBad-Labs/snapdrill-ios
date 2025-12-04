//
//  PDFPageComposer.swift
//  NotBad
//
//  PDF 页面编排器 - 主类
//
//  职责：
//  - 分页逻辑
//  - 坐标计算
//  - 调用各个子渲染器
//

import UIKit
import PDFKit

// MARK: - PDF Page Composer

/// PDF 页面编排器
///
/// 负责整体的 PDF 生成流程，包括：
/// - 页面管理（创建新页、分页判断）
/// - 坐标追踪
/// - 调用各个 Renderer 绘制内容
///
/// ## 架构设计
///
/// 采用 Renderer Pattern 将绘制职责分离：
/// - `PDFHeaderRenderer` - 试卷头部
/// - `PDFSectionRenderer` - 学科分类标题
/// - `PDFItemRenderer` - 单个错题
/// - `PDFFooterRenderer` - 页脚和边框
///
/// ## 使用示例
///
/// ```swift
/// let composer = PDFPageComposer()
/// let pdfData = composer.compose(
///     items: reviewItems,
///     title: "期末错题集",
///     includeImages: true
/// )
/// ```
@MainActor
final class PDFPageComposer {
    
    // MARK: - State
    
    private var currentPageNumber = 0
    private var subjectIndexMap: [String: Int] = [:]
    
    // MARK: - Public API
    
    /// 生成 PDF
    /// - Parameters:
    ///   - items: 要导出的错题列表
    ///   - title: PDF 标题
    ///   - includeImages: 是否包含图片
    ///   - includeNotes: 是否包含笔记
    ///   - showAnswerArea: 是否显示答题区域
    /// - Returns: PDF 数据
    func compose(
        items: [ReviewItem],
        title: String = "错题集",
        includeImages: Bool = true,
        includeNotes: Bool = false,
        showAnswerArea: Bool = true
    ) -> Data {
        // 重置状态
        currentPageNumber = 0
        subjectIndexMap = [:]
        
        let pageSize = PDFRenderContext.pageSize
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        
        let itemConfig = PDFItemRenderer.Config(
            includeImages: includeImages,
            includeNotes: includeNotes,
            showAnswerArea: showAnswerArea
        )
        
        return renderer.pdfData { context in
            var currentY: CGFloat = 0
            
            // 开始第一页
            beginNewPage(context: context, cgContext: context.cgContext)
            
            // 绘制试卷头部
            let headerRenderer = PDFHeaderRenderer(
                context: context.cgContext,
                title: title,
                itemCount: items.count
            )
            currentY = headerRenderer.render()
            
            // 按学科分组
            let groupedItems = Dictionary(grouping: items) { $0.subject.displayName }
            let sortedSubjects = groupedItems.keys.sorted()
            
            // 建立学科序号映射
            for (index, subject) in sortedSubjects.enumerated() {
                subjectIndexMap[subject] = index
            }
            
            var globalIndex = 1
            
            // 遍历学科
            for subject in sortedSubjects {
                guard let subjectItems = groupedItems[subject] else { continue }
                
                // 检查是否需要分页（学科标题）
                if currentY + 80 > PDFRenderContext.contentRect.maxY {
                    beginNewPage(context: context, cgContext: context.cgContext)
                    currentY = PDFRenderContext.contentRect.minY
                }
                
                // 绘制学科标题
                let sectionRenderer = PDFSectionRenderer(
                    context: context.cgContext,
                    subject: subject,
                    sectionIndex: subjectIndexMap[subject] ?? 0
                )
                currentY = sectionRenderer.render(at: currentY)
                
                // 遍历该学科的错题
                for reviewItem in subjectItems {
                    let estimatedHeight = PDFItemRenderer.estimateHeight(for: reviewItem, config: itemConfig)
                    
                    // 检查是否需要分页
                    if currentY + estimatedHeight > PDFRenderContext.contentRect.maxY {
                        beginNewPage(context: context, cgContext: context.cgContext)
                        currentY = PDFRenderContext.contentRect.minY
                    }
                    
                    // 绘制错题
                    let itemRenderer = PDFItemRenderer(
                        context: context.cgContext,
                        reviewItem: reviewItem,
                        index: globalIndex,
                        config: itemConfig
                    )
                    currentY = itemRenderer.render(at: currentY)
                    globalIndex += 1
                }
                
                currentY += 15
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// 开始新页面
    private func beginNewPage(context: UIGraphicsPDFRendererContext, cgContext: CGContext) {
        context.beginPage()
        currentPageNumber += 1
        
        // 绘制页脚和边框
        let footerRenderer = PDFFooterRenderer(context: cgContext, pageNumber: currentPageNumber)
        footerRenderer.render()
    }
}
