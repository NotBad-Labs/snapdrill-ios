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
@MainActor
final class PDFExportService: PDFExportServiceProtocol {
    
    // MARK: - Singleton
    
    static let shared = PDFExportService()
    private init() {}
    
    // MARK: - Configuration
    
    /// PDF 页面尺寸 (A4)
    private let pageSize = CGSize(width: 595.2, height: 841.8) // A4 at 72 DPI
    
    /// 页面边距
    private let margin: CGFloat = 50
    
    /// 内容区域
    private var contentRect: CGRect {
        CGRect(
            x: margin,
            y: margin + 30, // 留出页眉空间
            width: pageSize.width - margin * 2,
            height: pageSize.height - margin * 2 - 50 // 留出页脚空间
        )
    }
    
    /// 当前页码
    private var currentPageNumber = 0
    
    /// 学科序号映射
    private var subjectIndexMap: [String: Int] = [:]
    
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
        currentPageNumber = 0
        subjectIndexMap = [:]
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        
        let data = renderer.pdfData { context in
            var currentY: CGFloat = 0
            
            // 开始第一页
            beginNewPage(context: context, cgContext: context.cgContext)
            currentY = drawExamHeader(context: context.cgContext, title: title, itemCount: items.count)
            
            // 按学科分组
            let groupedItems = Dictionary(grouping: items) { $0.subject.displayName }
            let sortedSubjects = groupedItems.keys.sorted()
            
            // 建立学科序号映射
            for (index, subject) in sortedSubjects.enumerated() {
                subjectIndexMap[subject] = index
            }
            
            var globalIndex = 1
            
            for subject in sortedSubjects {
                guard let subjectItems = groupedItems[subject] else { continue }
                
                // 学科大题标题
                if currentY + 80 > contentRect.maxY {
                    beginNewPage(context: context, cgContext: context.cgContext)
                    currentY = contentRect.minY
                }
                currentY = drawSectionHeader(context: context.cgContext, subject: subject, y: currentY)
                
                // 错题内容
                for item in subjectItems {
                    let estimatedHeight = estimateItemHeight(item, includeImages: includeImages, includeNotes: includeNotes, showAnswerArea: showAnswerArea)
                    
                    if currentY + estimatedHeight > contentRect.maxY {
                        beginNewPage(context: context, cgContext: context.cgContext)
                        currentY = contentRect.minY
                    }
                    
                    currentY = drawExamItem(
                        context: context.cgContext,
                        item: item,
                        index: globalIndex,
                        y: currentY,
                        includeImages: includeImages,
                        includeNotes: includeNotes,
                        showAnswerArea: showAnswerArea
                    )
                    globalIndex += 1
                }
                
                currentY += 15
            }
        }
        
