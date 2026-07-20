//
//  PDFExportService.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  PDF 导出服务，负责将错题数据渲染为 PDF 文档。
//

import Foundation
import UIKit
import PDFKit

/// 负责将错题列表生成 PDF 的服务类
///
/// 该服务提供将 `PDFExportable` 数组转换为 PDF 文件的能力，支持自定义图片提供者以加载本地或远程图片。
public final class PDFExportService: Sendable {
    /// 共享实例 - 建议使用 ServiceContainer 注入
    public static let shared = PDFExportService()

    /// 创建 PDF 导出服务实例；通常通过 `ServiceContainer` 注入
    public init() {}

    // MARK: - 常量

    private static let pageWidth: CGFloat = 595.2   // A4 width
    private static let pageHeight: CGFloat = 841.8  // A4 height
    private static let margin: CGFloat = 40
    private static let headerHeight: CGFloat = 25   // 页眉占用高度（含分隔线）
    private static let itemSpacing: CGFloat = 20
    // itemsPerPage 已移至 PDFExportOptions，此处不再硬编码

    // any PDFExportable：无 associated type / Self 约束的协议作为集合元素，
    // 允许异构集合（不同 PDFExportable 实现类型混传），见 CLAUDE.md Exception 2。
    /// 异步生成包含指定题目的 PDF 数据，支持中途取消
    /// 格式：每页一般 2 题，支持页眉页码、答案显示/隐藏、答题留白区
    public func createPDF(
        from items: [any PDFExportable],
        options: PDFExportOptions = .default,
        imageProvider: @Sendable @escaping (String) -> UIImage?
    ) async throws -> Data {
        guard !items.isEmpty else {
            throw PDFExportError.emptyInput
        }

        let pageRect = CGRect(x: 0, y: 0, width: Self.pageWidth, height: Self.pageHeight)
        let itemHeight = itemHeight(in: pageRect, options: options)
        guard itemHeight - Self.itemSpacing >= UIFont.systemFont(ofSize: 14).lineHeight else {
            throw PDFExportError.unsupportedItemDensity(itemsPerPage: options.itemsPerPage)
        }

        let pdfMetaData = [
            kCGPDFContextCreator: "SnapDrill App",
            kCGPDFContextAuthor: "SnapDrill User"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let chunks = items.chunked(into: options.itemsPerPage)
        let totalPages = chunks.count
        let categoryText = resolveCategory(from: items)
        let dateText = Date().formatted(date: .abbreviated, time: .omitted)

        // 渲染包含可能取消的操作
        var renderError: Error?

        let data = renderer.pdfData { context in
            for (pageIndex, chunk) in chunks.enumerated() {
                do {
                    // 每页先完成可渲染性预检，再 beginPage；失败时不创建空白页。
                    // 页级 autoreleasepool 保证已解码图片不会随整批导出持续累积。
                    try autoreleasepool {
                        let preparedItems = try prepareItems(
                            chunk,
                            startingAt: pageIndex * options.itemsPerPage,
                            imageProvider: imageProvider
                        )
                        context.beginPage()

                        // 页眉
                        if options.showHeader {
                            let headerInfo = PageHeaderInfo(
                                categoryText: categoryText,
                                dateText: dateText,
                                currentPage: pageIndex + 1,
                                totalPages: totalPages
                            )
                            drawPageHeader(context: context.cgContext, rect: pageRect, info: headerInfo)
                        }

                        drawItemsPage(
                            context: context.cgContext,
                            rect: pageRect,
                            items: preparedItems,
                            options: options
                        )
                    }
                } catch {
                    renderError = error
                    return
                }
            }
        }

        if let renderError {
            throw renderError
        }

        return data
    }

    private func prepareItems(
        _ items: [any PDFExportable],
        startingAt startIndex: Int,
        imageProvider: @Sendable (String) -> UIImage?
    ) throws -> [PreparedPDFItem] {
        try items.enumerated().map { offset, item in
            if Task.isCancelled {
                throw CancellationError()
            }

            let trimmedContent = item.content?.trimmingCharacters(in: .whitespacesAndNewlines)
            let content = trimmedContent?.isEmpty == false ? trimmedContent : nil
            let loadedImage = item.imagePath.flatMap(imageProvider)
            let image = loadedImage.flatMap { image -> UIImage? in
                let size = image.size
                guard size.width.isFinite,
                      size.height.isFinite,
                      size.width > 0,
                      size.height > 0 else {
                    return nil
                }
                return image
            }

            guard content != nil || image != nil else {
                throw PDFExportError.unreadableItem(position: startIndex + offset + 1)
            }

            return PreparedPDFItem(
                content: content,
                image: image,
                answerText: item.answerText
            )
        }
    }

    // MARK: - Category 解析

    /// 从导出条目中解析统一分类名称
    ///
    /// - 0 个分类 → 默认标题
    /// - 1 个分类 → 该分类名
    /// - 2+ 个分类 → "综合资料"
    func resolveCategory(from items: [any PDFExportable]) -> String {
        let categories = Set(items.compactMap(\.exportCategory))
        switch categories.count {
        case 0:
            return L10n.Export.defaultCategory
        case 1:
            return categories.first ?? L10n.Export.defaultCategory
        default:
            return L10n.Export.mixedCategory
        }
    }

    // MARK: - 页眉渲染

    /// 页眉渲染所需的上下文数据
    private struct PageHeaderInfo {
        let categoryText: String
        let dateText: String
        let currentPage: Int
        let totalPages: Int
    }

    private func drawPageHeader(context: CGContext, rect: CGRect, info: PageHeaderInfo) {
        let headerFont = UIFont.systemFont(ofSize: 9)
        let headerColor = UIColor.systemGray
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: headerColor
        ]

        // 左侧：「文档 · 2026-03-31」
        let leftText = "\(info.categoryText) · \(info.dateText)"
        (leftText as NSString).draw(
            at: CGPoint(x: Self.margin, y: 15),
            withAttributes: headerAttrs
        )

        // 右侧：「第 1/5 页」
        let rightText = L10n.Export.pageNumber(info.currentPage, info.totalPages)
        let rightSize = (rightText as NSString).size(withAttributes: headerAttrs)
        (rightText as NSString).draw(
            at: CGPoint(x: rect.width - Self.margin - rightSize.width, y: 15),
            withAttributes: headerAttrs
        )

        // 分隔线
        context.saveGState()
        context.setStrokeColor(UIColor.systemGray4.cgColor)
        context.setLineWidth(0.5)
        let lineY: CGFloat = 30
        context.move(to: CGPoint(x: Self.margin, y: lineY))
        context.addLine(to: CGPoint(x: rect.width - Self.margin, y: lineY))
        context.strokePath()
        context.restoreGState()
    }

