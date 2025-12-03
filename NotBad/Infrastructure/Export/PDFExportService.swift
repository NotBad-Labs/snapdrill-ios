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
/// 将错题导出为可打印的 PDF 文件。
@MainActor
final class PDFExportService {
    
    // MARK: - Singleton
    
    static let shared = PDFExportService()
    private init() {}
    
    // MARK: - Configuration
    
    /// PDF 页面尺寸 (A4)
    private let pageSize = CGSize(width: 595.2, height: 841.8) // A4 at 72 DPI
    
    /// 页面边距
    private let margin: CGFloat = 40
    
    /// 内容区域
    private var contentRect: CGRect {
        CGRect(
            x: margin,
            y: margin,
            width: pageSize.width - margin * 2,
            height: pageSize.height - margin * 2
        )
    }
    
    // MARK: - Export Methods
    
    /// 导出错题为 PDF
    /// - Parameters:
    ///   - items: 要导出的错题列表
    ///   - title: PDF 标题
    ///   - includeImages: 是否包含图片
    ///   - includeNotes: 是否包含笔记
    /// - Returns: PDF 数据
    func exportToPDF(
        items: [ReviewItem],
        title: String = "我的错题本",
        includeImages: Bool = true,
        includeNotes: Bool = true
    ) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        
        let data = renderer.pdfData { context in
            var currentY: CGFloat = 0
            var isFirstPage = true
            
            // 标题页
            context.beginPage()
            currentY = drawTitlePage(context: context.cgContext, title: title, itemCount: items.count)
            isFirstPage = false
            
            // 按学科分组
            let groupedItems = Dictionary(grouping: items) { $0.subject.displayName }
            let sortedSubjects = groupedItems.keys.sorted()
            
            for subject in sortedSubjects {
                guard let subjectItems = groupedItems[subject] else { continue }
                
                // 学科标题
                if currentY + 60 > contentRect.maxY {
                    context.beginPage()
                    currentY = contentRect.minY
                }
                currentY = drawSubjectHeader(context: context.cgContext, subject: subject, y: currentY)
                
                // 错题内容
                for (index, item) in subjectItems.enumerated() {
                    let estimatedHeight = estimateItemHeight(item, includeImages: includeImages, includeNotes: includeNotes)
                    
                    if currentY + estimatedHeight > contentRect.maxY {
                        context.beginPage()
                        currentY = contentRect.minY
                    }
                    
                    currentY = drawItem(
                        context: context.cgContext,
                        item: item,
                        index: index + 1,
                        y: currentY,
                        includeImages: includeImages,
                        includeNotes: includeNotes
                    )
                }
                
                currentY += 20 // 学科间距
            }
            
            // 页脚（统计信息）
            if currentY + 80 > contentRect.maxY {
                context.beginPage()
                currentY = contentRect.minY
            }
            drawFooter(context: context.cgContext, items: items, y: currentY)
        }
        
