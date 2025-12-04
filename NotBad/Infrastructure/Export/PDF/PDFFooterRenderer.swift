//
//  PDFFooterRenderer.swift
//  NotBad
//
//  PDF 页脚渲染器 - 负责绘制页面边框和页脚
//

import UIKit

// MARK: - PDF Footer Renderer

/// PDF 页脚渲染器
///
/// 负责绘制：
/// - 页面边框（试卷风格）
/// - 装订线提示
/// - 页码
/// - 底部 Slogan
struct PDFFooterRenderer {
    
    private let context: CGContext
    private let pageNumber: Int
    
    init(context: CGContext, pageNumber: Int) {
        self.context = context
        self.pageNumber = pageNumber
    }
    
    /// 绘制页面边框和页脚
    func render() {
        drawPageBorder()
        drawPageNumber()
        drawSlogan()
    }
    
    // MARK: - Private Drawing Methods
    
    /// 绘制页面边框（试卷风格）
    private func drawPageBorder() {
        let pageSize = PDFRenderContext.pageSize
        
        // 外边框
        context.setStrokeColor(PDFRenderContext.Colors.black.cgColor)
        context.setLineWidth(2)
        let outerRect = CGRect(x: 30, y: 30, width: pageSize.width - 60, height: pageSize.height - 60)
        context.stroke(outerRect)
        
        // 装订线提示（左侧）
        drawBindingLine()
    }
    
    /// 绘制装订线
    private func drawBindingLine() {
        let pageSize = PDFRenderContext.pageSize
        
        let bindingAttributes: [NSAttributedString.Key: Any] = [
            .font: PDFRenderContext.Fonts.tiny,
            .foregroundColor: PDFRenderContext.Colors.lightGray
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
    
    /// 绘制页码
    private func drawPageNumber() {
        let pageSize = PDFRenderContext.pageSize
        let footerY = pageSize.height - 40
        
        let pageAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: PDFRenderContext.Colors.darkGray
        ]
        let pageText = "第 \(pageNumber) 页"
        let pageString = NSAttributedString(string: pageText, attributes: pageAttributes)
        let pageTextSize = pageString.size()
        let pageX = (pageSize.width - pageTextSize.width) / 2
        pageString.draw(at: CGPoint(x: pageX, y: footerY))
    }
    
    /// 绘制底部 Slogan
    private func drawSlogan() {
        let margin = PDFRenderContext.margin
        let footerY = PDFRenderContext.pageSize.height - 40
        
        let tipText = "NotBad 错题本 · 智能复习，高效学习"
        let tipAttributes: [NSAttributedString.Key: Any] = [
            .font: PDFRenderContext.Fonts.tiny,
            .foregroundColor: PDFRenderContext.Colors.lightGray
        ]
        let tipString = NSAttributedString(string: tipText, attributes: tipAttributes)
        tipString.draw(at: CGPoint(x: margin, y: footerY))
    }
}
