//
//  PDFSectionRenderer.swift
//  NotBad
//
//  PDF 学科分类标题渲染器
//

import UIKit

// MARK: - PDF Section Renderer

/// PDF 学科分类标题渲染器
///
/// 负责绘制大题样式的学科分类标题（如：一、数学）
struct PDFSectionRenderer {
    
    private static let sectionNumbers = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
    
    private let context: CGContext
    private let subject: String
    private let sectionIndex: Int
    
    init(context: CGContext, subject: String, sectionIndex: Int) {
        self.context = context
        self.subject = subject
        self.sectionIndex = sectionIndex
    }
    
    /// 渲染学科分类标题
    /// - Parameter y: 起始 Y 坐标
    /// - Returns: 渲染完成后的 Y 坐标
    func render(at y: CGFloat) -> CGFloat {
        let currentY = y + 10
        let margin = PDFRenderContext.margin
        
        // 大题标题（如：一、数学）
        let sectionNumber = sectionIndex < Self.sectionNumbers.count
            ? Self.sectionNumbers[sectionIndex]
            : "\(sectionIndex + 1)"
        
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: PDFRenderContext.Fonts.sectionHeader,
            .foregroundColor: PDFRenderContext.Colors.black
        ]
        let headerText = "\(sectionNumber)、\(subject)"
        let headerString = NSAttributedString(string: headerText, attributes: headerAttributes)
        headerString.draw(at: CGPoint(x: margin, y: currentY))
        
        return currentY + 28
    }
}
