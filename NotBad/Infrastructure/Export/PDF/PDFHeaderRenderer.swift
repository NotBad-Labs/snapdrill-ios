//
//  PDFHeaderRenderer.swift
//  NotBad
//
//  PDF 页眉渲染器 - 负责绘制试卷头部
//

import UIKit

// MARK: - PDF Header Renderer

/// PDF 页眉渲染器
///
/// 负责绘制试卷头部，包括：
/// - 学校名称区域
/// - 班级姓名区域
/// - 试卷标题
/// - 副标题（题目数量、日期）
/// - 注意事项框
struct PDFHeaderRenderer {
    
    private let context: CGContext
    private let title: String
    private let itemCount: Int
    
    init(context: CGContext, title: String, itemCount: Int) {
        self.context = context
        self.title = title
        self.itemCount = itemCount
    }
    
    /// 绘制试卷头部
    /// - Returns: 绘制完成后的 Y 坐标
    func render() -> CGFloat {
        var y = PDFRenderContext.contentRect.minY
        
        y = drawSchoolAndNameArea(y: y)
        y = drawTitle(y: y)
        y = drawNoticeBox(y: y)
        y = drawDoubleLine(y: y)
        
        return y + 15
    }
    
    // MARK: - Private Drawing Methods
    
    /// 绘制学校和姓名区域
    private func drawSchoolAndNameArea(y: CGFloat) -> CGFloat {
        let margin = PDFRenderContext.margin
        
        // 学校名称区域（虚线框）
        context.setStrokeColor(PDFRenderContext.Colors.lightGray.cgColor)
        context.setLineWidth(0.5)
        context.setLineDash(phase: 0, lengths: [3, 3])
        let schoolRect = CGRect(x: margin, y: y, width: 200, height: 25)
        context.stroke(schoolRect)
        context.setLineDash(phase: 0, lengths: [])
        
        let hintAttributes: [NSAttributedString.Key: Any] = [
            .font: PDFRenderContext.Fonts.small,
            .foregroundColor: PDFRenderContext.Colors.lightGray
        ]
        
        let schoolHint = NSAttributedString(string: "学校：________________", attributes: hintAttributes)
        schoolHint.draw(at: CGPoint(x: margin + 5, y: y + 5))
        
        // 班级姓名区域
        let nameHint = NSAttributedString(string: "班级：_______ 姓名：_______", attributes: hintAttributes)
        nameHint.draw(at: CGPoint(x: PDFRenderContext.pageSize.width - margin - 180, y: y + 5))
        
        return y + 40
    }
    
    /// 绘制试卷标题
    private func drawTitle(y: CGFloat) -> CGFloat {
        var currentY = y
        let pageWidth = PDFRenderContext.pageSize.width
        let margin = PDFRenderContext.margin
        
        // 主标题（大号加粗居中）
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: PDFRenderContext.Fonts.title,
            .foregroundColor: PDFRenderContext.Colors.black
        ]
        let titleString = NSAttributedString(string: title, attributes: titleAttributes)
        let titleSize = titleString.size()
        let titleX = (pageWidth - titleSize.width) / 2
        titleString.draw(at: CGPoint(x: titleX, y: currentY))
        currentY += 35
        
        // 副标题（题目数量）
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: PDFRenderContext.Colors.darkGray
        ]
        let subtitle = "（共 \(itemCount) 题）"
        let subtitleString = NSAttributedString(string: subtitle, attributes: subtitleAttributes)
        let subtitleSize = subtitleString.size()
        let subtitleX = (pageWidth - subtitleSize.width) / 2
        subtitleString.draw(at: CGPoint(x: subtitleX, y: currentY))
        currentY += 25
        
        // 日期（右对齐）
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        let dateString = dateFormatter.string(from: Date())
        
        let dateAttr = NSAttributedString(string: dateString, attributes: [
            .font: UIFont.systemFont(ofSize: 10, weight: .light),
            .foregroundColor: PDFRenderContext.Colors.lightGray
        ])
        let dateSize = dateAttr.size()
        dateAttr.draw(at: CGPoint(x: pageWidth - margin - dateSize.width, y: currentY - 20))
        
        return currentY + 5
    }
    
    /// 绘制注意事项框
    private func drawNoticeBox(y: CGFloat) -> CGFloat {
        let margin = PDFRenderContext.margin
        let contentWidth = PDFRenderContext.contentRect.width
        
        // 边框
        context.setStrokeColor(PDFRenderContext.Colors.black.cgColor)
        context.setLineWidth(1)
        let noticeRect = CGRect(x: margin, y: y, width: contentWidth, height: 45)
        context.stroke(noticeRect)
        
        // 标题
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: PDFRenderContext.Colors.black
        ]
        let noticeHeader = NSAttributedString(string: "【注意事项】", attributes: titleAttributes)
        noticeHeader.draw(at: CGPoint(x: margin + 8, y: y + 5))
        
        // 内容
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: PDFRenderContext.Fonts.small,
            .foregroundColor: PDFRenderContext.Colors.darkGray
        ]
        let notice = NSAttributedString(
            string: "1. 请认真审题，仔细作答。  2. 本试卷为错题巩固练习，请独立完成。  3. 答题时请保持卷面整洁。",
            attributes: contentAttributes
        )
        notice.draw(at: CGPoint(x: margin + 8, y: y + 22))
        
        return y + 55
    }
    
    /// 绘制双横线分隔
    private func drawDoubleLine(y: CGFloat) -> CGFloat {
        let margin = PDFRenderContext.margin
        let pageWidth = PDFRenderContext.pageSize.width
        
        // 粗线
        context.setStrokeColor(PDFRenderContext.Colors.black.cgColor)
        context.setLineWidth(1.5)
        context.move(to: CGPoint(x: margin, y: y))
        context.addLine(to: CGPoint(x: pageWidth - margin, y: y))
        context.strokePath()
        
        // 细线
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: margin, y: y + 3))
        context.addLine(to: CGPoint(x: pageWidth - margin, y: y + 3))
        context.strokePath()
        
        return y
    }
}
