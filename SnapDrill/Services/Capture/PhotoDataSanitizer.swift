import ImageIO
import UIKit

/// Strips EXIF GPS location metadata, normalizes orientation, and keeps stored images compact (PRD §8.2, §9).
struct PhotoDataSanitizer: PhotoDataSanitizing {
    func sanitize(_ imageData: Data, maxDimension: CGFloat = 2200) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }
        let normalized = normalizeOrientation(image, maxDimension: maxDimension)
        guard let cgImage = normalized.cgImage else {
            return normalized.jpegData(compressionQuality: 0.86)
        }

        // Write via ImageIO with an explicit clean metadata dictionary (no {GPS} / {TIFF} location tags)
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            "public.jpeg" as CFString,
            1,
            nil
        ) else {
            return normalized.jpegData(compressionQuality: 0.86)
        }

        let cleanProperties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.86
        ]
        CGImageDestinationAddImage(destination, cgImage, cleanProperties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return normalized.jpegData(compressionQuality: 0.86)
        }
        return mutableData as Data
    }

    private func normalizeOrientation(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return image }

        let longest = max(size.width, size.height)
        let scaleFactor = longest > maxDimension ? (maxDimension / longest) : 1.0
        let targetSize = CGSize(
            width: (size.width * scaleFactor).rounded(.down),
            height: (size.height * scaleFactor).rounded(.down)
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
