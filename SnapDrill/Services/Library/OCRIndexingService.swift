import UIKit
import Vision

/// On-device CJK + English text extraction powering Pro keyword search with off-MainActor execution & timeout guard (PRD §3.1, F-33).
enum OCRIndexingService {
    static func recognizeText(in imageData: Data, timeoutSeconds: Double = 2.5) async -> String {
        let task = Task.detached(priority: .userInitiated) { () -> String in
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

        return await withTaskGroup(of: String?.self) { group in
            group.addTask {
                await task.value
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(timeoutSeconds))
                return nil
            }

            for await candidate in group {
                if let text = candidate {
                    group.cancelAll()
                    return text
                } else {
                    task.cancel()
                    group.cancelAll()
                    return ""
                }
            }
            return ""
        }
    }
}
