import Foundation

// MARK: - Process Image Use Case Implementation
public final class ProcessImageUseCaseImpl: ProcessImageUseCase {
    
    // MARK: - Dependencies
    private let ocrService: OCRServiceProtocol
    
    // MARK: - Initialization
    public init(ocrService: OCRServiceProtocol) {
        self.ocrService = ocrService
    }
    
    // MARK: - Use Case Execution
    public func execute(_ request: ProcessImageRequest) async throws -> ProcessImageResponse {
        // 执行OCR识别
        let ocrResult = try await ocrService.recognizeText(from: request.imageData)
        
        // 质量检查
        guard ocrResult.confidence >= request.qualityThreshold else {
            return ProcessImageResponse(
                recognizedText: ocrResult.recognizedText,
                confidence: ocrResult.confidence,
                processingTime: ocrResult.metadata.processingTime,
                suggestionForImprovement: generateImprovementSuggestion(for: ocrResult)
            )
        }
        
        return ProcessImageResponse(
            recognizedText: ocrResult.recognizedText,
            confidence: ocrResult.confidence,
            processingTime: ocrResult.metadata.processingTime,
            suggestionForImprovement: nil
        )
    }
    
    // MARK: - Private Methods
    private func generateImprovementSuggestion(for result: OCRResult) -> String? {
        if result.confidence < 0.3 {
            return "图片质量较低，建议重新拍照，确保光线充足、文字清晰"
        } else if result.confidence < 0.6 {
            return "识别精度一般，建议调整拍摄角度或距离"
        } else {
            return nil
        }
    }
}

// MARK: - Reprocess Image Use Case Implementation
public final class ReprocessImageUseCaseImpl: ReprocessImageUseCase {
    
    // MARK: - Dependencies
    private let ocrService: OCRServiceProtocol
    
    // MARK: - Initialization
    public init(ocrService: OCRServiceProtocol) {
        self.ocrService = ocrService
    }
    
    // MARK: - Use Case Execution
    public func execute(_ request: ReprocessImageRequest) async throws -> ReprocessImageResponse {
        // 执行重新处理
        let ocrResults = try await ocrService.reprocessImage(request.imageData)
        
        // 转换为响应格式
        let responses = ocrResults.map { ocrResult in
            ProcessImageResponse(
                recognizedText: ocrResult.recognizedText,
                confidence: ocrResult.confidence,
                processingTime: ocrResult.metadata.processingTime,
                suggestionForImprovement: generateImprovementSuggestion(for: ocrResult)
            )
        }
        
        // 选择推荐结果（置信度最高的）
        let recommendedResult = responses.max { $0.confidence < $1.confidence }
        
        // 生成改进建议
        let improvements = generateImprovementSuggestions(
            results: responses,
            userFeedback: request.userFeedback
        )
        
        return ReprocessImageResponse(
            results: responses,
            recommendedResult: recommendedResult,
            improvementSuggestions: improvements
        )
    }
    
    // MARK: - Private Methods
    private func generateImprovementSuggestion(for result: OCRResult) -> String? {
        if result.confidence < 0.5 {
            return "建议重新拍摄：确保文字清晰可见，避免模糊或阴影"
        } else if result.confidence < 0.7 {
            return "可以尝试调整：拍摄角度垂直，距离适中"
        } else {
            return nil
        }
    }
    
    private func generateImprovementSuggestions(
        results: [ProcessImageResponse],
        userFeedback: String?
    ) -> [String] {
        var suggestions: [String] = []
        
        // 基于识别结果的建议
        let avgConfidence = results.map(\.confidence).reduce(0, +) / Float(results.count)
        
        if avgConfidence < 0.6 {
            suggestions.append("整体识别精度较低，建议检查图片质量")
        }
        
        // 基于用户反馈的建议
        if let feedback = userFeedback?.lowercased() {
            if feedback.contains("模糊") || feedback.contains("不清楚") {
                suggestions.append("图片模糊，建议使用更好的光线条件重新拍摄")
            }
            
            if feedback.contains("错误") || feedback.contains("不对") {
                suggestions.append("识别错误，可以尝试裁剪图片只保留文字部分")
            }
            
            if feedback.contains("漏掉") || feedback.contains("缺少") {
                suggestions.append("部分文字未识别，建议分段拍摄复杂内容")
            }
        }
        
        // 通用建议
        if suggestions.isEmpty {
            suggestions.append("尝试调整拍摄角度和距离以获得更好的识别效果")
        }
        
        return suggestions
    }
}
