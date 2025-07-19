//
//  Tag.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainErrors // 包含 QuestionDomainError

/// 题目领域错误
// Note: In a real project, this would be in its own file: Core/Domain/Errors/QuestionDomainError.swift
enum QuestionDomainError: Error, CustomStringConvertible, LocalizedError {
    case emptyContent
    case contentTooLong
    case noAnswers
    case noCorrectAnswers
    case noAnswerOptions
    case emptyAnswer
    case emptyTag // 标签内容为空
    case tooLongTag(Int) // 标签太长
    case invalidTagCharacters // 标签包含无效字符
    case duplicateTag // 标签已存在（在集合中添加时可能遇到）
    case conflictingTags(Tag, Tag) // 标签冲突

    case cannotReduceDifficultyForMasteredQuestion
    case cannotReviewUnatttemptedQuestion
    case tooManyAttemptsForMasteredQuestion
    case inconsistentSubjectAndTags(subject: Subject, tag: Tag)
    case invalidStateForOperation(String)

    // MARK: - Subject 相关的验证错误 (已从 ValidationError 整合)
    case emptySubjectName
    case subjectNameTooLong(String)
    case duplicateCoreSubject(String)
    case unknownCoreSubject(String)

    var description: String {
        switch self {
        case .emptyContent:
            return "题目内容不能为空。"
        case .contentTooLong:
            return "题目内容过长，请精简。"
        case .noAnswers:
            return "题目必须有答案。"
        case .noCorrectAnswers:
            return "题目必须有正确答案。"
        case .noAnswerOptions:
            return "多选题必须提供选项。"
        case .emptyAnswer:
            return "答案内容不能为空。"
        case .emptyTag:
            return "标签内容不能为空。"
        case .tooLongTag(let count):
            return "标签太长（\(count)个字符），最多20个字符。"
        case .invalidTagCharacters:
            return "标签包含无效字符。"
        case .duplicateTag:
            return "标签已存在。"
        case .conflictingTags(let tag1, let tag2):
            return "标签冲突: '\(tag1.value)' 与 '\(tag2.value)'。"
        case .cannotReduceDifficultyForMasteredQuestion:
            return "已掌握的题目不能随意降低难度。"
        case .cannotReviewUnatttemptedQuestion:
            return "未曾尝试过的题目不能标记为已复习。"
        case .tooManyAttemptsForMasteredQuestion:
            return "已掌握的题目今天尝试次数过多，请明天再练。"
        case .inconsistentSubjectAndTags(let subject, let tag):
            return "学科 '\(subject.displayName)' 与标签 '\(tag.value)' 不一致。"
        case .invalidStateForOperation(let operation):
            return "当前题目状态不允许执行操作: '\(operation)'。"
        case .emptySubjectName:
            return "学科名称不能为空。"
        case .subjectNameTooLong(let name):
            return "学科名称太长: '\(name)'（最多10个字符）。"
        case .duplicateCoreSubject(let name):
            return "不能创建与核心学科重复的自定义学科: '\(name)'。"
        case .unknownCoreSubject(let name):
            return "未知的核心学科名称: '\(name)'。"
        }
    }

    var errorDescription: String? {
        return description
    }
}

/// 学科枚举 (仅为编译目的包含，实际应从 Subject.swift 导入)
// Note: In a real project, this would be in its own file: Core/Domain/Entities/Content/Subject.swift
enum Subject: String, CaseIterable, Codable, Sendable, Hashable {
    case mathematics = "数学"
    case physics = "物理"
    case chemistry = "化学"
    case biology = "生物"
    case english = "英语"
    case chinese = "语文"
    case history = "历史"
    case geography = "地理"
    case politics = "政治"
    case computerScience = "计算机科学"
    case general = "综合"

    var displayName: String { rawValue }

    static func findCoreSubject(byName name: String) -> Subject? {
        return Subject.allCases.first(where: { $0.rawValue == name })
    }
}


