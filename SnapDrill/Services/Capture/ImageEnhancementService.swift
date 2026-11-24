import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Implements Original / Enhanced / Black & White document modes using local shadow-normalized Core Image pipelines (PRD F-04).
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

        let inputExtent = ciInput.extent
        guard !inputExtent.isEmpty, !inputExtent.isNull, !inputExtent.isInfinite else {
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

        let renderRect = processed.extent.intersection(inputExtent)
        guard !renderRect.isEmpty, !renderRect.isNull, !renderRect.isInfinite,
              let cgOut = Self.ciContext.createCGImage(processed, from: renderRect) else {
            return imageData
        }
        return UIImage(cgImage: cgOut).jpegData(compressionQuality: 0.90) ?? imageData
    }

    private func applyDocumentEnhance(to input: CIImage) -> CIImage {
        let extent = input.extent
        // Estimate slow local illumination field and divide out uneven shadows/vignetting while keeping ink dark
        let blurRadius = Float(max(24.0, min(extent.width, extent.height) * 0.065))
        let clampedInput = input.clampedToExtent()
        let bgBlur = CIFilter.gaussianBlur()
        bgBlur.inputImage = clampedInput
        bgBlur.radius = blurRadius
        let illumination = (bgBlur.outputImage ?? clampedInput).cropped(to: extent)

        let divide = CIFilter.divideBlendMode()
        divide.inputImage = input
        divide.backgroundImage = illumination
        let shadowNormalized = (divide.outputImage ?? input).cropped(to: extent)

        let highlightShadow = CIFilter.highlightShadowAdjust()
        highlightShadow.inputImage = input
        highlightShadow.shadowAmount = 0.45
        highlightShadow.highlightAmount = 0.90
        let balancedOriginal = (highlightShadow.outputImage ?? input).cropped(to: extent)

        // Blend shadow-normalized image over balanced original so lighting normalizes without washing out color pens
        let blend = CIFilter.dissolveTransition()
        blend.inputImage = balancedOriginal
        blend.targetImage = shadowNormalized
        blend.time = 0.58

        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = (blend.outputImage ?? shadowNormalized).cropped(to: extent)
        colorControls.contrast = 1.12
        colorControls.brightness = 0.02
        colorControls.saturation = 1.04

        let sharpen = CIFilter.sharpenLuminance()
        sharpen.inputImage = (colorControls.outputImage ?? input).cropped(to: extent)
        sharpen.sharpness = 0.40

        return (sharpen.outputImage ?? input).cropped(to: extent)
    }

    private func applyBlackAndWhite(to input: CIImage) -> CIImage {
        let extent = input.extent
        let normalized = applyDocumentEnhance(to: input)

        let mono = CIFilter.colorControls()
        mono.inputImage = normalized
        mono.saturation = 0.0
        mono.contrast = 1.48
        mono.brightness = 0.05

        let sharpen = CIFilter.sharpenLuminance()
        sharpen.inputImage = (mono.outputImage ?? normalized).cropped(to: extent)
        sharpen.sharpness = 0.55

        return (sharpen.outputImage ?? normalized).cropped(to: extent)
    }
}
