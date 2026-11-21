import PDFKit
import UIKit
import XCTest
@testable import SnapDrill

final class PDFExportServiceTests: XCTestCase {
    private func makeQuestionImageData(height: CGFloat = 340) -> Data {
        let size = CGSize(width: 800, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor.black.setStroke()
            ctx.stroke(CGRect(x: 20, y: 20, width: size.width - 40, height: size.height - 40))
        }.jpegData(compressionQuality: 0.8)!
    }

    func testPDFRespectsPaperSizesPaginationAndWatermarkRules() throws {
        let service = PDFExportService()
        let imgData = makeQuestionImageData(height: 500)
        let payloads = (1...4).map { idx in
            PDFQuestionPayload(
                id: UUID(),
                index: idx,
                subjectName: "Math",
                imageData: imgData,
                answerText: "Answer for problem \(idx)",
                answerImageDatas: [],
                causeLabels: ["Careless"],
                notes: "Check boundary condition",
                createdAt: .now
            )
        }

        // B5 Free tier (with watermark & end appendix)
        let freeOptions = PDFExportOptions.p0Default(
            title: "Weekly Review",
            paperSize: .b5,
            includeWatermark: true
        )
        let freeData = try service.renderPDFData(questions: payloads, options: freeOptions)
        let freeDoc = try XCTUnwrap(PDFDocument(data: freeData))

        // 4 large problems + answer appendix must span multiple pages without clipping
        XCTAssertGreaterThanOrEqual(freeDoc.pageCount, 3)

        let page0Bounds = try XCTUnwrap(freeDoc.page(at: 0)?.bounds(for: .mediaBox))
        XCTAssertEqual(page0Bounds.width, PaperSize.b5.pointSize.width, accuracy: 1.0)
        XCTAssertEqual(page0Bounds.height, PaperSize.b5.pointSize.height, accuracy: 1.0)

        let page0Text = freeDoc.page(at: 0)?.string ?? ""
        XCTAssertTrue(page0Text.contains("SnapDrill"))

        let lastPageText = freeDoc.page(at: freeDoc.pageCount - 1)?.string ?? ""
        XCTAssertTrue(lastPageText.contains("Answer for problem 1"))

        // US Letter Pro tier (no watermark)
        let proOptions = PDFExportOptions(
            title: "Pro Sheet",
            paperSize: .letter,
            useCleanedImages: true,
            answerPlacement: .none,
            blankSpace: .compact,
            includeFooterWatermark: false
        )
        let proData = try service.renderPDFData(questions: payloads, options: proOptions)
        let proDoc = try XCTUnwrap(PDFDocument(data: proData))
        let proBounds = try XCTUnwrap(proDoc.page(at: 0)?.bounds(for: .mediaBox))
        XCTAssertEqual(proBounds.width, PaperSize.letter.pointSize.width, accuracy: 1.0)

        let proFirstPageText = proDoc.page(at: 0)?.string ?? ""
        XCTAssertFalse(proFirstPageText.contains("SnapDrill"))
    }
}
