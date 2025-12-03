//
//  SmartAnalysisService.swift
//  NotBad
//
//  使用 Apple Intelligence 进行智能分析
//

import Foundation
import FoundationModels

// MARK: - SmartAnalysisResult

/// 智能分析结果
struct SmartAnalysisResult: Sendable {
    /// 建议的标题
    let suggestedTitle: String
    
    /// 建议的科目
    let suggestedSubject: Subject
    
    /// 分析置信度 (0-1)
    let confidence: Double
    
    /// 是否需要用户确认
    var needsConfirmation: Bool {
        confidence < 0.8
    }
}

// MARK: - SubjectAnalysisSchema

/// 科目分析结果的结构化输出
@Generable
struct SubjectAnalysisSchema {
    /// 建议的科目代码
    @Guide(description: "根据题目内容分析最可能的科目。必须是以下之一：chinese（语文）、english（英语）、math（数学）、physics（物理）、chemistry（化学）、biology（生物）、science（科学）、history（历史）、geography（地理）、politics（政治）、ethics（道德与法治）、information_tech（信息技术）、general_tech（通用技术）、other（其他）")
    var subjectCode: String
    
    /// 建议的标题（简洁概括题目要点，不超过30字）
    @Guide(description: "根据题目内容生成一个简洁的标题，概括题目的核心知识点或主题，不超过30个字符")
    var suggestedTitle: String
    
    /// 置信度 (0-100)
    @Guide(description: "对科目判断的置信度，0-100之间的整数")
    var confidencePercent: Int
}

// MARK: - SmartAnalysisService

/// 智能分析服务
///
/// 使用 Apple Intelligence Foundation Models 进行端侧智能分析：
/// - 自动识别题目所属科目
/// - 生成简洁的题目标题
///
/// ## 功能特性
///
/// - 完全端侧处理，保护隐私
/// - 支持中文题目分析
/// - 结构化输出，便于直接使用
///
/// ## 使用示例
///
/// ```swift
/// let service = SmartAnalysisService.shared
///
/// if await service.isAvailable {
///     let result = try await service.analyze(text: "求证：勾股定理...")
///     print("建议科目: \(result.suggestedSubject.displayName)")
///     print("建议标题: \(result.suggestedTitle)")
/// }
/// ```
@MainActor
final class SmartAnalysisService {
    
    // MARK: - Singleton
    
    /// 共享实例
    static let shared = SmartAnalysisService()
    
    // MARK: - Properties
    
    /// 系统语言模型
    private let model = SystemLanguageModel.default
    
    /// 语言模型会话
    private var session: LanguageModelSession?
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Availability
    
    /// 检查服务是否可用
    var isAvailable: Bool {
        model.isAvailable
    }
    
    /// 可用性状态
    var availability: SystemLanguageModel.Availability {
        model.availability
    }
    
    /// 不可用的原因
    var unavailableReason: String? {
        switch model.availability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return String(localized: "smart_analysis_unavailable_device")
        case .unavailable(.appleIntelligenceNotEnabled):
            return String(localized: "smart_analysis_unavailable_not_enabled")
        case .unavailable(.modelNotReady):
            return String(localized: "smart_analysis_unavailable_not_ready")
        case .unavailable:
            return String(localized: "smart_analysis_error_unavailable")
        }
    }
    
    // MARK: - Analysis
    
    /// 分析题目内容
    ///
    /// - Parameter text: 题目文本内容
    /// - Returns: 分析结果，包含建议的科目和标题
    /// - Throws: 分析失败时抛出错误
    func analyze(text: String) async throws -> SmartAnalysisResult {
        guard isAvailable else {
            throw SmartAnalysisError.serviceUnavailable
        }
        
        // 创建新的会话
        let instructions = Instructions {
            "你是一个教育领域的专家助手，专门帮助分析学生的作业和试题。"
            "你需要根据题目内容判断它属于哪个学科，并生成简洁的标题。"
            "请始终用中文回复。"
        }
        
        let session = LanguageModelSession(instructions: instructions)
        
        // 截取前500字符进行分析，避免过长
        let analysisText = String(text.prefix(500))
        
        let prompt = """
        请分析以下学生作业题目，判断它属于哪个学科，并生成一个简洁的标题。
        
        题目内容：
        \(analysisText)
        
        请根据题目的专业术语、公式、问题类型等特征进行判断。
        """
        
        let response = try await session.respond(
            to: prompt,
            generating: SubjectAnalysisSchema.self
        )
        
        // 从响应中获取内容
        let content = response.content
        
        // 解析科目
        let subject = Subject(rawValue: content.subjectCode) ?? .other
        
        // 清理标题
        let cleanTitle = content.suggestedTitle
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(50)
        
        return SmartAnalysisResult(
            suggestedTitle: String(cleanTitle),
            suggestedSubject: subject,
            confidence: Double(content.confidencePercent) / 100.0
        )
    }
    
    /// 仅分析科目
    ///
    /// - Parameter text: 题目文本内容
    /// - Returns: 建议的科目
    func analyzeSubject(text: String) async throws -> Subject {
        let result = try await analyze(text: text)
        return result.suggestedSubject
    }
    
    /// 仅生成标题
    ///
    /// - Parameter text: 题目文本内容
    /// - Returns: 建议的标题
    func generateTitle(text: String) async throws -> String {
        let result = try await analyze(text: text)
        return result.suggestedTitle
    }
}

// MARK: - SmartAnalysisError

/// 智能分析错误
enum SmartAnalysisError: LocalizedError {
    case serviceUnavailable
    case sessionCreationFailed
    case analysisTimeout
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return String(localized: "smart_analysis_error_unavailable")
        case .sessionCreationFailed:
            return String(localized: "smart_analysis_error_session")
        case .analysisTimeout:
            return String(localized: "smart_analysis_error_timeout")
        case .invalidResponse:
            return String(localized: "smart_analysis_error_invalid")
        }
    }
}
