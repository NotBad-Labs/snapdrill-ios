//
//  CreateReviewItemUseCaseProtocol.swift
//  NotBad
//
//  Domain Layer - Use Case Protocol
//

import Foundation

// MARK: - CreateReviewItemUseCaseProtocol

/// 创建错题用例协议
///
/// 负责创建新的错题记录：
/// - 验证输入数据
/// - 处理图片数据
/// - 设置默认值
/// - 保存到仓库
///
/// ## 业务规则
///
/// 1. 标题不能为空
/// 2. 必须选择学科和年级
/// 3. 图片大小不超过 10MB
/// 4. 初始掌握程度为"未开始"
///
/// ## 使用示例
///
/// ```swift
/// let useCase = dependencies.makeCreateReviewItemUseCase()
/// let item = try await useCase.execute(
///     title: "二次函数求极值",
///     imageData: imageData,
///     subject: .math,
///     grade: .grade10
/// )
/// ```
@MainActor
protocol CreateReviewItemUseCaseProtocol: Sendable {
    
    /// 创建新错题
    ///
    /// - Parameter input: 创建输入
    /// - Returns: 创建的错题
    /// - Throws: 创建失败时抛出错误
    func execute(input: CreateReviewItemInput) async throws -> ReviewItem
    
    /// 从 OCR 结果创建错题
    ///
    /// - Parameters:
    ///   - ocrResult: OCR 识别结果
    ///   - imageData: 原始图片数据
    /// - Returns: 创建的错题
    /// - Throws: 创建失败时抛出错误
    func execute(
        ocrResult: OCRResult,
        imageData: Data
    ) async throws -> ReviewItem
}

// MARK: - CreateReviewItemInput

/// 创建错题输入
struct CreateReviewItemInput: Sendable {
    
    /// 标题
    let title: String
    
    /// 图片数据
    let imageData: Data?
    
    /// 学科
    let subject: Subject
    
    /// 年级
    let grade: Grade
    
    /// 难度
    let difficulty: Difficulty
    
    /// 错误类型
    let errorType: ErrorType
    
    /// 知识点
    let knowledgePoints: [String]
    
    /// 备注
    let note: String
    
    // MARK: - Initialization
    
    init(
        title: String,
        imageData: Data? = nil,
        subject: Subject,
        grade: Grade,
        difficulty: Difficulty = .medium,
        errorType: ErrorType = .conceptual,
        knowledgePoints: [String] = [],
        note: String = ""
    ) {
        self.title = title
        self.imageData = imageData
        self.subject = subject
        self.grade = grade
        self.difficulty = difficulty
        self.errorType = errorType
        self.knowledgePoints = knowledgePoints
        self.note = note
    }
    
    // MARK: - Validation
    
    /// 验证输入是否有效
    func validate() throws {
        // 标题不能为空
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CreateReviewItemError.emptyTitle
        }
        
        // 图片大小限制（10MB）
        if let data = imageData, data.count > 10 * 1024 * 1024 {
            throw CreateReviewItemError.imageTooLarge(size: data.count)
        }
    }
}

// MARK: - CreateReviewItemError

/// 创建错题错误
enum CreateReviewItemError: Error, LocalizedError, Sendable {
    case emptyTitle
    case imageTooLarge(size: Int)
    case saveFailed(underlying: Error)
    case invalidInput(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return String(localized: "标题不能为空")
        case .imageTooLarge(let size):
            let mb = Double(size) / 1024 / 1024
            return String(localized: "图片太大（\(String(format: "%.1f", mb))MB），请压缩后重试")
        case .saveFailed:
            return String(localized: "保存失败，请重试")
        case .invalidInput(let reason):
            return String(localized: "输入无效：\(reason)")
        }
    }
}

// MARK: - OCRResult

/// OCR 识别结果
///
/// 由 OCR 服务返回，用于自动填充错题信息。
struct OCRResult: Sendable {
    
    /// 识别的文本
    let text: String
    
    /// 推断的学科
    let inferredSubject: Subject?
    
    /// 推断的知识点
    let inferredKnowledgePoints: [String]
    
    /// 置信度（0-1）
    let confidence: Double
    
    /// 识别区域
    let regions: [OCRRegion]
    
    init(
        text: String,
        inferredSubject: Subject? = nil,
        inferredKnowledgePoints: [String] = [],
        confidence: Double = 0,
        regions: [OCRRegion] = []
    ) {
        self.text = text
        self.inferredSubject = inferredSubject
        self.inferredKnowledgePoints = inferredKnowledgePoints
        self.confidence = confidence
        self.regions = regions
    }
}

// MARK: - OCRRegion

/// OCR 识别区域
struct OCRRegion: Sendable {
    let text: String
    let boundingBox: CGRect
    let confidence: Double
}
