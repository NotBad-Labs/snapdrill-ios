import PDFKit
import UIKit
import XCTest
@testable import SnapDrill

final class PDFExportServiceTests: XCTestCase {
    private func makeQuestionImageData(height: CGFloat = 340, color: UIColor = .white) -> Data {
        let size = CGSize(width: 800, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
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

    func testLong2000CharAnswerAndThreeAnswerImagesPaginateWithoutTruncation() throws {
        let service = PDFExportService()
        let qImg = makeQuestionImageData(height: 300)
        let ansImg1 = makeQuestionImageData(height: 360, color: .systemRed)
        let ansImg2 = makeQuestionImageData(height: 360, color: .systemBlue)
        let ansImg3 = makeQuestionImageData(height: 360, color: .systemGreen)

        let longPrefix = String(repeating: "数学解析步骤推导练习 · Step-by-step derivation across quadratic intervals. ", count: 36)
        let firstLongAnswer = String(longPrefix.prefix(1975)) + "\nTAILMARKER2000"
        let secondLongAnswer = String(longPrefix.prefix(1760)) + "\nTAILMARKERSECOND"

        let payloads = [
            PDFQuestionPayload(
                id: UUID(),
                index: 1,
                subjectName: "Physics",
                imageData: qImg,
                answerText: firstLongAnswer,
                answerImageDatas: [ansImg1, ansImg2, ansImg3],
                causeLabels: ["Concept Unclear"],
                notes: "Review full working",
                createdAt: .now
            ),
            PDFQuestionPayload(
                id: UUID(),
                index: 2,
                subjectName: "Physics",
                imageData: qImg,
                answerText: secondLongAnswer,
                answerImageDatas: [ansImg1, ansImg2],
                causeLabels: ["Calculation Error"],
                notes: "Verify units at end",
                createdAt: .now
            )
        ]

        let options = PDFExportOptions.p0Default(
            title: PDFExportOptions.defaultTitle(subjectName: "Physics"),
            paperSize: .b5,
            includeWatermark: true
        )
        XCTAssertTrue(options.title.contains("Physics"))
        XCTAssertEqual(PDFExportService.sanitizedFilename("Math/Quiz:1*?"), "Math-Quiz-1--")

        let data = try service.renderPDFData(questions: payloads, options: options)
        let doc = try XCTUnwrap(PDFDocument(data: data))
        XCTAssertGreaterThanOrEqual(doc.pageCount, 4)

        var fullExtracted = ""
        for idx in 0..<doc.pageCount {
            fullExtracted += "\n" + (doc.page(at: idx)?.string ?? "")
        }
        let compactExtracted = fullExtracted
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()

        XCTAssertTrue(compactExtracted.contains("TAILMARKER2000"))
        XCTAssertTrue(compactExtracted.contains("TAILMARKERSECOND"))
        XCTAssertTrue(fullExtracted.contains("Review full working"))
        XCTAssertTrue(fullExtracted.contains("Verify units at end"))

        // Verify ALL 2 question images + 3 answer images (Q1) + 2 answer images (Q2) = 7 Image XObjects rendered in PDF
        XCTAssertGreaterThanOrEqual(countImageXObjects(in: data), 7)
    }

    func testInlineBelowLayoutTemporaryFileAndEmptySelectionError() throws {
        let service = PDFExportService()

        // Empty selection must throw PDFExportError.emptySelection
        let emptyOptions = PDFExportOptions.p0Default(title: "Empty", paperSize: .a4, includeWatermark: false)
        do {
            _ = try service.renderPDFData(questions: [], options: emptyOptions)
            XCTFail("Expected PDFExportError.emptySelection")
        } catch let error as PDFExportError {
            if case .emptySelection = error {
                // Expected
            } else {
                XCTFail("Unexpected PDFExportError: \(error)")
            }
        }

        let qImg = makeQuestionImageData(height: 260)
        let ans1 = makeQuestionImageData(height: 240, color: .systemRed)
        let ans2 = makeQuestionImageData(height: 240, color: .systemBlue)
        let ans3 = makeQuestionImageData(height: 240, color: .systemGreen)

        let longAnswer = String(repeating: "多步骤解析：先移项再配方验证判别式。", count: 90) + "\nINLINETAILMARK"
        let longTitle = "高三数学冲刺错题汇编 · 函数导数与圆锥曲线综合专项复习训练卷"
        let payload = PDFQuestionPayload(
            id: UUID(),
            index: 1,
            subjectName: "数学",
            imageData: qImg,
            answerText: longAnswer,
            answerImageDatas: [ans1, ans2, ans3],
            causeLabels: ["计算失误"],
            notes: "InlineNoteMark",
            createdAt: .now
        )

        let inlineOptions = PDFExportOptions(
            title: longTitle,
            paperSize: .a4,
            useCleanedImages: true,
            answerPlacement: .inlineBelow,
            blankSpace: .standard,
            includeFooterWatermark: false
        )

        let data = try service.renderPDFData(questions: [payload], options: inlineOptions)
        let doc = try XCTUnwrap(PDFDocument(data: data))
        XCTAssertGreaterThanOrEqual(doc.pageCount, 2)

        var allText = ""
        for idx in 0..<doc.pageCount {
            allText += "\n" + (doc.page(at: idx)?.string ?? "")
        }
        let compact = allText.components(separatedBy: .whitespacesAndNewlines).joined()
        XCTAssertTrue(compact.contains("INLINETAILMARK"))
        XCTAssertTrue(allText.contains("InlineNoteMark"))
        XCTAssertTrue(compact.contains("圆锥曲线综合专项复习训练卷"))
        XCTAssertGreaterThanOrEqual(countImageXObjects(in: data), 4) // 1 question + 3 answer images

        // writeTemporaryPDF writes a valid PDF file with sanitized filename
        let tempOptions = PDFExportOptions(
            title: "Math/Quiz:Inline*?",
            paperSize: .a4,
            useCleanedImages: true,
            answerPlacement: .inlineBelow,
            blankSpace: .standard,
            includeFooterWatermark: false
        )
        let url = try service.writeTemporaryPDF(questions: [payload], options: tempOptions)
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertEqual(url.lastPathComponent, "Math-Quiz-Inline--.pdf")
        let written = try Data(contentsOf: url)
        XCTAssertEqual(String(data: written.prefix(5), encoding: .utf8), "%PDF-")
    }

    private func countImageXObjects(in pdfData: Data) -> Int {
        guard let provider = CGDataProvider(data: pdfData as CFData),
              let cgDoc = CGPDFDocument(provider),
              cgDoc.numberOfPages > 0 else {
            return 0
        }
        var count = 0
        for pageNumber in 1...cgDoc.numberOfPages {
            guard let page = cgDoc.page(at: pageNumber),
                  let pageDict = page.dictionary else { continue }
            var resources: CGPDFDictionaryRef?
            guard CGPDFDictionaryGetDictionary(pageDict, "Resources", &resources),
                  let resources else { continue }
            var xObjects: CGPDFDictionaryRef?
            guard CGPDFDictionaryGetDictionary(resources, "XObject", &xObjects),
                  let xObjects else { continue }
            CGPDFDictionaryApplyBlock(xObjects, { _, object, _ in
                var stream: CGPDFStreamRef?
                guard CGPDFObjectGetValue(object, .stream, &stream),
                      let stream,
                      let streamDict = CGPDFStreamGetDictionary(stream) else {
                    return true
                }
                var subtype: UnsafePointer<CChar>?
                if CGPDFDictionaryGetName(streamDict, "Subtype", &subtype),
                   let subtype,
                   String(cString: subtype) == "Image" {
                    count += 1
                }
                return true
            }, nil)
        }
        return count
    }
}
