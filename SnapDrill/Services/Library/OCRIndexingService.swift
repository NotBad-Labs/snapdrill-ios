import UIKit
import Vision

/// On-device CJK + English text extraction powering Pro keyword search (PRD §3.1, F-33).
enum OCRIndexingService {
    static func recognizeText(in imageData: Data) async -> String {
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            return ""
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["zh-Hans", "zh-Hant", "ja-JP", "ko-KR", "en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
            return lines.joined(separator: "\n")
        } catch {
            return ""
        }
    }
}
