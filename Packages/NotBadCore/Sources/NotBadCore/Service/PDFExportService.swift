//
//  PDFExportService.swift
//  NotBadCore
//
//  Created by NotBad Architect on 2025/12/31.
//

import UIKit
import PDFKit

/// 负责将错题列表生成 PDF
public final class PDFExportService: Sendable {
    public static let shared = PDFExportService()
    
    private init() {}
    
    /// 生成包含指定题目的 PDF 数据
    /// 格式：每页一般 2-3 题，留出空白位置便于重做
    public func createPDF(from items: [ReviewItem], imageProvider: (String) -> UIImage?) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "NotBad App",
            kCGPDFContextAuthor: "NotBad User"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 595.2 // A4 width
        let pageHeight = 841.8 // A4 height
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            // Title Page
            context.beginPage()
            drawTitlePage(context: context.cgContext, rect: pageRect)
            
            // Items
            // Layout: 2 items per page roughly.
            let itemsPerPage = 2
            let chunks = items.chunked(into: itemsPerPage)
            
            for chunk in chunks {
                context.beginPage()
                drawItemsPage(context: context.cgContext, rect: pageRect, items: chunk, imageProvider: imageProvider)
            }
        }
        
        return data
    }
    
    private func drawTitlePage(context: CGContext, rect: CGRect) {
        let title = "NotBad 错题本"
        let font = UIFont.systemFont(ofSize: 36, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        
        let size = title.size(withAttributes: attrs)
        let x = (rect.width - size.width) / 2
        let y = (rect.height - size.height) / 2
        
        (title as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
        
        let subtitle = "生成日期: \(Date().formatted(date: .abbreviated, time: .shortened))"
        let subFont = UIFont.systemFont(ofSize: 14)
        let subAttrs: [NSAttributedString.Key: Any] = [.font: subFont, .foregroundColor: UIColor.gray]
        let subSize = subtitle.size(withAttributes: subAttrs)
         (subtitle as NSString).draw(at: CGPoint(x: (rect.width - subSize.width) / 2, y: y + size.height + 10), withAttributes: subAttrs)
    }
    
    private func drawItemsPage(context: CGContext, rect: CGRect, items: [ReviewItem], imageProvider: (String) -> UIImage?) {
        let margin: CGFloat = 40
        let availableHeight = rect.height - margin * 2
        let itemHeight = availableHeight / 2 // Half page per item
        
        for (index, item) in items.enumerated() {
            let yOffset = margin + CGFloat(index) * itemHeight
            let contentRect = CGRect(x: margin, y: yOffset, width: rect.width - margin * 2, height: itemHeight - 20)
            
            drawItem(context: context, rect: contentRect, item: item, imageProvider: imageProvider)
            
            // Draw separator
            // Separator Removed based on user feedback
            // if index < items.count - 1 { ... }
        }
    }
    
    private func drawItem(context: CGContext, rect: CGRect, item: ReviewItem, imageProvider: (String) -> UIImage?) {
        // Draw Image if exists
        var textYOffset = rect.minY
        
        if let path = item.imagePath, let image = imageProvider(path) {
            let imageMaxHeight = rect.height * 0.6
            let aspect = image.size.width / image.size.height
            
            var drawWidth = rect.width
            var drawHeight = drawWidth / aspect
            
            if drawHeight > imageMaxHeight {
                drawHeight = imageMaxHeight
                drawWidth = drawHeight * aspect
            }
            
            let imageRect = CGRect(x: rect.minX, y: rect.minY, width: drawWidth, height: drawHeight)
            image.draw(in: imageRect)
            
            textYOffset += drawHeight + 10
        }
        
        // Draw Content Text
        // Only if there is space
        if textYOffset < rect.maxY {
            let textRect = CGRect(x: rect.minX, y: textYOffset, width: rect.width, height: rect.height - (textYOffset - rect.minY))
            
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.lineBreakMode = .byTruncatingTail
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .paragraphStyle: paraStyle
            ]
            
            (item.content as NSString).draw(in: textRect, withAttributes: attrs)
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
