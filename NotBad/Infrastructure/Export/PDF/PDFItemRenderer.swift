//
//  PDFItemRenderer.swift
//  NotBad
//
//  PDF 错题渲染器 - 负责绘制单个错题
//

import UIKit

// MARK: - PDF Item Renderer

/// PDF 错题渲染器
///
/// 负责绘制单个错题，包括：
/// - 题号和难度标签
/// - 题目内容
/// - 知识点标签
/// - 图片
/// - 笔记/解析
/// - 答题区域
struct PDFItemRenderer {
    
    // MARK: - Configuration
    
    struct Config {
        let includeImages: Bool
        let includeNotes: Bool
        let showAnswerArea: Bool
        
        static let `default` = Config(
            includeImages: true,
            includeNotes: false,
            showAnswerArea: true
        )
    }
    
    // MARK: - Properties
    
    private let context: CGContext
    private let item: ReviewItem
    private let index: Int
    private let config: Config
    
    // MARK: - Initialization
    
    init(context: CGContext, item: ReviewItem, index: Int, config: Config = .default) {
        self.context = context
        self.item = item
        self.index = index
        self.config = config
    }
    
    // MARK: - Public Methods
    
    /// 估算错题渲染高度（用于分页计算）
    static func estimateHeight(for item: ReviewItem, config: Config) -> CGFloat {
        var height: CGFloat = 45 // 基础高度（题号 + 难度标签）
        
        let contentWidth = PDFRenderContext.contentRect.width - 40
        
        // 题目内容高度
        let contentHeight = PDFRenderContext.estimateTextHeight(
            item.title,
            width: contentWidth,
            font: PDFRenderContext.Fonts.itemContent
        )
        height += min(contentHeight, 80) + 10
        
        // 图片高度
        if config.includeImages && item.imageData != nil {
            height += 100
        }
        
        // 笔记高度
        if config.includeNotes && !item.note.isEmpty {
            let notesHeight = PDFRenderContext.estimateTextHeight(
                item.note,
                width: contentWidth - 20,
                font: PDFRenderContext.Fonts.note
            )
            height += min(notesHeight, 50) + 25
        }
        
        // 答题区域
        if config.showAnswerArea {
            height += 80
        }
        
        return height + 15
    }
    
    /// 渲染错题
    /// - Parameter y: 起始 Y 坐标
    /// - Returns: 渲染完成后的 Y 坐标
    func render(at y: CGFloat) -> CGFloat {
        var currentY = y
        
        currentY = drawIndexAndDifficulty(y: currentY)
        currentY = drawContent(y: currentY)
        currentY = drawKnowledgePoints(y: currentY)
        currentY = drawImage(y: currentY)
        currentY = drawNotes(y: currentY)
        currentY = drawAnswerArea(y: currentY)
        currentY = drawSeparator(y: currentY)
        
        return currentY + 12
    }
    
    // MARK: - Private Drawing Methods
    
    /// 绘制题号和难度
    private func drawIndexAndDifficulty(y: CGFloat) -> CGFloat {
        let margin = PDFRenderContext.margin
        let pageWidth = PDFRenderContext.pageSize.width
        
        // 题号
        let indexAttributes: [NSAttributedString.Key: Any] = [
            .font: PDFRenderContext.Fonts.itemIndex,
            .foregroundColor: PDFRenderContext.Colors.black
        ]
        let indexString = NSAttributedString(string: "\(index). ", attributes: indexAttributes)
        indexString.draw(at: CGPoint(x: margin, y: y))
        
        // 难度星级
        let difficultyStars = String(repeating: "★", count: item.difficulty.rawValue + 1)
            + String(repeating: "☆", count: 4 - item.difficulty.rawValue)
        let difficultyAttributes: [NSAttributedString.Key: Any] = [
            .font: PDFRenderContext.Fonts.small,
            .foregroundColor: PDFRenderContext.Colors.orange
        ]
        let difficultyString = NSAttributedString(string: "难度: \(difficultyStars)", attributes: difficultyAttributes)
        difficultyString.draw(at: CGPoint(x: pageWidth - margin - 80, y: y + 2))
        
        return y + 18
    }
    
    /// 绘制题目内容
    private func drawContent(y: CGFloat) -> CGFloat {
        let margin = PDFRenderContext.margin
        let contentWidth = PDFRenderContext.contentRect.width - 40
        
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: PDFRenderContext.Fonts.itemContent,
            .foregroundColor: PDFRenderContext.Colors.black
        ]
        let contentText = item.title.isEmpty ? "（请查看图片）" : item.title
        let contentString = NSAttributedString(string: contentText, attributes: contentAttributes)
        let textContentRect = CGRect(x: margin + 20, y: y, width: contentWidth, height: 80)
        contentString.draw(with: textContentRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil)
        
        let contentHeight = min(
            PDFRenderContext.estimateTextHeight(contentText, width: contentWidth, font: PDFRenderContext.Fonts.itemContent),
            80
        )
        
