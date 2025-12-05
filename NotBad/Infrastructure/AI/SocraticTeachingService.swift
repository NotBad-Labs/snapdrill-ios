//
//  SocraticTeachingService.swift
//  NotBad
//
//  苏格拉底式教学服务 - 引导式提问而非直接给答案
//

import Foundation
import FoundationModels

// MARK: - Socratic Hint Level

/// 提示层级
///
/// 苏格拉底式教学采用渐进式提示，从最少提示逐步增加
enum SocraticHintLevel: Int, CaseIterable, Sendable {
    /// 第一层：方向性提示（只给思考方向）
    case direction = 1
    
    /// 第二层：概念提示（指出相关知识点）
    case concept = 2
    
    /// 第三层：步骤提示（分解解题步骤）
    case steps = 3
    
    /// 第四层：详细提示（给出关键思路）
    case detailed = 4
    
    /// 最终层：完整解答（实在不会时）
    case solution = 5
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .direction:
            return "方向引导"
        case .concept:
            return "知识提示"
        case .steps:
            return "步骤分解"
        case .detailed:
            return "详细思路"
        case .solution:
            return "完整解答"
        }
    }
    
    /// 图标
    var icon: String {
        switch self {
        case .direction:
            return "arrow.right.circle"
        case .concept:
            return "lightbulb"
        case .steps:
            return "list.number"
        case .detailed:
            return "doc.text.magnifyingglass"
        case .solution:
            return "checkmark.circle"
        }
    }
    
    /// 下一个层级
    var next: SocraticHintLevel? {
        SocraticHintLevel(rawValue: rawValue + 1)
    }
}

// MARK: - Socratic Response

/// 苏格拉底式教学响应
struct SocraticResponse: Sendable {
    /// 提示层级
    let level: SocraticHintLevel
    
    /// 引导性问题（帮助学生思考）
    let guidingQuestions: [String]
    
    /// 提示内容
    let hint: String
    
    /// 鼓励语（激励学生继续思考）
    let encouragement: String
    
    /// 是否还有更多提示
    var hasMoreHints: Bool {
        level != .solution
    }
    
    /// 建议：如果还是不会怎么办
    var nextStepSuggestion: String {
        if let next = level.next {
            return "如果还是不太确定，可以点击「\(next.displayName)」获取更多帮助"
        }
        return "现在你应该能理解这道题了，试着自己再做一遍吧！"
    }
}

// MARK: - Socratic Response Schema

/// 苏格拉底式响应的结构化输出
@Generable
struct SocraticResponseSchema {
    /// 引导性问题（1-3个）
    @Guide(description: "根据题目和当前提示层级，生成1-3个引导学生思考的问题。问题应该由浅入深，帮助学生发现解题关键")
    var guidingQuestions: [String]
    
    /// 提示内容
    @Guide(description: "根据提示层级给出相应的提示。层级1只给方向，层级2指出知识点，层级3分解步骤，层级4给详细思路，层级5给完整解答")
    var hint: String
    
    /// 鼓励语
    @Guide(description: "给学生一句鼓励的话，激励他们继续思考，保持积极的学习态度")
    var encouragement: String
}

// MARK: - SocraticTeachingService

/// 苏格拉底式教学服务
///
/// 通过引导式提问帮助学生自主思考，而非直接给出答案。
/// 符合教育心理学原理，促进深度学习。
///
/// ## 教学理念
///
/// 1. **提问引导**：通过问题引发学生思考
/// 2. **渐进提示**：从最少提示逐步增加
/// 3. **正向激励**：每次回复都包含鼓励
/// 4. **自主建构**：帮助学生自己发现答案
///
/// ## 使用示例
///
/// ```swift
/// let service = SocraticTeachingService.shared
///
/// // 获取第一层提示
/// let response = try await service.getHint(
///     for: reviewItem,
///     level: .direction
/// )
///
/// // 显示引导问题
/// for question in response.guidingQuestions {
///     print("🤔 \(question)")
/// }
/// ```
@MainActor
final class SocraticTeachingService {
    
    // MARK: - Singleton
    
    static let shared = SocraticTeachingService()
    
    // MARK: - Properties
    
    private let model = SystemLanguageModel.default
    
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
    
    // MARK: - Teaching API
    
