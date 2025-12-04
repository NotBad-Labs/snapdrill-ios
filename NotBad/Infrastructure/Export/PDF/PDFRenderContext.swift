//
//  PDFRenderContext.swift
//  NotBad
//
//  PDF 渲染共享上下文
//

import UIKit

// MARK: - PDF Render Context

/// PDF 渲染上下文
///
/// 在各个 Renderer 之间共享的配置和状态。
struct PDFRenderContext {
    
    // MARK: - Page Configuration
    
    /// PDF 页面尺寸 (A4)
    static let pageSize = CGSize(width: 595.2, height: 841.8) // A4 at 72 DPI
    
    /// 页面边距
    static let margin: CGFloat = 50
    
    /// 内容区域
    static var contentRect: CGRect {
        CGRect(
            x: margin,
            y: margin + 30, // 留出页眉空间
            width: pageSize.width - margin * 2,
            height: pageSize.height - margin * 2 - 50 // 留出页脚空间
        )
    }
    
    // MARK: - Fonts
    
    enum Fonts {
        static let title = UIFont.systemFont(ofSize: 24, weight: .bold)
        static let sectionHeader = UIFont.systemFont(ofSize: 14, weight: .bold)
        static let itemIndex = UIFont.systemFont(ofSize: 12, weight: .bold)
        static let itemContent = UIFont.systemFont(ofSize: 11, weight: .regular)
        static let hint = UIFont.systemFont(ofSize: 10, weight: .regular)
        static let note = UIFont.systemFont(ofSize: 10, weight: .regular)
        static let small = UIFont.systemFont(ofSize: 9, weight: .regular)
        static let tiny = UIFont.systemFont(ofSize: 8, weight: .light)
    }
    
    // MARK: - Colors
    
    enum Colors {
        static let black = UIColor.black
        static let darkGray = UIColor.darkGray
        static let lightGray = UIColor.lightGray
        static let orange = UIColor.orange
        static let blue = UIColor.systemBlue
    }
    
    // MARK: - Text Utilities
    
    /// 估算文本高度
    static func estimateTextHeight(_ text: String, width: CGFloat, font: UIFont) -> CGFloat {
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
