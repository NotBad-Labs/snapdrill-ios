import Foundation

// MARK: - OCR Use Case Protocols

public protocol ProcessImageUseCase {
    associatedtype Request = ProcessImageRequest
    associatedtype Response = ProcessImageResponse
    
    func execute(_ request: Request) async throws -> Response
}

public protocol ReprocessImageUseCase {
    associatedtype Request = ReprocessImageRequest  
    associatedtype Response = ReprocessImageResponse
    
    func execute(_ request: Request) async throws -> Response
}

// MARK: - Request/Response Models

public struct ProcessImageRequest {
    public let imageData: Data
    public let expectedLanguage: String
    public let qualityThreshold: Float
    
    public init(
        imageData: Data,
        expectedLanguage: String = "zh-Hans",
        qualityThreshold: Float = 0.5
    ) {
        self.imageData = imageData
        self.expectedLanguage = expectedLanguage
        self.qualityThreshold = qualityThreshold
    }
}

public struct ProcessImageResponse {
    public let recognizedText: String
    public let confidence: Float
    public let processingTime: TimeInterval
    public let suggestionForImprovement: String?
    
    public init(
        recognizedText: String,
        confidence: Float,
        processingTime: TimeInterval,
        suggestionForImprovement: String? = nil
    ) {
        self.recognizedText = recognizedText
        self.confidence = confidence
        self.processingTime = processingTime
        self.suggestionForImprovement = suggestionForImprovement
    }
}

public struct ReprocessImageRequest {
    public let imageData: Data
    public let previousResult: String?
    public let userFeedback: String?
    
    public init(
        imageData: Data,
        previousResult: String? = nil,
        userFeedback: String? = nil
    ) {
        self.imageData = imageData
        self.previousResult = previousResult
        self.userFeedback = userFeedback
    }
}

public struct ReprocessImageResponse {
    public let results: [ProcessImageResponse]
    public let recommendedResult: ProcessImageResponse?
    public let improvementSuggestions: [String]
    
    public init(
        results: [ProcessImageResponse],
        recommendedResult: ProcessImageResponse? = nil,
        improvementSuggestions: [String] = []
    ) {
        self.results = results
        self.recommendedResult = recommendedResult ?? results.first
        self.improvementSuggestions = improvementSuggestions
    }
}
