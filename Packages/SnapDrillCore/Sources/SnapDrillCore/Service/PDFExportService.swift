//
//  PDFExportService.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  PDF 导出服务，负责将错题数据渲染为 PDF 文档。
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import PDFKit

/// 负责将错题列表生成 PDF 的服务类
///
/// 该服务提供将 `PDFExportable` 数组转换为 PDF 文件的能力，支持自定义图片提供者以加载本地或远程图片。
public final class PDFExportService: Sendable {
    /// 共享实例 - 建议使用 ServiceContainer 注入
    public static let shared = PDFExportService()

    /// 创建 PDF 导出服务实例；通常通过 `ServiceContainer` 注入
    public init() {}

    #if canImport(UIKit)
    // any PDFExportable：无 associated type / Self 约束的协议作为集合元素，
    // 允许异构集合（不同 PDFExportable 实现类型混传），见 CLAUDE.md Exception 2。
    /// 异步生成包含指定题目的 PDF 数据，支持中途取消
    /// 格式：每页一般 2-3 题，留出空白位置便于重做
    public func createPDF(from items: [any PDFExportable], imageProvider: @Sendable @escaping (String) -> UIImage?) async throws -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "SnapDrill App",
            kCGPDFContextAuthor: "SnapDrill User"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 595.2 // A4 width
        let pageHeight = 841.8 // A4 height
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        // 渲染包含可能取消的操作
        var renderError: Error?

        let data = renderer.pdfData { (context) in
            do {
                // Title Page
                context.beginPage()
                drawTitlePage(context: context.cgContext, rect: pageRect)

                // Items
                let itemsPerPage = 2
                let chunks = items.chunked(into: itemsPerPage)

                for chunk in chunks {
                    // Check for cooperative cancellation during the loop
                    if Task.isCancelled {
                        throw CancellationError()
                    }
                    // autoreleasepool 确保每页渲染后释放图片位图和 CoreGraphics 临时对象，
                    // 避免 50+ 题导出时全部堆积在内存导致 OOM
                    try autoreleasepool {
                        context.beginPage()
                        drawItemsPage(context: context.cgContext, rect: pageRect, items: chunk, imageProvider: imageProvider)
                    }
                }
            } catch {
                renderError = error
            }
        }

        if let renderError {
            throw renderError
        }

        return data
    }

    // MARK: - Drawings

    private func drawTitlePage(context: CGContext, rect: CGRect) {
        let title = L10n.Export.pdfTitle
        let font = UIFont.systemFont(ofSize: 36, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]

        let size = title.size(withAttributes: attrs)
        let x = (rect.width - size.width) / 2
        let y = (rect.height - size.height) / 2

        (title as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: attrs)

        let subtitle = L10n.Export.pdfGenerationDate(Date().formatted(date: .abbreviated, time: .shortened))
        let subFont = UIFont.systemFont(ofSize: 14)
        let subAttrs: [NSAttributedString.Key: Any] = [.font: subFont, .foregroundColor: UIColor.gray]
        let subSize = subtitle.size(withAttributes: subAttrs)
         (subtitle as NSString).draw(at: CGPoint(x: (rect.width - subSize.width) / 2, y: y + size.height + 10), withAttributes: subAttrs)
    }

    private func drawItemsPage(context: CGContext, rect: CGRect, items: [any PDFExportable], imageProvider: @Sendable (String) -> UIImage?) {
        let margin: CGFloat = 40
        let availableHeight = rect.height - margin * 2
        let itemHeight = availableHeight / 2 // Half page per item

        for (index, item) in items.enumerated() {
            let yOffset = margin + CGFloat(index) * itemHeight
            let contentRect = CGRect(x: margin, y: yOffset, width: rect.width - margin * 2, height: itemHeight - 20)

            drawItem(context: context, rect: contentRect, item: item, imageProvider: imageProvider)
        }
    }

    private func drawItem(context: CGContext, rect: CGRect, item: any PDFExportable, imageProvider: @Sendable (String) -> UIImage?) {
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

        // 绘制题目文字（内容可选，仅当有内容且有空间时绘制）
        if let contentText = item.content, textYOffset < rect.maxY {
            let textRect = CGRect(x: rect.minX, y: textYOffset, width: rect.width, height: rect.height - (textYOffset - rect.minY))

            let paraStyle = NSMutableParagraphStyle()
            paraStyle.lineBreakMode = .byTruncatingTail
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .paragraphStyle: paraStyle
            ]

            (contentText as NSString).draw(in: textRect, withAttributes: attrs)
        }
    }
    #else
    public func createPDF(from items: [any PDFExportable], imageProvider: @Sendable @escaping (String) -> Any?) async throws -> Data {
        // Fallback for non-iOS platforms
        return Data()
    }
    #endif
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
