import CoreGraphics
import Foundation

/// Supported physical paper formats for PDF generation and AirPrint (PRD §3.1, §8.5).
enum PaperSize: String, CaseIterable, Identifiable, Codable, Sendable {
    case a4
    case b5
    case letter

    var id: String { rawValue }

    /// Size in PDF points (72 points per inch).
    var pointSize: CGSize {
        switch self {
        case .a4: return CGSize(width: 595.28, height: 841.89)
        case .b5: return CGSize(width: 498.90, height: 708.66)
        case .letter: return CGSize(width: 612.0, height: 792.0)
        }
    }

    var localizedTitle: String {
        switch self {
        case .a4: return String(localized: "A4 (210 × 297 mm)")
        case .b5: return String(localized: "B5 (176 × 250 mm)")
        case .letter: return String(localized: "US Letter")
        }
    }

    var shortLabel: String {
        switch self {
        case .a4: return "A4"
        case .b5: return "B5"
        case .letter: return "Letter"
        }
    }

    /// Selects regional default paper size based on user locale (PRD §8.5).
    static func defaultForLocale(_ locale: Locale = .current) -> PaperSize {
        let regionCode = locale.region?.identifier.uppercased() ?? ""
        if regionCode == "US" || regionCode == "CA" {
            return .letter
        }
        if regionCode == "JP" || regionCode == "KR" {
            return .b5
        }
        return .a4
    }
}

/// Controls where reference answers appear in exported PDFs (PRD F-51).
enum AnswerPlacement: String, CaseIterable, Identifiable, Codable, Sendable {
    case endAppendix
    case inlineBelow
    case none

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .endAppendix: return String(localized: "Answers at End")
        case .inlineBelow: return String(localized: "Below Each Question")
        case .none: return String(localized: "Questions Only")
        }
    }
}

/// Blank writing space left underneath each problem for redoing on paper (PRD §8.5, F-51).
enum BlankSpaceSize: String, CaseIterable, Identifiable, Codable, Sendable {
    case compact
    case standard
    case generous

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .compact: return String(localized: "Compact")
        case .standard: return String(localized: "Standard")
        case .generous: return String(localized: "Generous")
        }
    }

    var points: CGFloat {
        switch self {
        case .compact: return 56
        case .standard: return 110
        case .generous: return 180
        }
    }
}

/// Configuration driving PDF generation; Pro gating resolves effective options cleanly.
struct PDFExportOptions: Sendable, Equatable {
    var title: String
    var paperSize: PaperSize
    var useCleanedImages: Bool
    var answerPlacement: AnswerPlacement
    var blankSpace: BlankSpaceSize
    var includeFooterWatermark: Bool

    static func p0Default(title: String, paperSize: PaperSize, includeWatermark: Bool) -> PDFExportOptions {
        PDFExportOptions(
            title: title,
            paperSize: paperSize,
            useCleanedImages: true,
            answerPlacement: .endAppendix,
            blankSpace: .standard,
            includeFooterWatermark: includeWatermark
        )
    }

    /// PRD §8.5 default PDF title combining Subject name and localized export date.
    static func defaultTitle(subjectName: String?, date: Date = .now) -> String {
        let base = (subjectName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            ? subjectName!
            : String(localized: "SnapDrill Practice Sheet")
        let formattedDate = date.formatted(date: .abbreviated, time: .omitted)
        return "\(base) · \(formattedDate)"
    }
}

/// Value-type problem payload passed into PDFExportServing without coupling renderer to SwiftData context.
struct PDFQuestionPayload: Sendable, Identifiable {
    let id: UUID
    let index: Int
    let subjectName: String
    let imageData: Data?
    let answerText: String
    let answerImageDatas: [Data]
    let causeLabels: [String]
    let notes: String
    let createdAt: Date
}