    // MARK: - 内容页

    private func drawItemsPage(
        context: CGContext,
        rect: CGRect,
        items: [PreparedPDFItem],
        options: PDFExportOptions
    ) {
        let topOffset = options.showHeader ? Self.margin + Self.headerHeight : Self.margin
        let itemHeight = itemHeight(in: rect, options: options)

        for (index, item) in items.enumerated() {
            let yOffset = topOffset + CGFloat(index) * itemHeight
            let contentRect = CGRect(
                x: Self.margin,
                y: yOffset,
                width: rect.width - Self.margin * 2,
                height: itemHeight - Self.itemSpacing
            )

            drawItem(
                context: context,
                rect: contentRect,
                item: item,
                options: options
            )
        }
    }

    private func itemHeight(in rect: CGRect, options: PDFExportOptions) -> CGFloat {
        let topOffset = options.showHeader ? Self.margin + Self.headerHeight : Self.margin
        let availableHeight = rect.height - topOffset - Self.margin
        return availableHeight / CGFloat(options.itemsPerPage)
    }

    // MARK: - 单题渲染

    private func drawItem(
        context: CGContext,
        rect: CGRect,
        item: PreparedPDFItem,
        options: PDFExportOptions
    ) {
        // 根据渲染模式确定图片高度上限
        let imageMaxRatio: CGFloat
        if !options.hideAnswers && item.answerText != nil {
            imageMaxRatio = 0.50  // 显示答案时压缩图片，为答案文本留空间
        } else if options.hideAnswers && options.showBlankAnswerArea {
            imageMaxRatio = 0.45  // 答题留白模式，为虚线区域留空间
        } else {
            imageMaxRatio = 0.60  // 默认（与旧行为一致）
        }

        // 绘制图片（如果有）
        var currentY = rect.minY

        if let image = item.image {
            let imageMaxHeight = rect.height * imageMaxRatio
            let aspect = image.size.width / image.size.height

            var drawWidth = rect.width
            var drawHeight = drawWidth / aspect

            if drawHeight > imageMaxHeight {
                drawHeight = imageMaxHeight
                drawWidth = drawHeight * aspect
            }

            let imageRect = CGRect(x: rect.minX, y: currentY, width: drawWidth, height: drawHeight)
            image.draw(in: imageRect)

            currentY += drawHeight + 10
        }

        // 绘制题目文字（内容可选，仅当有内容且有空间时绘制）
        if let contentText = item.content, currentY < rect.maxY {
            let textRect = CGRect(
                x: rect.minX,
                y: currentY,
                width: rect.width,
                height: rect.maxY - currentY
            )

            let paraStyle = NSMutableParagraphStyle()
            paraStyle.lineBreakMode = .byWordWrapping
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .paragraphStyle: paraStyle
            ]

            let textSize = (contentText as NSString).boundingRect(
                with: CGSize(width: textRect.width, height: textRect.height),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attrs,
                context: nil
            )

            (contentText as NSString).draw(in: textRect, withAttributes: attrs)
            currentY += min(textSize.height, textRect.height) + 10
        }