/// 标签颜色（纯领域概念，不绑定UI框架）
/// 这是一个值对象，用于在领域层表达与标签相关的颜色语义。
/// UI层会根据此处的 hexValue 进行具体的颜色渲染。
enum TagColor: String, CaseIterable, Codable, Sendable, Hashable {
    case blue = "蓝色"
    case red = "红色"
    case green = "绿色"
    case orange = "橙色"
    case purple = "紫色"
    case gray = "灰色"
    case pink = "粉色"
    case yellow = "黄色"

    /// 颜色的十六进制值（供UI层使用）
    var hexValue: String {
        switch self {
        case .blue: return "#007AFF"
        case .red: return "#FF3B30"
        case .green: return "#34C759"
        case .orange: return "#FF9500"
        case .purple: return "#AF52DE"
        case .gray: return "#8E8E93"
        case .pink: return "#FF2D92"
        case .yellow: return "#FFCC00"
        }
    }

    /// 颜色的语义含义
    var meaning: String {
        switch self {
        case .blue: return "常规"
        case .red: return "重要"
        case .green: return "简单"
        case .orange: return "提醒"
        case .purple: return "特殊"
        case .gray: return "次要"
        case .pink: return "兴趣"
        case .yellow: return "注意"
        }
    }
}

/// 标签的业务类型分类
/// 这是一个值对象，用于对标签进行更高级别的语义分类。
enum TagType: String, CaseIterable, Codable, Sendable, Hashable {
    case activity = "活动"      // 学习活动相关，如：复习、练习、作业
    case priority = "优先级"    // 重要性相关，如：考试、重点、重要
    case difficulty = "难度"    // 难度相关，如：简单、困难、基础
    case method = "方法"        // 学习方法相关，如：快速、详细
    case subject = "学科"       // 用于与 Subject 实体关联，如：数学、物理 (新增，以支持 QuestionMetadata 验证)
    case custom = "自定义"      // 用户自定义标签，无特定预定义分类

    var displayName: String { rawValue }
}


/// 标签值对象
/// 用于对题目、学习内容等进行分类和标记。
/// 这是一个不可变的值对象，封装了标签的文本内容、唯一标识、颜色概念以及其自身的业务规则。
struct Tag: Hashable, Codable, Sendable {
    /// 标签的文本内容
    let value: String

    /// 标签的唯一标识（基于小写的value生成，用于去重和比较）
    let id: String // 遵循 Identifiable 协议的 id

    /// 标签颜色（领域概念）
    let color: TagColor

    /// 标签的业务类型
    let type: TagType // 新增 type 属性

    /// 创建标签
    /// - Parameters:
    ///   - value: 标签文本
    ///   - color: 标签颜色，默认为蓝色
    ///   - type: 标签的业务类型，默认为 .custom
    /// - Throws: QuestionDomainError 如果标签无效
    init(_ value: String, color: TagColor = .blue, type: TagType = .custom) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        // 验证：不能为空
        guard !trimmed.isEmpty else {
            throw QuestionDomainError.emptyTag
        }

        // 验证：长度限制
        guard trimmed.count <= 20 else {
            throw QuestionDomainError.tooLongTag(trimmed.count)
        }

        // 验证：不能包含特殊字符（简单检查，可根据需求细化）
        // 允许字母、数字、空格，以及中文逗号、顿号、句号
        guard trimmed.allSatisfy({ $0.isLetter || $0.isNumber || $0.isWhitespace || "、，。".contains($0) }) else {
            throw QuestionDomainError.invalidTagCharacters
        }

        self.value = trimmed
        self.id = trimmed.lowercased() // id 基于小写值，确保唯一性
        self.color = color
        self.type = type // 设置类型
    }
}

// MARK: - Identifiable 协议
extension Tag: Identifiable {
    // id 属性已在结构体中定义
}

