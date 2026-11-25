import CoreText
import Foundation
import PDFKit
import UIKit

/// Renders print-ready A4/B5/Letter practice sheets with strict anti-page-splitting for problem images,
/// full multi-page pagination for 2,000-character answers & all 3 answer images, and PRD-compliant watermarks (PRD §8.5, AC-07).
struct PDFExportService: PDFExportServing {
    func renderPDFData(questions: [PDFQuestionPayload], options: PDFExportOptions) throws -> Data {
        guard !questions.isEmpty else {
            throw PDFExportError.emptySelection
        }

        let pageSize = options.paperSize.pointSize
        let marginX: CGFloat = 38
        let marginTop: CGFloat = 40
        let footerReserve: CGFloat = 40
        let contentWidth = pageSize.width - marginX * 2
        let maxContentY = pageSize.height - footerReserve

        let bounds = CGRect(origin: .zero, size: pageSize)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: options.title,
            kCGPDFContextCreator as String: "SnapDrill"
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)

        let data = renderer.pdfData { pdfContext in
            var pageNumber = 1

            func startNewPage() {
                drawFooter(
                    pageNumber: pageNumber,
                    pageSize: pageSize,
                    includeWatermark: options.includeFooterWatermark
                )
                pageNumber += 1
                pdfContext.beginPage()
            }

            pdfContext.beginPage()
            var cursorY = drawDocumentHeader(
                title: options.title,
                questionCount: questions.count,
                paperLabel: options.paperSize.shortLabel,
                x: marginX,
                y: marginTop,
                width: contentWidth
            )

            for question in questions {
                let decodedImage = question.imageData.flatMap { UIImage(data: $0) }
                let fittedImageSize = fitImageSize(
                    decodedImage?.size,
                    maxWidth: contentWidth,
                    maxHeight: (maxContentY - marginTop) * 0.62
                )

                let headerHeight: CGFloat = 22
                let trailingReserve: CGFloat = (options.answerPlacement == .none || options.answerPlacement == .endAppendix)
                    ? options.blankSpace.points
                    : 20
                let requiredStemHeight = headerHeight + fittedImageSize.height + trailingReserve + 16

                // Strictly avoid splitting a single problem image across pages (PRD §8.5)
                if cursorY + requiredStemHeight > maxContentY && cursorY > marginTop + 20 {
                    startNewPage()
                    cursorY = marginTop
                }

                // Draw problem header label
                let badgeText = "\(question.index).  \(question.subjectName)"
                let badgeAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11.5, weight: .semibold),
                    .foregroundColor: UIColor(red: 0.173, green: 0.337, blue: 0.537, alpha: 1.0)
                ]
                (badgeText as NSString).draw(at: CGPoint(x: marginX, y: cursorY), withAttributes: badgeAttrs)
                cursorY += headerHeight

                // Draw question image
                if let decodedImage, fittedImageSize.height > 0 {
                    if cursorY + fittedImageSize.height > maxContentY && cursorY > marginTop + 20 {
                        startNewPage()
                        cursorY = marginTop
                    }
                    let imageRect = CGRect(
                        x: marginX,
                        y: cursorY,
                        width: fittedImageSize.width,
                        height: fittedImageSize.height
                    )
                    decodedImage.draw(in: imageRect)
                    UIColor(red: 0.85, green: 0.83, blue: 0.78, alpha: 0.9).setStroke()
                    let border = UIBezierPath(roundedRect: imageRect, cornerRadius: 3)
                    border.lineWidth = 0.6
                    border.stroke()
                    cursorY += fittedImageSize.height + 10
                }

