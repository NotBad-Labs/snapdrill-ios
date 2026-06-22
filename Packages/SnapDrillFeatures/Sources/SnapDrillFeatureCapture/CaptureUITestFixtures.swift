//
//  CaptureUITestFixtures.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

#if DEBUG
import PDFKit
import UIKit

@MainActor
enum CaptureUITestFixtures {
    static func makeCaptureImage() -> UIImage {
        let size = CGSize(width: 900, height: 620)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemPurple.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let cardRect = CGRect(x: 80, y: 80, width: 740, height: 460)
            drawCard(
                title: "Capture",
                subtitle: "SnapDrill UI QA",
                color: .systemPurple,
                cardRect: cardRect
            )
        }
    }

    static func makePDFDocument() -> PDFDocument? {
        let pageBounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
        let data = renderer.pdfData { context in
            for page in 1...2 {
                context.beginPage()
                drawPage(
                    title: "PDF Fixture Page \(page)",
                    subtitle: "SnapDrill page picker QA",
                    color: page == 1 ? .systemRed : .systemOrange,
                    in: pageBounds
                )
            }
        }
        return PDFDocument(data: data)
    }

    static func makeScanPages() -> [UIImage] {
        [
            makeScanPage(number: 1, color: .systemGreen),
            makeScanPage(number: 2, color: .systemTeal)
        ]
    }

    private static func makeScanPage(number: Int, color: UIColor) -> UIImage {
        let size = CGSize(width: 900, height: 1240)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            drawPage(
                title: "Scan Fixture Page \(number)",
                subtitle: "SnapDrill scan picker QA",
                color: color,
                in: CGRect(origin: .zero, size: size)
            )
        }
    }

    private static func drawPage(title: String, subtitle: String, color: UIColor, in rect: CGRect) {
        color.setFill()
        UIBezierPath(rect: rect).fill()

        let inset = min(rect.width, rect.height) * 0.11
        let cardRect = rect.insetBy(dx: inset, dy: inset * 1.35)
        drawCard(title: title, subtitle: subtitle, color: color, cardRect: cardRect)
    }

    private static func drawCard(title: String, subtitle: String, color: UIColor, cardRect: CGRect) {
        UIColor.white.setFill()
        UIBezierPath(roundedRect: cardRect, cornerRadius: 28).fill()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 42, weight: .bold),
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        title.draw(
            in: CGRect(x: cardRect.minX + 24, y: cardRect.midY - 64, width: cardRect.width - 48, height: 62),
            withAttributes: titleAttributes
        )

        let captionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .medium),
            .foregroundColor: UIColor.secondaryLabel,
            .paragraphStyle: paragraph
        ]
        subtitle.draw(
            in: CGRect(x: cardRect.minX + 24, y: cardRect.midY + 6, width: cardRect.width - 48, height: 42),
            withAttributes: captionAttributes
        )
    }
}
#endif