// MARK: - 预定义标签
extension Tag {
    /// 常用预定义标签
    // 使用 try! 是因为这些是硬编码的，预期不会失败。
    // 在实际应用中，如果这些标签来自外部配置，则需要更安全的加载机制。
    static let review = try! Tag("复习", color: .orange, type: .activity)
    static let homework = try! Tag("作业", color: .red, type: .activity)
    static let exam = try! Tag("考试", color: .purple, type: .priority)
    static let practice = try! Tag("练习", color: .blue, type: .activity)
    static let important = try! Tag("重点", color: .red, type: .priority)
    static let easy = try! Tag("简单", color: .green, type: .difficulty)
    static let difficult = try! Tag("困难", color: .red, type: .difficulty)
    static let quick = try! Tag("快速", color: .blue, type: .method)
    static let detailed = try! Tag("详细", color: .purple, type: .method)
    static let foundation = try! Tag("基础", color: .green, type: .difficulty)
    // 新增学科相关的预定义标签，以支持 QuestionMetadata 的验证
    static let mathematics = try! Tag("数学", type: .subject)
    static let physics = try! Tag("物理", type: .subject)
    static let chemistry = try! Tag("化学", type: .subject)
    static let biology = try! Tag("生物", type: .subject)
    static let english = try! Tag("英语", type: .subject)
    static let chinese = try! Tag("语文", type: .subject)
    static let history = try! Tag("历史", type: .subject)
    static let geography = try! Tag("地理", type: .subject)
    static let politics = try! Tag("政治", type: .subject)
    static let computerScience = try! Tag("计算机科学", type: .subject)
    static let generalSubject = try! Tag("综合", type: .subject)


    /// 所有预定义标签
    static let predefined: [Tag] = [
        review, homework, exam, practice, important,
        easy, difficult, quick, detailed, foundation,
        mathematics, physics, chemistry, biology, english,
        chinese, history, geography, politics, computerScience, generalSubject
    ]

    /// 根据名称查找预定义标签
    /// - Parameter name: 标签名称
    /// - Returns: 找到的标签，如果不存在则返回 nil
    static func predefined(named name: String) -> Tag? {
        return predefined.first { $0.value == name }
    }
}

// MARK: - 业务方法
extension Tag {
    /// 判断是否为预定义标签
    /// - Returns: true 如果是预定义标签
    func isPredefined() -> Bool {
        return Self.predefined.contains { $0.id == self.id }
    }

    /// 检查与另一个标签是否冲突
    /// 此方法封装了标签冲突的业务规则。
    /// - Parameter other: 另一个标签
    /// - Returns: true 如果两个标签语义上冲突
    func conflicts(with other: Tag) -> Bool {
        // 规则1: 特定值对的冲突（例如，不能同时是“简单”和“困难”）
        let conflictValuePairs: [(String, String)] = [
            ("简单", "困难"),
            ("快速", "详细"),
            ("基础", "高级") // 假设有“高级”标签
        ]

        if conflictValuePairs.contains(where: { pair in
            (self.value == pair.0 && other.value == pair.1) ||
            (self.value == pair.1 && other.value == pair.0)
        }) {
            return true
        }

        // 规则2: 同一类型标签的冲突（例如，不能同时有两个难度标签，除非它们是同一个标签）
        // 排除自定义标签，因为自定义标签可以很灵活
        if self.type != .custom && self.type == other.type && self.id != other.id {
            // 如果两个标签类型相同，且不是同一个标签，则可能冲突
            // 例如：不能同时有 "语文" 和 "数学" (TagType.subject)
            // 不能同时有 "考试" 和 "作业" (TagType.activity) - 这种冲突可能需要业务决定
            // 这里我们假设，同一类型下，除了自定义标签外，通常是互斥的。
            return true
        }

        return false
    }

    /// 检查此标签是否与给定学科兼容
    /// 此方法用于在 QuestionMetadata 中验证学科标签的一致性。
    /// - Parameter subject: 要检查的 Subject
    /// - Returns: 如果兼容则为 true，否则为 false
    func isCompatibleWith(subject: Subject) -> Bool {
        if self.type == .subject { // 注意这里直接使用 type 属性
            return self.value == subject.displayName // 假设 Subject 的 displayName 与 Tag 的 value 匹配
        }
        return true // 非学科标签默认兼容所有学科
    }
}

// MARK: - CustomStringConvertible (用于调试和日志)
extension Tag: CustomStringConvertible {
    var description: String {
        "\(value) (类型: \(type.displayName), 颜色: \(color.displayName))"
    }
}

