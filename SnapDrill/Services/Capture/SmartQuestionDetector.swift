import UIKit
import Vision

private actor DetectorTimeoutRaceGate<Value: Sendable> {
    private var continuation: CheckedContinuation<Value, Never>?
    private var resolvedValue: Value?

    func wait() async -> Value {
        if let resolvedValue {
            return resolvedValue
        }
        return await withCheckedContinuation { cont in
            if let resolvedValue {
                cont.resume(returning: resolvedValue)
            } else {
                continuation = cont
            }
        }
    }

    func resolve(with value: Value) -> Bool {
        guard resolvedValue == nil else { return false }
        resolvedValue = value
        continuation?.resume(returning: value)
        continuation = nil
        return true
    }
}

private final class CancellableQuestionRequestBox: @unchecked Sendable {
    private let lock = NSLock()
    private var request: VNRequest?
    private var isCancelled = false

    func attach(_ request: VNRequest) {
        lock.lock()
        let alreadyCancelled = isCancelled
        self.request = request
        lock.unlock()
        if alreadyCancelled {
            request.cancel()
        }
    }

    func cancel() {
        lock.lock()
        isCancelled = true
        let req = request
        lock.unlock()
        req?.cancel()
    }

    func clear() {
        lock.lock()
        request = nil
        lock.unlock()
    }
}

/// Pro F-06: Suggests question crop boxes on an exam page off MainActor with non-blocking timeout guard (M7).
struct SmartQuestionDetector: SmartQuestionDetecting {
    private let timeoutSeconds: Double

    init(timeoutSeconds: Double = 2.5) {
        self.timeoutSeconds = timeoutSeconds
    }

    func suggestBoxes(in imageData: Data, maxBoxes: Int) async -> [CaptureCropBox] {
        let gate = DetectorTimeoutRaceGate<[CaptureCropBox]>()
        let requestBox = CancellableQuestionRequestBox()
        let limit = timeoutSeconds

        let workTask = Task.detached(priority: .userInitiated) {
            let detected = await withTaskCancellationHandler {
                Self.performDetection(in: imageData, maxBoxes: maxBoxes, requestBox: requestBox)
            } onCancel: {
                requestBox.cancel()
            }
            _ = await gate.resolve(with: detected)
        }

        let timeoutTask = Task.detached(priority: .userInitiated) {
            try? await Task.sleep(for: .seconds(limit))
            guard !Task.isCancelled else { return }
            let won = await gate.resolve(with: [CaptureCropBox()])
            if won {
                requestBox.cancel()
                workTask.cancel()
            }
        }

        let result = await withTaskCancellationHandler {
            await gate.wait()
        } onCancel: {
            requestBox.cancel()
            workTask.cancel()
            timeoutTask.cancel()
            Task { _ = await gate.resolve(with: [CaptureCropBox()]) }
        }
        timeoutTask.cancel()
        return result
    }

    private static func performDetection(
        in imageData: Data,
        maxBoxes: Int,
        requestBox: CancellableQuestionRequestBox
    ) -> [CaptureCropBox] {
        guard !Task.isCancelled,
              let uiImage = UIImage(data: imageData),
              let cgImage = uiImage.cgImage else {
            return [CaptureCropBox()]
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .fast
        request.usesLanguageCorrection = false
        requestBox.attach(request)
        defer { requestBox.clear() }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            guard !Task.isCancelled,
                  let observations = request.results,
                  !observations.isEmpty else {
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

            return paddedBoxes.isEmpty ? [CaptureCropBox()] : paddedBoxes
        } catch {
            return [CaptureCropBox()]
        }
    }
}