                if options.answerPlacement == .inlineBelow {
                    let body = buildAnswerSummaryText(question: question)
                    if !body.isEmpty {
                        let prefix = String(localized: "Answer")
                        cursorY = drawPaginatedText(
                            "\(prefix): \(body)",
                            attrs: [
                                .font: UIFont.systemFont(ofSize: 10.5),
                                .foregroundColor: UIColor(red: 0.28, green: 0.28, blue: 0.30, alpha: 1.0)
                            ],
                            x: marginX,
                            startY: cursorY,
                            width: contentWidth,
                            marginTop: marginTop,
                            maxContentY: maxContentY,
                            cgContext: pdfContext.cgContext,
                            onPageBreak: { startNewPage() }
                        )
                        cursorY += 6
                    }

                    for ansData in question.answerImageDatas {
                        guard let ansImage = UIImage(data: ansData) else { continue }
                        let fitted = fitImageSize(ansImage.size, maxWidth: contentWidth * 0.55, maxHeight: 120)
                        if cursorY + fitted.height > maxContentY {
                            startNewPage()
                            cursorY = marginTop
                        }
                        ansImage.draw(in: CGRect(x: marginX, y: cursorY, width: fitted.width, height: fitted.height))
                        cursorY += fitted.height + 8
                    }
                    cursorY += 10
                } else {
                    drawPracticeBlankArea(
                        x: marginX,
                        y: cursorY,
                        width: contentWidth,
                        height: options.blankSpace.points
                    )
                    cursorY += options.blankSpace.points + 14
                }
            }

            // Appendix page for answers when placement == .endAppendix (PRD §8.5 default)
            let questionsWithDetails = questions.filter {
                !$0.answerText.isEmpty || !$0.answerImageDatas.isEmpty || !$0.causeLabels.isEmpty || !$0.notes.isEmpty
            }

            if options.answerPlacement == .endAppendix && !questionsWithDetails.isEmpty {
                startNewPage()
                cursorY = drawAppendixHeader(x: marginX, y: marginTop, width: contentWidth)

                for question in questionsWithDetails {
                    // Keep index title + first lines together if near page bottom
                    if cursorY + 46 > maxContentY {
                        startNewPage()
                        cursorY = marginTop
                    }

                    let titleAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 11.5, weight: .semibold),
                        .foregroundColor: UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0)
                    ]
                    let header = "\(question.index). [\(question.subjectName)]"
                    (header as NSString).draw(at: CGPoint(x: marginX, y: cursorY), withAttributes: titleAttrs)
                    cursorY += 18

                    let body = buildAnswerSummaryText(question: question)
                    if !body.isEmpty {
                        cursorY = drawPaginatedText(
                            body,
                            attrs: [
                                .font: UIFont.systemFont(ofSize: 10.5),
                                .foregroundColor: UIColor(red: 0.25, green: 0.25, blue: 0.27, alpha: 1.0)
                            ],
                            x: marginX + 12,
                            startY: cursorY,
                            width: contentWidth - 12,
                            marginTop: marginTop,
                            maxContentY: maxContentY,
                            cgContext: pdfContext.cgContext,
                            onPageBreak: { startNewPage() }
                        )
                        cursorY += 6
                    }

                    // Render ALL up to 3 answer images cleanly with page breaks (M4)
                    for ansData in question.answerImageDatas {
                        guard let ansImage = UIImage(data: ansData) else { continue }
                        let fitted = fitImageSize(ansImage.size, maxWidth: (contentWidth - 12) * 0.62, maxHeight: 130)
                        if cursorY + fitted.height > maxContentY {
                            startNewPage()
                            cursorY = marginTop
                        }
                        ansImage.draw(in: CGRect(x: marginX + 12, y: cursorY, width: fitted.width, height: fitted.height))
                        cursorY += fitted.height + 8
                    }

                    cursorY += 12
                }
            }

            drawFooter(
                pageNumber: pageNumber,
                pageSize: pageSize,
                includeWatermark: options.includeFooterWatermark
            )
        }

        return data
    }

    func writeTemporaryPDF(questions: [PDFQuestionPayload], options: PDFExportOptions) throws -> URL {
        let data = try renderPDFData(questions: questions, options: options)
        let safeTitle = Self.sanitizedFilename(options.title)
        let filename = (safeTitle.isEmpty ? "SnapDrill-Export" : safeTitle) + ".pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: [.atomic])
        return url
    }

    static func sanitizedFilename(_ raw: String) -> String {
        let illegal = CharacterSet(charactersIn: "/\\:*?\"<>|\r\n\t")
        let parts = raw.components(separatedBy: illegal)
        return parts.joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Pure CoreText Paginated Drawing (M6)

    private func drawPaginatedText(
        _ text: String,
        attrs: [NSAttributedString.Key: Any],
        x: CGFloat,
        startY: CGFloat,
        width: CGFloat,
        marginTop: CGFloat,
        maxContentY: CGFloat,
        cgContext: CGContext,
        onPageBreak: () -> Void
    ) -> CGFloat {
        var ctAttrs = attrs
        if let uiColor = attrs[.foregroundColor] as? UIColor {
            ctAttrs[NSAttributedString.Key(kCTForegroundColorAttributeName as String)] = uiColor.cgColor
        }
        let attrString = NSAttributedString(string: text, attributes: ctAttrs)
        guard attrString.length > 0 else { return startY }

        let framesetter = CTFramesetterCreateWithAttributedString(attrString)
        var currentY = startY
        var location = 0

        while location < attrString.length {
            var availableHeight = maxContentY - currentY
            if availableHeight < 20 {
                onPageBreak()
                currentY = marginTop
                availableHeight = maxContentY - currentY
            }

            let boxHeight = max(20, availableHeight - 6)
            let boxPath = CGPath(rect: CGRect(x: 0, y: 0, width: width, height: boxHeight), transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(location, 0), boxPath, nil)
            let visible = CTFrameGetVisibleStringRange(frame)

            guard visible.length > 0 else {
                if currentY > marginTop + 1 {
                    onPageBreak()
                    currentY = marginTop
                    continue
                } else {
                    break
                }
            }

            cgContext.saveGState()
            cgContext.textMatrix = .identity
            cgContext.translateBy(x: x, y: currentY + boxHeight)
            cgContext.scaleBy(x: 1.0, y: -1.0)
            CTFrameDraw(frame, cgContext)
            cgContext.restoreGState()

            let ctLines = CTFrameGetLines(frame) as? [CTLine] ?? []
            var drawnHeight: CGFloat = 0
            if let lastLine = ctLines.last {
                var origins = [CGPoint](repeating: .zero, count: ctLines.count)
                CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), &origins)
                var ascent: CGFloat = 0
                var descent: CGFloat = 0
                var leading: CGFloat = 0
                CTLineGetTypographicBounds(lastLine, &ascent, &descent, &leading)
                drawnHeight = min(boxHeight, max(0, (boxHeight - origins[ctLines.count - 1].y) + descent + leading))
            }

            currentY += ceil(drawnHeight) + 6
            location = visible.location + visible.length

            if location < attrString.length {
                onPageBreak()
                currentY = marginTop
            }
        }

        return currentY
    }

    // MARK: - Drawing Helpers

    private func drawDocumentHeader(
        title: String,
        questionCount: Int,
        paperLabel: String,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat
    ) -> CGFloat {
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .bold),
            .foregroundColor: UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0)
        ]
        let titleNS = title as NSString
        let measuredTitle = titleNS.boundingRect(
            with: CGSize(width: width, height: 120),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: titleAttrs,
            context: nil
        )
        let titleHeight = max(22, ceil(measuredTitle.height))
        titleNS.draw(
            with: CGRect(x: x, y: y, width: width, height: titleHeight),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: titleAttrs,
            context: nil
        )

        let dateText = Date().formatted(date: .abbreviated, time: .omitted)
        let subtitle = String(localized: "\(questionCount) questions · \(dateText) · \(paperLabel)")
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor(red: 0.42, green: 0.40, blue: 0.37, alpha: 1.0)
        ]
        let subtitleY = y + titleHeight + 4
        (subtitle as NSString).draw(at: CGPoint(x: x, y: subtitleY), withAttributes: subAttrs)

        let lineY = subtitleY + 19
        UIColor(red: 0.85, green: 0.82, blue: 0.76, alpha: 1.0).setStroke()
        let line = UIBezierPath()
        line.move(to: CGPoint(x: x, y: lineY))
        line.addLine(to: CGPoint(x: x + width, y: lineY))
        line.lineWidth = 0.8
        line.stroke()

        return lineY + 14
    }

    private func drawAppendixHeader(x: CGFloat, y: CGFloat, width: CGFloat) -> CGFloat {
        let title = String(localized: "Reference Answers & Notes")
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor(red: 0.173, green: 0.337, blue: 0.537, alpha: 1.0)
        ]
        (title as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: titleAttrs)

        let lineY = y + 28
        UIColor(red: 0.85, green: 0.82, blue: 0.76, alpha: 1.0).setStroke()
        let line = UIBezierPath()
        line.move(to: CGPoint(x: x, y: lineY))
        line.addLine(to: CGPoint(x: x + width, y: lineY))
        line.lineWidth = 0.8
        line.stroke()
        return lineY + 14
    }

    private func drawPracticeBlankArea(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        UIColor(red: 0.88, green: 0.86, blue: 0.82, alpha: 0.85).setStroke()
        let spacing: CGFloat = 24
        var lineY = y + spacing
        while lineY < y + height - 6 {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x, y: lineY))
            path.addLine(to: CGPoint(x: x + width, y: lineY))
            path.lineWidth = 0.45
            let pattern: [CGFloat] = [2, 3]
            path.setLineDash(pattern, count: 2, phase: 0)
            path.stroke()
            lineY += spacing
        }
    }

    private func drawFooter(pageNumber: Int, pageSize: CGSize, includeWatermark: Bool) {
        let footerY = pageSize.height - 24
        let pageAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.5),
            .foregroundColor: UIColor(white: 0.55, alpha: 1.0)
        ]
        let pageStr = "\(pageNumber)" as NSString
        let pageW = pageStr.size(withAttributes: pageAttrs).width
        pageStr.draw(at: CGPoint(x: (pageSize.width - pageW) / 2.0, y: footerY), withAttributes: pageAttrs)

        // PRD §8.5: Free tier footer watermark strictly 8pt light gray at bottom-right without covering content
        if includeWatermark {
            let wmAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8.0, weight: .medium),
                .foregroundColor: UIColor(white: 0.62, alpha: 0.85)
            ]
            let wm = "SnapDrill" as NSString
            let wmSize = wm.size(withAttributes: wmAttrs)
            wm.draw(at: CGPoint(x: pageSize.width - 38 - wmSize.width, y: footerY), withAttributes: wmAttrs)
        }
    }

    private func buildAnswerSummaryText(question: PDFQuestionPayload) -> String {
        var parts: [String] = []
        if !question.causeLabels.isEmpty {
            parts.append("[\(question.causeLabels.joined(separator: " / "))]")
        }
        if !question.answerText.isEmpty {
            parts.append(question.answerText)
        }
        if !question.notes.isEmpty {
            let notePrefix = String(localized: "Note")
            parts.append("\(notePrefix): \(question.notes)")
        }
        return parts.joined(separator: "\n")
    }

    private func fitImageSize(_ originalSize: CGSize?, maxWidth: CGFloat, maxHeight: CGFloat) -> CGSize {
        guard let originalSize, originalSize.width > 0, originalSize.height > 0 else {
            return .zero
        }
        let scale = min(maxWidth / originalSize.width, maxHeight / originalSize.height)
        return CGSize(
            width: (originalSize.width * scale).rounded(.down),
            height: (originalSize.height * scale).rounded(.down)
        )
    }
}