        return data
    }
    
    // MARK: - Page Management
    
    /// 开始新页面
    private func beginNewPage(context: UIGraphicsPDFRendererContext, cgContext: CGContext) {
        context.beginPage()
        currentPageNumber += 1
        drawPageBorder(context: cgContext)
        drawPageFooter(context: cgContext)
    }
    
    /// 绘制页面边框（试卷风格）
    private func drawPageBorder(context: CGContext) {
        // 外边框
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(2)
        let outerRect = CGRect(x: 30, y: 30, width: pageSize.width - 60, height: pageSize.height - 60)
        context.stroke(outerRect)
        
        // 装订线提示（左侧）
        let bindingAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .light),
            .foregroundColor: UIColor.gray
        ]
        let bindingText = "← 装订线 →"
        let bindingString = NSAttributedString(string: bindingText, attributes: bindingAttributes)
        
        // 旋转绘制装订线文字
        context.saveGState()
        context.translateBy(x: 18, y: pageSize.height / 2 + 30)
        context.rotate(by: -.pi / 2)
        bindingString.draw(at: .zero)
        context.restoreGState()
    }
    
    /// 绘制页脚
    private func drawPageFooter(context: CGContext) {
        let footerY = pageSize.height - 40
        
        // 页码
        let pageAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]
        let pageText = "第 \(currentPageNumber) 页"
        let pageString = NSAttributedString(string: pageText, attributes: pageAttributes)
        let pageTextSize = pageString.size()
        let pageX = (self.pageSize.width - pageTextSize.width) / 2
        pageString.draw(at: CGPoint(x: pageX, y: footerY))
        
        // 底部提示
        let tipText = "NotBad 错题本 · 智能复习，高效学习"
        let tipAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .light),
            .foregroundColor: UIColor.lightGray
        ]
        let tipString = NSAttributedString(string: tipText, attributes: tipAttributes)
        tipString.draw(at: CGPoint(x: margin, y: footerY))
    }
    
    // MARK: - Drawing Methods
    
    /// 绘制试卷头部
    private func drawExamHeader(context: CGContext, title: String, itemCount: Int) -> CGFloat {
        var y = contentRect.minY
        
        // 学校名称区域（虚线框）
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(0.5)
        context.setLineDash(phase: 0, lengths: [3, 3])
        let schoolRect = CGRect(x: margin, y: y, width: 200, height: 25)
        context.stroke(schoolRect)
        context.setLineDash(phase: 0, lengths: [])
        
        let schoolHintAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .light),
            .foregroundColor: UIColor.lightGray
        ]
        let schoolHint = NSAttributedString(string: "学校：________________", attributes: schoolHintAttributes)
        schoolHint.draw(at: CGPoint(x: margin + 5, y: y + 5))
        
        // 班级姓名区域
        let nameHint = NSAttributedString(string: "班级：_______ 姓名：_______", attributes: schoolHintAttributes)
        nameHint.draw(at: CGPoint(x: pageSize.width - margin - 180, y: y + 5))
        
        y += 40
        
        // 试卷标题（大号加粗居中）
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        let titleString = NSAttributedString(string: title, attributes: titleAttributes)
        let titleSize = titleString.size()
        let titleX = (pageSize.width - titleSize.width) / 2
        titleString.draw(at: CGPoint(x: titleX, y: y))
        y += 35
        
        // 副标题
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        let dateString = dateFormatter.string(from: Date())
        
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]
        let subtitle = "（共 \(itemCount) 题）"
        let subtitleString = NSAttributedString(string: subtitle, attributes: subtitleAttributes)
        let subtitleSize = subtitleString.size()
        let subtitleX = (pageSize.width - subtitleSize.width) / 2
        subtitleString.draw(at: CGPoint(x: subtitleX, y: y))
        y += 25
        
        // 日期（右对齐）
        let dateAttr = NSAttributedString(string: dateString, attributes: [
            .font: UIFont.systemFont(ofSize: 10, weight: .light),
            .foregroundColor: UIColor.gray
        ])
        let dateSize = dateAttr.size()
        dateAttr.draw(at: CGPoint(x: pageSize.width - margin - dateSize.width, y: y - 20))
        
        // 注意事项框
        y += 5
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1)
        let noticeRect = CGRect(x: margin, y: y, width: contentRect.width, height: 45)
        context.stroke(noticeRect)
        
        let noticeTitle: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: UIColor.black
        ]
        let noticeHeader = NSAttributedString(string: "【注意事项】", attributes: noticeTitle)
        noticeHeader.draw(at: CGPoint(x: margin + 8, y: y + 5))
        
        let noticeContent: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]
        let notice = NSAttributedString(string: "1. 请认真审题，仔细作答。  2. 本试卷为错题巩固练习，请独立完成。  3. 答题时请保持卷面整洁。", attributes: noticeContent)
        notice.draw(at: CGPoint(x: margin + 8, y: y + 22))
        
        y += 55
        
        // 双横线分隔
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1.5)
        context.move(to: CGPoint(x: margin, y: y))
        context.addLine(to: CGPoint(x: pageSize.width - margin, y: y))
        context.strokePath()
        
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: margin, y: y + 3))
        context.addLine(to: CGPoint(x: pageSize.width - margin, y: y + 3))
        context.strokePath()
        
        y += 15
        
        return y
    }
    
    /// 绘制学科分类标题（大题样式）
    private func drawSectionHeader(context: CGContext, subject: String, y: CGFloat) -> CGFloat {
        var currentY = y + 10
        
        // 大题标题（如：一、数学）
        let sectionNumbers = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
        let sectionIndex = subjectIndexMap[subject] ?? 0
        let sectionNumber = sectionIndex < sectionNumbers.count ? sectionNumbers[sectionIndex] : "\(sectionIndex + 1)"
        
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        let headerText = "\(sectionNumber)、\(subject)"
        let headerString = NSAttributedString(string: headerText, attributes: headerAttributes)
        headerString.draw(at: CGPoint(x: margin, y: currentY))
        
        currentY += 28
        return currentY
    }
    
    /// 估算错题高度
    private func estimateItemHeight(_ item: ReviewItem, includeImages: Bool, includeNotes: Bool, showAnswerArea: Bool) -> CGFloat {
        var height: CGFloat = 45 // 基础高度（题号 + 难度标签）
        
        // 题目内容高度
        let contentHeight = estimateTextHeight(item.title, width: contentRect.width - 40, fontSize: 11)
        height += min(contentHeight, 80) + 10
        
        // 图片高度
        if includeImages && item.imageData != nil {
            height += 100
        }
        
        // 笔记高度
        if includeNotes && !item.note.isEmpty {
            let notesHeight = estimateTextHeight(item.note, width: contentRect.width - 60, fontSize: 10)
            height += min(notesHeight, 50) + 25
        }
        
        // 答题区域
        if showAnswerArea {
            height += 80
        }
        
        return height + 15
    }
    
    /// 绘制单个错题（试卷题目样式）
    private func drawExamItem(
        context: CGContext,
        item: ReviewItem,
        index: Int,
        y: CGFloat,
        includeImages: Bool,
        includeNotes: Bool,
        showAnswerArea: Bool
    ) -> CGFloat {
        var currentY = y
        
        // 题号（加粗）+ 难度标签
        let indexAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        let indexString = NSAttributedString(string: "\(index). ", attributes: indexAttributes)
        indexString.draw(at: CGPoint(x: margin, y: currentY))
        
        // 难度星级
        let difficultyStars = String(repeating: "★", count: item.difficulty.rawValue + 1) + String(repeating: "☆", count: 4 - item.difficulty.rawValue)
        let difficultyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .regular),
            .foregroundColor: UIColor.orange
        ]
        let difficultyString = NSAttributedString(string: "难度: \(difficultyStars)", attributes: difficultyAttributes)
        difficultyString.draw(at: CGPoint(x: pageSize.width - margin - 80, y: currentY + 2))
        
        currentY += 18
        
        // 题目内容（带缩进）
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.black
        ]
        let contentText = item.title.isEmpty ? "（请查看图片）" : item.title
        let contentString = NSAttributedString(string: contentText, attributes: contentAttributes)
        let textContentRect = CGRect(x: margin + 20, y: currentY, width: self.contentRect.width - 40, height: 80)
        contentString.draw(with: textContentRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil)
        let contentHeight = min(estimateTextHeight(contentText, width: self.contentRect.width - 40, fontSize: 11), 80)
        currentY += contentHeight + 8
        
        // 知识点标签（如果有）
        if !item.knowledgePoints.isEmpty {
            let tagText = "【知识点】" + item.knowledgePoints.prefix(3).joined(separator: "、")
            let tagAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            let tagString = NSAttributedString(string: tagText, attributes: tagAttributes)
            tagString.draw(at: CGPoint(x: margin + 20, y: currentY))
            currentY += 15
        }
        
        // 图片（缩小显示）
        if includeImages, let imageData = item.imageData, let image = UIImage(data: imageData) {
            let maxWidth = self.contentRect.width - 60
            let maxHeight: CGFloat = 85
            let aspectRatio = image.size.width / image.size.height
            var imageWidth = min(maxWidth, 280)
            var imageHeight = imageWidth / aspectRatio
            
            if imageHeight > maxHeight {
                imageHeight = maxHeight
                imageWidth = imageHeight * aspectRatio
            }
            
            // 图片边框
            let imageRect = CGRect(x: margin + 25, y: currentY, width: imageWidth, height: imageHeight)
            context.setStrokeColor(UIColor.lightGray.cgColor)
            context.setLineWidth(0.5)
            context.stroke(imageRect)
            
            image.draw(in: imageRect)
            currentY += imageHeight + 10
        }
        
        // 笔记/解析提示
        if includeNotes && !item.note.isEmpty {
            // 解析标题
            let hintAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: UIColor.systemBlue
            ]
            let hintString = NSAttributedString(string: "【解析提示】", attributes: hintAttributes)
            hintString.draw(at: CGPoint(x: margin + 20, y: currentY))
            currentY += 14
            
            // 解析内容
            let noteAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            let noteString = NSAttributedString(string: item.note, attributes: noteAttributes)
            let noteRect = CGRect(x: margin + 20, y: currentY, width: self.contentRect.width - 60, height: 50)
            noteString.draw(with: noteRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil)
            let noteHeight = min(estimateTextHeight(item.note, width: self.contentRect.width - 60, fontSize: 10), 50)
            currentY += noteHeight + 8
        }
        
        // 答题区域（带横线）
        if showAnswerArea {
            currentY += 5
            
            let answerLabel: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                .foregroundColor: UIColor.gray
            ]
            let answerString = NSAttributedString(string: "答：", attributes: answerLabel)
            answerString.draw(at: CGPoint(x: margin + 20, y: currentY))
            
            // 答题横线
            context.setStrokeColor(UIColor.lightGray.cgColor)
            context.setLineWidth(0.5)
            
            let lineStartX = margin + 45
            let lineEndX = pageSize.width - margin - 20
            
            for i in 0..<3 {
                let lineY = currentY + CGFloat(i) * 22 + 18
                context.move(to: CGPoint(x: lineStartX, y: lineY))
                context.addLine(to: CGPoint(x: lineEndX, y: lineY))
            }
            context.strokePath()
            
            currentY += 70
        }
        
        // 题目分隔（浅色虚线）
        currentY += 5
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(0.3)
        context.setLineDash(phase: 0, lengths: [2, 2])
        context.move(to: CGPoint(x: margin + 20, y: currentY))
        context.addLine(to: CGPoint(x: pageSize.width - margin - 20, y: currentY))
        context.strokePath()
        context.setLineDash(phase: 0, lengths: [])
        
        currentY += 12
        
        return currentY
    }
    
    /// 估算文本高度
    private func estimateTextHeight(_ text: String, width: CGFloat, fontSize: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let boundingRect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        return ceil(boundingRect.height)
    }
}
