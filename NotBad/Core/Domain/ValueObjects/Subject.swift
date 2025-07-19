//
//  Subject.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
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
    case emptyTag
    case conflictingTags(Tag, Tag) // Assuming Tag is defined elsewhere
    case cannotReduceDifficultyForMasteredQuestion
    case cannotReviewUnatttemptedQuestion
    case tooManyAttemptsForMasteredQuestion
    case inconsistentSubjectAndTags(subject: Subject, tag: Tag) // Assuming Subject and Tag are defined elsewhere
    case invalidStateForOperation(String) // 更通用的状态错误

    // MARK: - Subject 相关的验证错误 (已从 ValidationError 整合)
    case emptySubjectName
    case subjectNameTooLong(String)
    case duplicateCoreSubject(String)
    case unknownCoreSubject(String) // 用于解码时发现未知核心学科

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

/// 学科分类枚举
/// 用于对学科进行更高级别的分类，例如语言文学、理科等。
enum SubjectCategory: String, CaseIterable, Codable, Sendable, Hashable {
    case language = "语言文学"
    case mathematics = "数学"
    case science = "理科"
    case humanities = "人文社科"
    case technology = "技术"
    case other = "其他" // 用于无法明确分类的学科，包括自定义学科

    /// 分类的显示名称
    var displayName: String {
        return rawValue
    }
}

/// 学科值对象
/// 代表中国大陆教育体系中的学科分类，包括官方核心学科和用户自定义学科。
/// 这是一个不可变的值对象，封装了学科名称和其是否为自定义的属性，并包含自验证逻辑。
struct Subject: Identifiable, Hashable, Sendable {
    /// Identifiable 协议要求的 id 属性，使用 name 作为唯一标识
    let id: String { name }
    let name: String // 学科名称
    let isCustom: Bool // 标识是否为用户自定义学科

    /// 显示名称（目前与 name 相同，但为未来本地化预留）
    var displayName: String {
        name
    }

    // MARK: - 初始化器

    /// 私有初始化器，用于内部创建 Subject 实例，特别是核心学科。
    /// 防止外部直接创建不符合规则的学科。
    private init(name: String, isCustom: Bool) {
        self.name = name
        self.isCustom = isCustom
    }

    /// 创建自定义学科的公开初始化器。
    /// 此初始化器包含严格的验证规则，确保自定义学科的有效性。
    /// - Parameter customName: 自定义学科名称
    /// - Throws: QuestionDomainError 如果名称无效或与核心学科重复
    init(customName: String) throws {
        let trimmed = customName.trimmingCharacters(in: .whitespacesAndNewlines)

        // 验证：名称不能为空
        guard !trimmed.isEmpty else {
            throw QuestionDomainError.emptySubjectName
        }

        // 验证：名称长度限制 (示例：最多10个字符)
        guard trimmed.count <= 10 else {
            throw QuestionDomainError.subjectNameTooLong(trimmed)
        }

        // 验证：不能与核心学科名称重复
        guard !Self.coreSubjects.contains(where: { $0.name == trimmed }) else {
            throw QuestionDomainError.duplicateCoreSubject(trimmed)
        }

        self.name = trimmed
        self.isCustom = true
    }
}

// MARK: - 预定义核心学科
extension Subject {
    /// 中国大陆官方核心学科列表（不可变）。
    /// 这些是预定义的、不可修改的学科实例。
    static let coreSubjects: [Subject] = [
        Subject(name: "语文", isCustom: false),
        Subject(name: "数学", isCustom: false),
        Subject(name: "外语", isCustom: false),
        Subject(name: "道德与法治", isCustom: false),
        Subject(name: "历史", isCustom: false),
        Subject(name: "地理", isCustom: false),
        Subject(name: "物理", isCustom: false),
        Subject(name: "化学", isCustom: false),
        Subject(name: "生物", isCustom: false),
        Subject(name: "信息技术", isCustom: false)
    ]

    // 便捷访问器，提供类型安全的访问方式，直接引用 coreSubjects 中的实例
    static let chinese = coreSubjects[0] // 假设顺序固定，或通过 findCoreSubject
    static let mathematics = coreSubjects[1]
    static let foreignLanguage = coreSubjects[2]
    static let moralAndLaw = coreSubjects[3]
    static let history = coreSubjects[4]
    static let geography = coreSubjects[5]
    static let physics = coreSubjects[6]
    static let chemistry = coreSubjects[7]
    static let biology = coreSubjects[8]
    static let informationTechnology = coreSubjects[9]
}

// MARK: - 查找方法
extension Subject {
    /// 根据名称查找核心学科。
    /// - Parameter name: 学科名称
    /// - Returns: 找到的学科实例，如果不存在则返回 nil。
    static func findCoreSubject(byName name: String) -> Subject? {
        return coreSubjects.first { $0.name == name }
    }

    /// 获取所有核心学科。
    /// - Returns: 所有核心学科的数组。
    static func allCoreSubjects() -> [Subject] {
        return coreSubjects
    }
}

// MARK: - 业务方法
extension Subject {
    /// 判断是否为核心学科。
    /// - Returns: 如果是官方核心学科则为 true，如果是自定义学科则为 false。
    func isCore() -> Bool {
        return !isCustom
    }

    /// 获取学科分类。
    /// - Returns: 学科所属的 SubjectCategory。自定义学科归为 .other。
    func category() -> SubjectCategory {
        guard isCore() else { return .other } // 自定义学科归为"其他"

        switch name {
        case "语文", "外语":
            return .language
        case "数学":
            return .mathematics
        case "物理", "化学", "生物":
            return .science
        case "历史", "地理", "道德与法治":
            return .humanities
        case "信息技术":
            return .technology
        default:
            return .other // 核心学科中未明确分类的
        }
    }

    /// 判断是否为理科学科。
    /// - Returns: 如果是理科学科（或数学）则为 true。
    func isScience() -> Bool {
        let currentCategory = category()
        return currentCategory == .science || currentCategory == .mathematics
    }

    /// 判断是否为文科学科。
    /// - Returns: 如果是文科学科（或语言文学）则为 true。
    func isHumanities() -> Bool {
        let currentCategory = category()
        return currentCategory == .humanities || currentCategory == .language
    }
}

// MARK: - Codable 支持
extension Subject: Codable {
    /// 编码时保存名称和是否自定义的信息。
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(isCustom, forKey: .isCustom)
    }

    /// 解码时重建 Subject 实例。
    /// 根据 isCustom 标志，选择使用自定义学科的验证初始化器或查找核心学科。
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let isCustom = try container.decode(Bool.self, forKey: .isCustom)

        if isCustom {
            // 对于自定义学科，使用其验证初始化器
            try self.init(customName: name)
        } else {
            // 对于核心学科，从预定义列表中查找，确保其有效性
            guard let coreSubject = Self.findCoreSubject(byName: name) else {
                throw QuestionDomainError.unknownCoreSubject(name) // 抛出更具体的领域错误
            }
            self = coreSubject
        }
    }

    private enum CodingKeys: String, CodingKey {
        case name, isCustom
    }
}

// MARK: - CustomStringConvertible (用于调试和日志)
extension Subject: CustomStringConvertible {
    var description: String {
        isCustom ? "\(name)(自定义)" : name
    }
}

