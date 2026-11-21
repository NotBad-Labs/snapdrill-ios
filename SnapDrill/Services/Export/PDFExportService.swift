import Foundation
import PDFKit
import UIKit

/// Renders print-ready A4/B5/Letter practice sheets with strict anti-page-splitting and answer appendix (PRD §8.5, AC-07).
struct PDFExportService: PDFExportServing {
    func renderPDFData(questions: [PDFQuestionPayload], options: PDFExportOptions) throws -> Data {
        guard !questions.isEmpty else {
            throw PDFExportError.emptySelection
        }

        let pageSize = options.paperSize.pointSize
        let marginX: CGFloat = 38
        let marginTop: CGFloat = 40
        let footerReserve: CGFloat = 38
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
                    maxHeight: (pageSize.height - marginTop - footerReserve) * 0.62
                )

                let headerHeight: CGFloat = 22
                let inlineExtraHeight: CGFloat = options.answerPlacement == .inlineBelow
                    ? estimateAnswerBlockHeight(question: question, width: contentWidth)
                    : (options.blankSpace.points)

                let totalBlockHeight = headerHeight + fittedImageSize.height + inlineExtraHeight + 16

                // Strictly avoid splitting a single problem image across pages (PRD §8.5)
                if cursorY + totalBlockHeight > maxContentY && cursorY > marginTop + 50 {
                    drawFooter(
                        pageNumber: pageNumber,
                        pageSize: pageSize,
                        includeWatermark: options.includeFooterWatermark
                    )
                    pageNumber += 1
                    pdfContext.beginPage()
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
                    cursorY += fittedImageSize.height + 8
                }

                // Draw inline answer or practice blank space
                if options.answerPlacement == .inlineBelow {
                    cursorY = drawInlineAnswer(
                        question: question,
                        x: marginX,
                        y: cursorY,
                        width: contentWidth
                    )
                    cursorY += 12
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
                drawFooter(
                    pageNumber: pageNumber,
                    pageSize: pageSize,
                    includeWatermark: options.includeFooterWatermark
                )
                pageNumber += 1
                pdfContext.beginPage()
                cursorY = drawAppendixHeader(x: marginX, y: marginTop, width: contentWidth)

                for question in questionsWithDetails {
                    let estHeight = estimateAnswerBlockHeight(question: question, width: contentWidth) + 28
                    if cursorY + estHeight > maxContentY && cursorY > marginTop + 40 {
                        drawFooter(
                            pageNumber: pageNumber,
                            pageSize: pageSize,
                            includeWatermark: options.includeFooterWatermark
                        )
                        pageNumber += 1
                        pdfContext.beginPage()
                        cursorY = marginTop
                    }

                    cursorY = drawAppendixEntry(
                        question: question,
                        x: marginX,
                        y: cursorY,
                        width: contentWidth
                    )
                    cursorY += 14
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
        let safeTitle = options.title
            .replacingOccurrences(of: "/", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let filename = (safeTitle.isEmpty ? "SnapDrill-Export" : safeTitle) + ".pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: [.atomic])
        return url
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
        (title as NSString).draw(in: CGRect(x: x, y: y, width: width, height: 26), withAttributes: titleAttrs)

        let dateText = Date().formatted(date: .abbreviated, time: .omitted)
        let subtitle = String(localized: "\(questionCount) questions · \(dateText) · \(paperLabel)")
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor(red: 0.42, green: 0.40, blue: 0.37, alpha: 1.0)
        ]
        (subtitle as NSString).draw(at: CGPoint(x: x, y: y + 25), withAttributes: subAttrs)

        let lineY = y + 44
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

    private func drawInlineAnswer(question: PDFQuestionPayload, x: CGFloat, y: CGFloat, width: CGFloat) -> CGFloat {
        let label = String(localized: "Answer")
        let body = buildAnswerSummaryText(question: question)
        let text = "\(label): \(body)"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10.5),
            .foregroundColor: UIColor(red: 0.28, green: 0.28, blue: 0.30, alpha: 1.0)
        ]
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: 180),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attrs,
            context: nil
        )
        (text as NSString).draw(in: CGRect(x: x, y: y, width: width, height: ceil(rect.height)), withAttributes: attrs)
        return y + ceil(rect.height) + 6
    }

    private func drawAppendixEntry(question: PDFQuestionPayload, x: CGFloat, y: CGFloat, width: CGFloat) -> CGFloat {
        var cursorY = y
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11.5, weight: .semibold),
            .foregroundColor: UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0)
        ]
        let header = "\(question.index). [\(question.subjectName)]"
        (header as NSString).draw(at: CGPoint(x: x, y: cursorY), withAttributes: titleAttrs)
        cursorY += 18

        let body = buildAnswerSummaryText(question: question)
        if !body.isEmpty {
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10.5),
                .foregroundColor: UIColor(red: 0.25, green: 0.25, blue: 0.27, alpha: 1.0)
            ]
            let bounding = (body as NSString).boundingRect(
                with: CGSize(width: width - 12, height: 240),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: bodyAttrs,
                context: nil
            )
            (body as NSString).draw(
                in: CGRect(x: x + 12, y: cursorY, width: width - 12, height: ceil(bounding.height)),
                withAttributes: bodyAttrs
            )
            cursorY += ceil(bounding.height) + 6
        }

        if let firstAnsData = question.answerImageDatas.first,
           let ansImage = UIImage(data: firstAnsData) {
            let fitted = fitImageSize(ansImage.size, maxWidth: width * 0.55, maxHeight: 110)
            ansImage.draw(in: CGRect(x: x + 12, y: cursorY, width: fitted.width, height: fitted.height))
            cursorY += fitted.height + 6
        }

        return cursorY
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

    private func estimateAnswerBlockHeight(question: PDFQuestionPayload, width: CGFloat) -> CGFloat {
        let summary = buildAnswerSummaryText(question: question)
        var height: CGFloat = 24
        if !summary.isEmpty {
            let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10.5)]
            let rect = (summary as NSString).boundingRect(
                with: CGSize(width: width - 12, height: 240),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attrs,
                context: nil
            )
            height += ceil(rect.height) + 8
        }
        if !question.answerImageDatas.isEmpty {
            height += 116
        }
        return height
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
