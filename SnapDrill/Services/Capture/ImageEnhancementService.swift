import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Implements Original / Enhanced / Black & White document modes using Core Image (PRD F-04).
struct ImageEnhancementService: ImageEnhancing {
    private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    func apply(_ mode: ImageEnhancementMode, to imageData: Data) -> Data {
        if mode == .original {
            return imageData
        }

        guard let uiImage = UIImage(data: imageData),
              let ciInput = CIImage(image: uiImage) else {
            return imageData
        }

        let processed: CIImage
        switch mode {
        case .original:
            return imageData
        case .enhanced:
            processed = applyDocumentEnhance(to: ciInput)
        case .blackAndWhite:
            processed = applyBlackAndWhite(to: ciInput)
        }

        guard let cgOut = Self.ciContext.createCGImage(processed, from: ciInput.extent) else {
            return imageData
        }
        return UIImage(cgImage: cgOut).jpegData(compressionQuality: 0.88) ?? imageData
    }

    private func applyDocumentEnhance(to input: CIImage) -> CIImage {
        let highlightShadow = CIFilter.highlightShadowAdjust()
        highlightShadow.inputImage = input
        highlightShadow.shadowAmount = 0.42
        highlightShadow.highlightAmount = 0.92

        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = highlightShadow.outputImage ?? input
        colorControls.contrast = 1.18
        colorControls.brightness = 0.04
        colorControls.saturation = 1.02

        let sharpen = CIFilter.sharpenLuminance()
        sharpen.inputImage = colorControls.outputImage ?? input
        sharpen.sharpness = 0.45

        return sharpen.outputImage ?? input
    }

    private func applyBlackAndWhite(to input: CIImage) -> CIImage {
        let mono = CIFilter.colorControls()
        mono.inputImage = input
        mono.saturation = 0.0
        mono.contrast = 1.55
        mono.brightness = 0.08

        let sharpen = CIFilter.sharpenLuminance()
        sharpen.inputImage = mono.outputImage ?? input
        sharpen.sharpness = 0.65

        return sharpen.outputImage ?? input
    }
}