        return data
    }
    
    // MARK: - Drawing Methods
    
    /// 绘制标题页
    private func drawTitlePage(context: CGContext, title: String, itemCount: Int) -> CGFloat {
        var y = contentRect.minY + 100
        
        // 标题
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        let titleString = NSAttributedString(string: title, attributes: titleAttributes)
        let titleRect = CGRect(x: contentRect.minX, y: y, width: contentRect.width, height: 50)
        titleString.draw(in: titleRect)
        y += 60
        
        // 副标题
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.locale = Locale(identifier: "zh_CN")
        let dateString = dateFormatter.string(from: Date())
        let subtitle = "导出日期：\(dateString)\n共 \(itemCount) 道错题"
        let subtitleString = NSAttributedString(string: subtitle, attributes: subtitleAttributes)
        let subtitleRect = CGRect(x: contentRect.minX, y: y, width: contentRect.width, height: 50)
        subtitleString.draw(in: subtitleRect)
        y += 80
        
        // 分隔线
        context.setStrokeColor(UIColor.separator.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: contentRect.minX, y: y))
        context.addLine(to: CGPoint(x: contentRect.maxX, y: y))
        context.strokePath()
        y += 30
        
        return y
    }
    
    /// 绘制学科标题
    private func drawSubjectHeader(context: CGContext, subject: String, y: CGFloat) -> CGFloat {
        var currentY = y
        
        // 学科背景条
        context.setFillColor(UIColor.systemOrange.withAlphaComponent(0.1).cgColor)
        let headerRect = CGRect(x: contentRect.minX, y: currentY, width: contentRect.width, height: 30)
        context.fill(headerRect)
        
        // 学科文字
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: UIColor.systemOrange
        ]
        let string = NSAttributedString(string: "📚 \(subject)", attributes: attributes)
        let textRect = CGRect(x: contentRect.minX + 10, y: currentY + 5, width: contentRect.width - 20, height: 25)
        string.draw(in: textRect)
        
        currentY += 40
        return currentY
    }
    
    /// 估算错题高度
    private func estimateItemHeight(_ item: ReviewItem, includeImages: Bool, includeNotes: Bool) -> CGFloat {
        var height: CGFloat = 80 // 基础高度（标题 + 元数据）
        
        // 题目内容高度
        let contentHeight = estimateTextHeight(item.title, width: contentRect.width - 20, fontSize: 12)
        height += min(contentHeight, 100)
        
        // 图片高度
        if includeImages && item.imageData != nil {
            height += 120
        }
        
        // 笔记高度
        if includeNotes && !item.note.isEmpty {
            let notesHeight = estimateTextHeight(item.note, width: contentRect.width - 20, fontSize: 11)
            height += min(notesHeight, 60) + 20
        }
        
        return height + 20 // 间距
    }
    
    /// 绘制单个错题
    private func drawItem(
        context: CGContext,
        item: ReviewItem,
        index: Int,
        y: CGFloat,
        includeImages: Bool,
        includeNotes: Bool
    ) -> CGFloat {
        var currentY = y
        
        // 题目序号和标题
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: UIColor.label
        ]
        let title = "第 \(index) 题"
        let titleString = NSAttributedString(string: title, attributes: titleAttributes)
        titleString.draw(at: CGPoint(x: contentRect.minX, y: currentY))
        currentY += 20
        
        // 元数据行
        let metaAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        let dateString = dateFormatter.string(from: item.createdAt)
        let metaText = "难度: \(item.difficulty.displayName) | 掌握度: \(item.mastery.displayName) | 添加于: \(dateString)"
        let metaString = NSAttributedString(string: metaText, attributes: metaAttributes)
        metaString.draw(at: CGPoint(x: contentRect.minX, y: currentY))
        currentY += 18
        
        // 知识点标签
        if !item.knowledgePoints.isEmpty {
            let tagText = "知识点: " + item.knowledgePoints.joined(separator: ", ")
            let tagAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.systemBlue
            ]
            let tagString = NSAttributedString(string: tagText, attributes: tagAttributes)
            tagString.draw(at: CGPoint(x: contentRect.minX, y: currentY))
            currentY += 18
        }
        
        currentY += 5
        
        // 图片
        if includeImages, let imageData = item.imageData, let image = UIImage(data: imageData) {
            let maxWidth = contentRect.width - 20
            let maxHeight: CGFloat = 100
            let aspectRatio = image.size.width / image.size.height
            var imageWidth = maxWidth
            var imageHeight = imageWidth / aspectRatio
            
            if imageHeight > maxHeight {
                imageHeight = maxHeight
                imageWidth = imageHeight * aspectRatio
            }
            
            let imageRect = CGRect(x: contentRect.minX + 10, y: currentY, width: imageWidth, height: imageHeight)
            image.draw(in: imageRect)
            currentY += imageHeight + 10
        }
        
        // 题目内容
        if !item.title.isEmpty {
            let contentAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor.label
            ]
            let contentString = NSAttributedString(string: item.title, attributes: contentAttributes)
            let contentRect = CGRect(x: self.contentRect.minX + 10, y: currentY, width: self.contentRect.width - 20, height: 100)
            contentString.draw(with: contentRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil)
            let actualHeight = min(estimateTextHeight(item.title, width: self.contentRect.width - 20, fontSize: 12), 100)
            currentY += actualHeight + 10
        }
        
        // 笔记
        if includeNotes && !item.note.isEmpty {
            // 笔记标签
            let noteHeaderAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: UIColor.systemGreen
            ]
            let noteHeader = NSAttributedString(string: "📝 笔记:", attributes: noteHeaderAttributes)
            noteHeader.draw(at: CGPoint(x: contentRect.minX + 10, y: currentY))
            currentY += 15
            
            // 笔记内容
            let noteAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let noteString = NSAttributedString(string: item.note, attributes: noteAttributes)
            let noteRect = CGRect(x: contentRect.minX + 10, y: currentY, width: contentRect.width - 20, height: 60)
            noteString.draw(with: noteRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil)
            let actualHeight = min(estimateTextHeight(item.note, width: contentRect.width - 20, fontSize: 11), 60)
            currentY += actualHeight + 10
        }
        
        // 分隔线
        context.setStrokeColor(UIColor.separator.cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: contentRect.minX, y: currentY))
        context.addLine(to: CGPoint(x: contentRect.maxX, y: currentY))
        context.strokePath()
        currentY += 15
        
        return currentY
    }
    
    /// 绘制页脚统计
    private func drawFooter(context: CGContext, items: [ReviewItem], y: CGFloat) {
        var currentY = y + 20
        
        // 分隔线
        context.setStrokeColor(UIColor.separator.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: contentRect.minX, y: currentY))
        context.addLine(to: CGPoint(x: contentRect.maxX, y: currentY))
        context.strokePath()
        currentY += 20
        
        // 统计标题
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: UIColor.label
        ]
        let titleString = NSAttributedString(string: "📊 统计信息", attributes: titleAttributes)
        titleString.draw(at: CGPoint(x: contentRect.minX, y: currentY))
        currentY += 25
        
        // 统计内容
        let masteredCount = items.filter { $0.isMastered }.count
        let masteryRate = items.isEmpty ? 0 : Double(masteredCount) / Double(items.count) * 100
        
        let statsAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let statsText = """
        总题数: \(items.count) 道
        已掌握: \(masteredCount) 道
        掌握率: \(String(format: "%.1f", masteryRate))%
        """
        let statsString = NSAttributedString(string: statsText, attributes: statsAttributes)
        let statsRect = CGRect(x: contentRect.minX, y: currentY, width: contentRect.width, height: 60)
        statsString.draw(in: statsRect)
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
