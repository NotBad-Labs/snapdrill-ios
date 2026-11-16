import UIKit

enum CaptureImageUtilities {
    static func crop(_ image: UIImage, normalized rect: CGRect) -> UIImage? {
        let w = image.size.width
        let h = image.size.height
        let crop = CGRect(x: rect.origin.x * w, y: rect.origin.y * h, width: rect.width * w, height: rect.height * h)
        guard let cg = image.cgImage?.cropping(to: crop.integral) else { return nil }
        return UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
    }
}

struct DefaultPhotoDataSanitizer: PhotoDataSanitizing {
    func stripGPSMetadata(from imageData: Data) -> Data {
        ImageEnhancementService.stripGPS(from: imageData) ?? imageData
    }
}