        return y + contentHeight + 8
    }
    
    /// 绘制知识点标签
    private func drawKnowledgePoints(y: CGFloat) -> CGFloat {
        guard !item.knowledgePoints.isEmpty else { return y }
        
        let margin = PDFRenderContext.margin
        let tagText = "【知识点】" + item.knowledgePoints.prefix(3).joined(separator: "、")
        let tagAttributes: [NSAttributedString.Key: Any] = [
            .font: PDFRenderContext.Fonts.small,
            .foregroundColor: PDFRenderContext.Colors.darkGray
        ]
        let tagString = NSAttributedString(string: tagText, attributes: tagAttributes)
        tagString.draw(at: CGPoint(x: margin + 20, y: y))
        
        return y + 15
    }
    
    /// 绘制图片
    private func drawImage(y: CGFloat) -> CGFloat {
        guard config.includeImages,
              let imageData = item.imageData,
              let image = UIImage(data: imageData) else {
            return y
        }
        
        let margin = PDFRenderContext.margin
        let contentWidth = PDFRenderContext.contentRect.width - 60
        let maxHeight: CGFloat = 85
        let aspectRatio = image.size.width / image.size.height
        
        var imageWidth = min(contentWidth, 280)
        var imageHeight = imageWidth / aspectRatio
        
        if imageHeight > maxHeight {
            imageHeight = maxHeight
            imageWidth = imageHeight * aspectRatio
        }
        
        // 图片边框
        let imageRect = CGRect(x: margin + 25, y: y, width: imageWidth, height: imageHeight)
        context.setStrokeColor(PDFRenderContext.Colors.lightGray.cgColor)
        context.setLineWidth(0.5)
        context.stroke(imageRect)
        
        image.draw(in: imageRect)
        
        return y + imageHeight + 10
    }
    
    /// 绘制笔记/解析
    private func drawNotes(y: CGFloat) -> CGFloat {
        guard config.includeNotes, !item.note.isEmpty else { return y }
        
        var currentY = y
        let margin = PDFRenderContext.margin
        let contentWidth = PDFRenderContext.contentRect.width - 60
        
        // 解析标题
        let hintAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: PDFRenderContext.Colors.blue
        ]
        let hintString = NSAttributedString(string: "【解析提示】", attributes: hintAttributes)
        hintString.draw(at: CGPoint(x: margin + 20, y: currentY))
        currentY += 14
        
        // 解析内容
        let noteAttributes: [NSAttributedString.Key: Any] = [
            .font: PDFRenderContext.Fonts.note,
            .foregroundColor: PDFRenderContext.Colors.darkGray
        ]
        let noteString = NSAttributedString(string: item.note, attributes: noteAttributes)
        let noteRect = CGRect(x: margin + 20, y: currentY, width: contentWidth, height: 50)
        noteString.draw(with: noteRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil)
        
        let noteHeight = min(
            PDFRenderContext.estimateTextHeight(item.note, width: contentWidth, font: PDFRenderContext.Fonts.note),
            50
        )
        
        return currentY + noteHeight + 8
    }
    
    /// 绘制答题区域
    private func drawAnswerArea(y: CGFloat) -> CGFloat {
        guard config.showAnswerArea else { return y }
        
        var currentY = y + 5
        let margin = PDFRenderContext.margin
        let pageWidth = PDFRenderContext.pageSize.width
        
        // "答："标签
        let answerLabel: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: PDFRenderContext.Colors.lightGray
        ]
        let answerString = NSAttributedString(string: "答：", attributes: answerLabel)
        answerString.draw(at: CGPoint(x: margin + 20, y: currentY))
        
        // 答题横线
        context.setStrokeColor(PDFRenderContext.Colors.lightGray.cgColor)
        context.setLineWidth(0.5)
        
        let lineStartX = margin + 45
        let lineEndX = pageWidth - margin - 20
        
        for i in 0..<3 {
            let lineY = currentY + CGFloat(i) * 22 + 18
            context.move(to: CGPoint(x: lineStartX, y: lineY))
            context.addLine(to: CGPoint(x: lineEndX, y: lineY))
        }
        context.strokePath()
        
        return currentY + 70
    }
    
    /// 绘制题目分隔线
    private func drawSeparator(y: CGFloat) -> CGFloat {
        let currentY = y + 5
        let margin = PDFRenderContext.margin
        let pageWidth = PDFRenderContext.pageSize.width
        
        context.setStrokeColor(PDFRenderContext.Colors.lightGray.cgColor)
        context.setLineWidth(0.3)
        context.setLineDash(phase: 0, lengths: [2, 2])
        context.move(to: CGPoint(x: margin + 20, y: currentY))
        context.addLine(to: CGPoint(x: pageWidth - margin - 20, y: currentY))
        context.strokePath()
        context.setLineDash(phase: 0, lengths: [])
        
        return currentY
    }
}
