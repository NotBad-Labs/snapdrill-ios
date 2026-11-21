import Foundation

enum PDFExportError: Error, LocalizedError, Sendable {
    case emptySelection
    case renderingFailed

    var errorDescription: String? {
        switch self {
        case .emptySelection:
            return String(localized: "Select at least one mistake to export as PDF.")
        case .renderingFailed:
            return String(localized: "Could not render the PDF document.")
        }
    }
}

/// Protocol-first PDF generation contract (ARCHITECTURE §4.3, PRD §8.5).
protocol PDFExportServing: Sendable {
    func renderPDFData(questions: [PDFQuestionPayload], options: PDFExportOptions) throws -> Data
    func writeTemporaryPDF(questions: [PDFQuestionPayload], options: PDFExportOptions) throws -> URL
}
