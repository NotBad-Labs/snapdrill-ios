import UIKit
import Vision

/// Pro F-06: Suggests question crop boxes on an exam page by clustering Vision OCR text bands vertically.
struct SmartQuestionDetector: SmartQuestionDetecting {
    func suggestBoxes(in imageData: Data, maxBoxes: Int) async -> [CaptureCropBox] {
        guard let uiImage = UIImage(data: imageData),
              let cgImage = uiImage.cgImage else {
            return [CaptureCropBox()]
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .fast
        request.usesLanguageCorrection = false

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            guard let observations = request.results, !observations.isEmpty else {
                return [CaptureCropBox()]
            }

            // Convert Vision bounding boxes (bottom-left) to top-left normalized coordinates
            let rects = observations.map { obs -> CGRect in
                let b = obs.boundingBox
                return CGRect(
                    x: b.origin.x,
                    y: 1.0 - b.origin.y - b.height,
                    width: b.width,
                    height: b.height
                )
            }
            .sorted { $0.minY < $1.minY }

            // Cluster nearby vertical bands separated by larger whitespace gaps (> 4.5% of page height)
            var clusters: [CGRect] = []
            let verticalGapThreshold: CGFloat = 0.045

            for rect in rects {
                if let last = clusters.last, rect.minY - last.maxY <= verticalGapThreshold {
                    clusters[clusters.count - 1] = last.union(rect)
                } else {
                    clusters.append(rect)
                }
            }

            // Filter tiny noise slivers and add comfortable padding around each question cluster
            let paddedBoxes = clusters
                .filter { $0.height >= 0.03 && $0.width >= 0.08 }
                .prefix(maxBoxes)
                .map { cluster -> CaptureCropBox in
                    let padded = CGRect(
                        x: max(0.03, cluster.minX - 0.04),
                        y: max(0.02, cluster.minY - 0.025),
                        width: min(0.94, cluster.width + 0.08),
                        height: min(0.96, cluster.height + 0.05)
                    )
                    return CaptureCropBox(normalizedRect: padded)
                }

            return paddedBoxes.isEmpty ? [CaptureCropBox()] : Array(paddedBoxes)
        } catch {
            return [CaptureCropBox()]
        }
    }
}
