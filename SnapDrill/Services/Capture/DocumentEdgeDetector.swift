import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

/// Detects paper borders with Vision and performs perspective straightening with Core Image (PRD F-02).
struct DocumentEdgeDetector: DocumentDetecting {
    private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    func detectCorners(in imageData: Data) async -> QuadCorners {
        guard let uiImage = UIImage(data: imageData),
              let cgImage = uiImage.cgImage else {
            return .fullFrame
        }

        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 1
        request.minimumConfidence = 0.65
        request.minimumAspectRatio = 0.35
        request.maximumAspectRatio = 1.0
        request.minimumSize = 0.25

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            guard let observation = request.results?.first else {
                return .fullFrame
            }
            // Convert Vision bottom-left normalized coordinates to SwiftUI top-left normalized coordinates
            return QuadCorners(
                topLeft: CGPoint(x: observation.topLeft.x, y: 1.0 - observation.topLeft.y),
                topRight: CGPoint(x: observation.topRight.x, y: 1.0 - observation.topRight.y),
                bottomRight: CGPoint(x: observation.bottomRight.x, y: 1.0 - observation.bottomRight.y),
                bottomLeft: CGPoint(x: observation.bottomLeft.x, y: 1.0 - observation.bottomLeft.y)
            )
        } catch {
            return .fullFrame
        }
    }

    func applyPerspectiveCorrection(to imageData: Data, corners: QuadCorners) -> Data {
        // Fast path: if corners match default fullFrame within tolerance, avoid redundant re-encode
        if isNearlyFullFrame(corners) {
            return imageData
        }

        guard let uiImage = UIImage(data: imageData),
              let ciInput = CIImage(image: uiImage) else {
            return imageData
        }

        let extent = ciInput.extent
        guard extent.width > 10, extent.height > 10 else { return imageData }

        // Convert top-left normalized points to CIImage bottom-left pixel coordinates
        func ciPoint(_ normalized: CGPoint) -> CGPoint {
            CGPoint(
                x: extent.origin.x + normalized.x * extent.width,
                y: extent.origin.y + (1.0 - normalized.y) * extent.height
            )
        }

        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = ciInput
        filter.topLeft = ciPoint(corners.topLeft)
        filter.topRight = ciPoint(corners.topRight)
        filter.bottomRight = ciPoint(corners.bottomRight)
        filter.bottomLeft = ciPoint(corners.bottomLeft)

        guard let output = filter.outputImage,
              let cgResult = Self.ciContext.createCGImage(output, from: output.extent) else {
            return imageData
        }
        return UIImage(cgImage: cgResult).jpegData(compressionQuality: 0.88) ?? imageData
    }

    private func isNearlyFullFrame(_ corners: QuadCorners) -> Bool {
        let tolerance: CGFloat = 0.005
        let ref = QuadCorners.fullFrame
        return hypot(corners.topLeft.x - ref.topLeft.x, corners.topLeft.y - ref.topLeft.y) < tolerance &&
               hypot(corners.topRight.x - ref.topRight.x, corners.topRight.y - ref.topRight.y) < tolerance &&
               hypot(corners.bottomRight.x - ref.bottomRight.x, corners.bottomRight.y - ref.bottomRight.y) < tolerance &&
               hypot(corners.bottomLeft.x - ref.bottomLeft.x, corners.bottomLeft.y - ref.bottomLeft.y) < tolerance
    }
}
