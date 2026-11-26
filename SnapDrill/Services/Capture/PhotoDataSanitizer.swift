import ImageIO
import UIKit

/// Strips EXIF GPS location metadata, normalizes orientation, and keeps stored images compact (PRD §8.2, §9).
/// Uses ImageIO downsampling at decode time so 48MP captures never allocate full-resolution bitmaps in memory.
struct PhotoDataSanitizer: PhotoDataSanitizing {
    func sanitize(_ imageData: Data, maxDimension: CGFloat = 2200) -> Data? {
        let downsampledCG = Self.decodeDownsampledCGImage(from: imageData, maxPixel: max(1, Int(maxDimension.rounded(.down))))
        let cgImage: CGImage
        if let downsampledCG {
            cgImage = downsampledCG
        } else if let image = UIImage(data: imageData),
                  let fallbackCG = normalizeOrientation(image, maxDimension: maxDimension).cgImage {
            cgImage = fallbackCG
        } else {
            return nil
        }

        // Write via ImageIO with an explicit clean metadata dictionary (no {GPS} / {TIFF} location tags)
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            "public.jpeg" as CFString,
            1,
            nil
        ) else {
            return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.86)
        }

        let cleanProperties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.86
        ]
        CGImageDestinationAddImage(destination, cgImage, cleanProperties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.86)
        }
        return mutableData as Data
    }

    /// Decodes a compact upright thumbnail directly via ImageIO without decoding the full JPEG into RAM.
    static func makeThumbnailImage(from data: Data, maxPixel: Int) -> UIImage? {
        guard let cg = decodeDownsampledCGImage(from: data, maxPixel: max(16, maxPixel)) else {
            return nil
        }
        return UIImage(cgImage: cg)
    }

    static func makeThumbnailData(from data: Data, maxPixel: Int) -> Data? {
        guard let cg = decodeDownsampledCGImage(from: data, maxPixel: max(16, maxPixel)) else {
            return nil
        }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, "public.jpeg" as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, cg, [kCGImageDestinationLossyCompressionQuality: 0.82] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }

    private static func decodeDownsampledCGImage(from data: Data, maxPixel: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
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
