import CoreImage
import UIKit

enum ImageEnhancementMode: String, CaseIterable, Identifiable {
    case enhanced
    case original
    case monochrome

    var id: String { rawValue }

    var title: String {
        switch self {
        case .enhanced: String(localized: "Enhanced")
        case .original: String(localized: "Original")
        case .monochrome: String(localized: "B&W")
        }
    }
}

enum ImageEnhancementService {
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    static func apply(_ mode: ImageEnhancementMode, to image: UIImage) -> UIImage {
        switch mode {
        case .original:
            return image
        case .enhanced:
            return enhanced(image) ?? image
        case .monochrome:
            return monochrome(image) ?? image
        }
    }

    static func enhanced(_ image: UIImage) -> UIImage? {
        guard let ci = CIImage(image: image) else { return nil }
        let filters: [CIFilter?] = [
            CIFilter(name: "CIHighlightShadowAdjust", parameters: [
                "inputHighlightAmount": 0.8,
                "inputShadowAmount": 0.35,
            ]),
            CIFilter(name: "CIColorControls", parameters: [
                kCIInputContrastKey: 1.12,
                kCIInputSaturationKey: 0.95,
            ]),
        ]
        var output = ci
        for filter in filters.compactMap({ $0 }) {
            filter.setValue(output, forKey: kCIInputImageKey)
            output = filter.outputImage ?? output
        }
        return render(output, size: image.size, scale: image.scale)
    }

    static func monochrome(_ image: UIImage) -> UIImage? {
        guard let ci = CIImage(image: image),
              let filter = CIFilter(name: "CIPhotoEffectMono")
        else { return nil }
        filter.setValue(ci, forKey: kCIInputImageKey)
        guard let output = filter.outputImage else { return nil }
        return render(output, size: image.size, scale: image.scale)
    }

    static func stripGPS(from data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let uti = CGImageSourceGetType(source)
        else { return nil }

        let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        var clean = metadata ?? [:]
        clean.removeValue(forKey: kCGImagePropertyGPSDictionary)

        let destData = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(destData, uti, 1, nil),
              let image = UIImage(data: data)?.cgImage
        else { return nil }

        CGImageDestinationAddImage(dest, image, clean as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return destData as Data
    }

    private static func render(_ ci: CIImage, size: CGSize, scale: CGFloat) -> UIImage? {
        guard let cg = context.createCGImage(ci, from: ci.extent) else { return nil }
        return UIImage(cgImage: cg, scale: scale, orientation: .up)
    }
}