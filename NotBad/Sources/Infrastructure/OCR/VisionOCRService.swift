import Foundation
@preconcurrency import Vision
import UIKit
import CoreImage

// MARK: - Vision OCR Service Implementation
public final class VisionOCRService: OCRServiceProtocol {
    
    // MARK: - Constants
    private enum Constants {
        static let minimumConfidence: Float = 0.5
        static let highConfidenceThreshold: Float = 0.8
        static let processingTimeout: TimeInterval = 10.0
        static let supportedLanguages = ["zh-Hans", "zh-Hant", "en-US"]
    }
    
    // MARK: - Private Properties
    private let processingQueue = DispatchQueue(label: "com.notbad.ocr.processing", qos: .userInitiated)
    
    // MARK: - Public Methods
    
    public init() {}
    
    public func recognizeText(from imageData: Data) async throws -> OCRResult {
        let startTime = Date()
        
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            throw OCRError.invalidImageData
        }
        
        let result = try await performVisionRecognition(on: cgImage)
        let processingTime = Date().timeIntervalSince(startTime)
        
        let metadata = OCRMetadata(
            processedAt: Date(),
            processingTime: processingTime,
            imageSize: image.size,
            language: "zh-Hans"
        )
        
        let ocrResult = OCRResult(
            recognizedText: result.text,
            confidence: result.confidence,
            boundingBoxes: result.textBlocks,
            metadata: metadata
        )
        
        // 验证结果质量
        guard validateResult(ocrResult) else {
            throw OCRError.lowConfidence
        }
        
        return ocrResult
    }
    
    public func reprocessImage(_ imageData: Data) async throws -> [OCRResult] {
        var results: [OCRResult] = []
        
        // 主要识别
        let primaryResult = try await recognizeText(from: imageData)
        results.append(primaryResult)
        
        // 如果主要识别置信度不高，尝试图像预处理后再次识别
        if primaryResult.confidence < Constants.highConfidenceThreshold {
            if let preprocessedResults = try? await performPreprocessingAndRecognition(imageData) {
                results.append(contentsOf: preprocessedResults)
            }
        }
        
        return results
    }
    
    public func validateResult(_ result: OCRResult) -> Bool {
        // 基本置信度检查
        guard result.confidence >= Constants.minimumConfidence else {
            return false
        }
        
        // 文本长度检查
        guard !result.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        return true
    }
    
    public func getSupportedLanguages() -> [String] {
        return Constants.supportedLanguages
    }
}

// MARK: - Private Methods
private extension VisionOCRService {
    
    func performVisionRecognition(on cgImage: CGImage) async throws -> (text: String, confidence: Float, textBlocks: [OCRTextBlock]) {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.recognitionFailed)
                    return
                }
                
                let result = self.processVisionObservations(observations)
                continuation.resume(returning: result)
            }
            
            // 配置识别参数
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["zh-Hans", "en-US"]
            request.usesLanguageCorrection = true
            
            // 执行识别 - 使用Task确保并发安全
            Task {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: OCRError.visionFrameworkUnavailable)
                }
            }
        }
    }
    
    func processVisionObservations(_ observations: [VNRecognizedTextObservation]) -> (text: String, confidence: Float, textBlocks: [OCRTextBlock]) {
        var allText: [String] = []
        var totalConfidence: Float = 0
        var textBlocks: [OCRTextBlock] = []
        
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            
            let text = topCandidate.string
            let confidence = topCandidate.confidence
            let boundingBox = observation.boundingBox
            
            allText.append(text)
            totalConfidence += confidence
            
            let textBlock = OCRTextBlock(
                text: text,
                confidence: confidence,
                boundingBox: boundingBox,
                range: NSRange(location: 0, length: text.count)
            )
            textBlocks.append(textBlock)
        }
        
        let finalText = allText.joined(separator: "\n")
        let averageConfidence = observations.isEmpty ? 0 : totalConfidence / Float(observations.count)
        
        return (finalText, averageConfidence, textBlocks)
    }
    
    func performPreprocessingAndRecognition(_ imageData: Data) async throws -> [OCRResult] {
        var results: [OCRResult] = []
        
        guard let originalImage = UIImage(data: imageData) else {
            throw OCRError.invalidImageData
        }
        
        // 尝试不同的图像预处理策略
        let preprocessingStrategies: [(String, (UIImage) -> UIImage?)] = [
            ("contrast_enhanced", enhanceContrast),
            ("grayscale", convertToGrayscale),
            ("sharpened", sharpenImage)
        ]
        
        for (strategy, preprocessor) in preprocessingStrategies {
            if let processedImage = preprocessor(originalImage),
               let processedImageData = processedImage.jpegData(compressionQuality: 0.9) {
                
                if let result = try? await recognizeText(from: processedImageData) {
                    // 标记这是预处理后的结果
                    var modifiedMetadata = result.metadata
                    modifiedMetadata = OCRMetadata(
                        processedAt: modifiedMetadata.processedAt,
                        processingTime: modifiedMetadata.processingTime,
                        imageSize: modifiedMetadata.imageSize,
                        language: "\(modifiedMetadata.language)_\(strategy)"
                    )
                    
                    let enhancedResult = OCRResult(
                        recognizedText: result.recognizedText,
                        confidence: result.confidence,
                        boundingBoxes: result.boundingBoxes,
                        metadata: modifiedMetadata
                    )
                    
                    results.append(enhancedResult)
                }
            }
        }
        
        return results
    }
    
    // MARK: - Image Preprocessing
    
    func enhanceContrast(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(1.5, forKey: kCIInputContrastKey) // 增强对比度
        filter?.setValue(1.1, forKey: kCIInputBrightnessKey) // 轻微增加亮度
        
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    func convertToGrayscale(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let filter = CIFilter(name: "CIPhotoEffectNoir")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    func sharpenImage(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let filter = CIFilter(name: "CISharpenLuminance")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(0.8, forKey: kCIInputSharpnessKey)
        
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}