        // 答案区域或答题留白区
        guard currentY < rect.maxY - 30 else { return }

        if !options.hideAnswers, let answer = item.answerText {
            // 显示答案：分隔线 + 答案文本
            drawAnswerSection(context: context, rect: rect, currentY: currentY, answerText: answer)
        } else if options.hideAnswers && options.showBlankAnswerArea {
            // 答题留白区：虚线框 + 引导线
            let blankRect = CGRect(
                x: rect.minX,
                y: currentY,
                width: rect.width,
                height: rect.maxY - currentY
            )
            drawBlankAnswerArea(context: context, rect: blankRect)
        }
    }

    // MARK: - 答案渲染

    private func drawAnswerSection(context: CGContext, rect: CGRect, currentY: CGFloat, answerText: String) {
        // 分隔线
        context.saveGState()
        context.setStrokeColor(UIColor.systemGray4.cgColor)
        context.setLineWidth(0.5)
        let lineInset: CGFloat = 20
        context.move(to: CGPoint(x: rect.minX + lineInset, y: currentY))
        context.addLine(to: CGPoint(x: rect.maxX - lineInset, y: currentY))
        context.strokePath()
        context.restoreGState()

        // 答案标签 + 文本
        let answerY = currentY + 8
        let answerRect = CGRect(
            x: rect.minX,
            y: answerY,
            width: rect.width,
            height: rect.maxY - answerY
        )

        let labeledAnswer = L10n.Export.answerLabel + answerText
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.lineBreakMode = .byWordWrapping
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: paraStyle
        ]

        (labeledAnswer as NSString).draw(in: answerRect, withAttributes: attrs)
    }

    // MARK: - 答题留白区

    private func drawBlankAnswerArea(context: CGContext, rect: CGRect) {
        guard rect.height >= 40 else { return }

        context.saveGState()

        // 虚线边框
        context.setStrokeColor(UIColor.systemGray4.cgColor)
        context.setLineWidth(0.5)
        context.setLineDash(phase: 0, lengths: [4, 4])
        context.stroke(rect.insetBy(dx: 0, dy: 2))

        // 重置虚线状态，引导线应为实线
        context.setLineDash(phase: 0, lengths: [])

        // 内部水平引导线（每 25pt 一条）
        context.setStrokeColor(UIColor.systemGray5.cgColor)
        context.setLineWidth(0.3)
        let lineSpacing: CGFloat = 25
        var lineY = rect.minY + lineSpacing + 2
        while lineY < rect.maxY - 5 {
            context.move(to: CGPoint(x: rect.minX + 8, y: lineY))
            context.addLine(to: CGPoint(x: rect.maxX - 8, y: lineY))
            context.strokePath()
            lineY += lineSpacing
        }

        context.restoreGState()
    }
}

private struct PreparedPDFItem {
    let content: String?
    let image: UIImage?
    let answerText: String?
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
