//
//  SwiftUIPDFExporter.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import PDFKit

// MARK: - Configuration

struct PDFExportConfig {
    let includeImages: Bool
    let includeNotes: Bool
    let showAnswerArea: Bool
    
    // MARK: - 试卷模式 (Exam Mode)
    
    /// 试卷模式：生成可用于测试的试卷
    ///
    /// 开启后：
    /// - 智能留白：根据题型自动调整答题区大小
    /// - 答案遮挡：隐藏笔记和知识点（避免作弊）
    /// - 增加题号：自动编号
    let examMode: Bool
    
    /// 试卷模式下的留白高度策略
    enum AnswerAreaHeight {
        /// 固定高度
        case fixed(CGFloat)
        /// 根据题型自动计算
        case smart
        
        /// 获取具体高度
        func height(for itemType: ReviewItemType) -> CGFloat {
            switch self {
            case .fixed(let h):
                return h
            case .smart:
                // 根据题型返回合理的留白高度
                switch itemType {
                case .choice, .multiChoice, .judgment:
                    return 40  // 选择/判断题只需小空间
                case .fillBlank, .matching:
                    return 60  // 填空/连线题稍多
                case .shortAnswer, .analysis:
                    return 120 // 简答/分析题
                case .calculation, .proof, .experiment:
                    return 180 // 计算/证明/实验题需要更多空间
                case .writing:
                    return 250 // 作文需要最多空间
                case .reading, .cloze:
                    return 150 // 阅读/完形
                case .drawing:
                    return 160 // 作图题
                case .other:
                    return 100 // 默认
                }
            }
        }
    }
    
    let answerAreaHeight: AnswerAreaHeight
    
    // MARK: - Initialization
    
    init(
        includeImages: Bool = true,
        includeNotes: Bool = false,
        showAnswerArea: Bool = true,
        examMode: Bool = false,
        answerAreaHeight: AnswerAreaHeight = .smart
    ) {
        self.includeImages = includeImages
        self.includeNotes = includeNotes
        self.showAnswerArea = showAnswerArea
        self.examMode = examMode
        self.answerAreaHeight = answerAreaHeight
    }
    
    // MARK: - Presets
    
    /// 复习模式：显示所有信息
    static let reviewMode = PDFExportConfig(
        includeImages: true,
        includeNotes: true,
        showAnswerArea: false,
        examMode: false
    )
    
    /// 试卷模式：隐藏答案，智能留白
    static let examMode = PDFExportConfig(
        includeImages: true,
        includeNotes: false,
        showAnswerArea: true,
        examMode: true,
        answerAreaHeight: .smart
    )
}

// MARK: - SwiftUI PDF Exporter

/// 基于 SwiftUI ImageRenderer 的 PDF 导出器
///
/// 替代传统的 Core Graphics 绘制方式，使用 SwiftUI 视图构建 PDF。
///
/// ## 优势
/// - 布局更简单（使用 VStack/HStack）
/// - 代码更易维护
/// - 支持动态字体和自适应布局
@MainActor
final class SwiftUIPDFExporter {
    
    // MARK: - Configuration
    
    /// 每页最大题目数量 (简单分页策略)
    /// 实际项目中可以根据题目高度动态计算，这里简化处理
    private let itemsPerPage = 3
    
    // MARK: - Public API
    
    /// 导出 PDF
    /// - Parameters:
    ///   - items: 错题列表
    ///   - title: 试卷标题
    ///   - config: 导出配置
    /// - Returns: PDF 数据
    func export(items: [ReviewItem], title: String, config: PDFExportConfig) -> Data? {
        // 1. 分页
        let pages = paginate(items: items)
        let totalPages = pages.count
        
        // 2. 创建 PDF 文档上下文
        let format = UIGraphicsPDFRendererFormat()
        let metaData = [
            kCGPDFContextTitle: title,
            kCGPDFContextAuthor: "NotBad App"
        ]
        format.documentInfo = metaData as [String: Any]
        
        // A4 尺寸
        let pageSize = CGSize(width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize), format: format)
        
        // 3. 渲染每一页
        var questionNumber = 1
        let data = renderer.pdfData { context in
            for (index, pageItems) in pages.enumerated() {
                // 开始新页面
                context.beginPage()
                
                // 构建 SwiftUI 视图
                let pageView = ExamPageView(
                    title: title,
                    pageIndex: index,
                    totalPages: totalPages,
                    items: pageItems,
                    showHeader: index == 0,
                    config: config,
                    startQuestionNumber: questionNumber
                )
                
                // 更新题号
                questionNumber += pageItems.count
                
                // 使用 ImageRenderer 渲染
                let imageRenderer = ImageRenderer(content: pageView)
                imageRenderer.scale = 1.0 // 保持 1:1 比例 (72 DPI)
                
                // 渲染到 PDF 上下文
                imageRenderer.render { size, renderInContext in
                    // 将 SwiftUI 的渲染结果绘制到当前的 PDF Context 中
                    renderInContext(context.cgContext)
                }
            }
        }
        
        return data
    }
    
    // MARK: - Helper
    
    /// 简单的分页逻辑
    private func paginate(items: [ReviewItem]) -> [[ReviewItem]] {
        var pages: [[ReviewItem]] = []
        var currentItems: [ReviewItem] = []
        
        for item in items {
            currentItems.append(item)
            
            if currentItems.count >= itemsPerPage {
                pages.append(currentItems)
                currentItems = []
            }
        }
        
        if !currentItems.isEmpty {
            pages.append(currentItems)
        }
        
        return pages
    }
}