    /// 获取苏格拉底式提示
    ///
    /// - Parameters:
    ///   - item: 当前复习的错题
    ///   - level: 提示层级（默认从最低开始）
    ///   - studentQuestion: 学生的具体问题（可选）
    /// - Returns: 苏格拉底式响应
    /// - Throws: 服务不可用或分析失败
    func getHint(
        for item: ReviewItem,
        level: SocraticHintLevel = .direction,
        studentQuestion: String? = nil
    ) async throws -> SocraticResponse {
        guard isAvailable else {
            throw SocraticTeachingError.serviceUnavailable
        }
        
        // 构建教学指令
        let instructions = Instructions {
            "你是一位耐心的教育专家，专门帮助K12学生学习。"
            "你采用苏格拉底式教学法：通过提问引导学生思考，而不是直接给答案。"
            "你的目标是帮助学生建立自主学习能力，培养批判性思维。"
            "请始终用中文回复，语言要简洁易懂，适合学生阅读。"
            "保持积极鼓励的态度，让学生感受到学习的乐趣。"
        }
        
        let session = LanguageModelSession(instructions: instructions)
        
        // 构建题目上下文
        let questionContext = buildQuestionContext(item: item, studentQuestion: studentQuestion)
        
        // 构建层级指令
        let levelInstructions = buildLevelInstructions(level: level)
        
        let prompt = """
        ## 题目信息
        
        \(questionContext)
        
        ## 提示要求
        
        当前提示层级：\(level.displayName)（第\(level.rawValue)层，共5层）
        
        \(levelInstructions)
        
        请根据以上要求，生成引导式的教学响应。
        """
        
        let response = try await session.respond(
            to: prompt,
            generating: SocraticResponseSchema.self
        )
        
        let content = response.content
        
        return SocraticResponse(
            level: level,
            guidingQuestions: content.guidingQuestions,
            hint: content.hint,
            encouragement: content.encouragement
        )
    }
    
    /// 快速生成思考引导（不使用完整结构化输出）
    ///
    /// 适用于快速获取一个引导问题的场景
    func quickGuide(for item: ReviewItem) async throws -> String {
        guard isAvailable else {
            throw SocraticTeachingError.serviceUnavailable
        }
        
        let instructions = Instructions {
            "你是一位教育专家，请用一个简短的引导问题帮助学生思考这道题。"
            "问题应该指向解题的关键点，但不要直接给出答案。"
            "用中文回复，语言简洁。"
        }
        
        let session = LanguageModelSession(instructions: instructions)
        
        let context = buildQuestionContext(item: item, studentQuestion: nil)
        let prompt = "请针对以下题目，给出一个引导学生思考的问题：\n\n\(context)"
        
        let response = try await session.respond(to: prompt)
        return response.content
    }
    
    // MARK: - Private Helpers
    
    /// 构建题目上下文
    private func buildQuestionContext(item: ReviewItem, studentQuestion: String?) -> String {
        var context = """
        学科：\(item.subject.displayName)
        题型：\(item.reviewItemType.displayName)
        题目标题：\(item.title.isEmpty ? "未命名" : item.title)
        """
        
        // 添加知识点
        if !item.knowledgePoints.isEmpty {
            context += "\n涉及知识点：\(item.knowledgePoints.items.joined(separator: "、"))"
        }
        
        // 添加笔记（可能包含题目内容）
        if !item.note.isEmpty {
            context += "\n题目笔记：\(String(item.note.prefix(500)))"
        }
        
        // 添加学生的具体问题
        if let question = studentQuestion, !question.isEmpty {
            context += "\n学生问题：\(question)"
        }
        
        return context
    }
    
    /// 根据层级构建指令
    private func buildLevelInstructions(level: SocraticHintLevel) -> String {
        switch level {
        case .direction:
            return """
            【第1层 - 方向引导】
            - 只给思考方向，不涉及具体方法
            - 引导问题应该帮助学生明确题目在问什么
            - 提示内容只需点出思考的起点
            - 例如："这道题考察的是什么概念？"
            """
            
        case .concept:
            return """
            【第2层 - 知识提示】
            - 指出这道题需要用到的核心知识点
            - 引导问题帮助学生回忆相关概念
            - 提示内容可以列出1-2个关键公式或定理名称
            - 例如："回忆一下勾股定理是怎么表述的？"
            """
            
        case .steps:
            return """
            【第3层 - 步骤分解】
            - 将解题过程分解为几个主要步骤
            - 引导问题针对每个步骤的关键点
            - 提示内容给出步骤框架，但不填细节
            - 例如："第一步是找出已知条件，你能列出来吗？"
            """
            
        case .detailed:
            return """
            【第4层 - 详细思路】
            - 给出较为详细的解题思路
            - 引导问题帮助学生验证自己的理解
            - 提示内容可以包含关键的中间步骤
            - 但仍然留一些让学生自己完成的部分
            """
            
        case .solution:
            return """
            【第5层 - 完整解答】
            - 给出完整的解题过程和答案
            - 引导问题帮助学生复盘和总结
            - 提示内容要清晰完整，方便学生理解
            - 最后建议学生自己再做一遍加深印象
            """
        }
    }
}

// MARK: - SocraticTeachingError

/// 苏格拉底教学错误
enum SocraticTeachingError: LocalizedError {
    case serviceUnavailable
    case analysisTimeout
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return String(localized: "socratic_error_unavailable")
        case .analysisTimeout:
            return String(localized: "socratic_error_timeout")
        case .invalidResponse:
            return String(localized: "socratic_error_invalid")
        }
    }
}

// MARK: - Convenience Extensions

extension SocraticTeachingService {
    
    /// 获取下一层提示
    func getNextHint(
        for item: ReviewItem,
        currentLevel: SocraticHintLevel
    ) async throws -> SocraticResponse? {
        guard let nextLevel = currentLevel.next else {
            return nil
        }
        return try await getHint(for: item, level: nextLevel)
    }
    
    /// 检查是否还有更多提示可用
    func hasMoreHints(currentLevel: SocraticHintLevel) -> Bool {
        currentLevel.next != nil
    }
}
