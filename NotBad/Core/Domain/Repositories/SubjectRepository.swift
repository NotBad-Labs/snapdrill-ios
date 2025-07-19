//
//  SubjectRepository.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainErrors // 包含 QuestionDomainError (或更通用的 DomainError)

/// 题目领域错误 (仅为编译目的包含，实际应从 QuestionDomainError.swift 导入)
enum QuestionDomainError: Error, CustomStringConvertible, LocalizedError {
    case emptySubjectName
    case subjectNameTooLong(String)
    case duplicateCoreSubject(String)
    case unknownCoreSubject(String)
    case invalidStateForOperation(String) // 更通用的状态错误

    var description: String {
        switch self {
        case .emptySubjectName:
            return "学科名称不能为空。"
        case .subjectNameTooLong(let name):
            return "学科名称太长: '\(name)'（最多10个字符）。"
        case .duplicateCoreSubject(let name):
            return "不能创建与核心学科重复的自定义学科: '\(name)'。"
        case .unknownCoreSubject(let name):
            return "未知的核心学科名称: '\(name)'。"
        case .invalidStateForOperation(let operation):
            return "当前操作不允许: '\(operation)'。"
        }
    }

    var errorDescription: String? {
        return description
    }
}

/// 学科值对象 (仅为编译目的包含，实际应从 Subject.swift 导入)
struct Subject: Identifiable, Hashable, Sendable, Codable {
    let id: String { name }
    let name: String
    let isCustom: Bool

    private init(name: String, isCustom: Bool) {
        self.name = name
        self.isCustom = isCustom
    }

    init(customName: String) throws {
        let trimmed = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw QuestionDomainError.emptySubjectName }
        guard trimmed.count <= 10 else { throw QuestionDomainError.subjectNameTooLong(trimmed) }
        guard !Subject.coreSubjects.contains(where: { $0.name == trimmed }) else { throw QuestionDomainError.duplicateCoreSubject(trimmed) }
        self.name = trimmed
        self.isCustom = true
    }

    var displayName: String { name }

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

    static func findCoreSubject(byName name: String) -> Subject? {
        return coreSubjects.first { $0.name == name }
    }

    func isCore() -> Bool { !isCustom }

    // Codable conformance for Subject
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(isCustom, forKey: .isCustom)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let isCustom = try container.decode(Bool.self, forKey: .isCustom)

        if isCustom {
            try self.init(customName: name)
        } else {
            guard let coreSubject = Self.findCoreSubject(byName: name) else {
                throw QuestionDomainError.unknownCoreSubject(name)
            }
            self = coreSubject
        }
    }

    private enum CodingKeys: String, CodingKey {
        case name, isCustom
    }
}


/// 学科仓储接口
/// 定义了对 `Subject` 值对象（或实体，取决于其在领域中的建模）进行持久化和检索的契约。
/// 考虑到核心学科是预定义的，这个仓储主要用于管理用户自定义学科。
///
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol SubjectRepository: Sendable {

    /// 保存或更新一个 `Subject` 实例。
    /// 主要用于保存用户自定义学科。核心学科通常不需要保存。
    /// - Parameter subject: 要保存或更新的 `Subject` 实例。
    /// - Throws: `QuestionDomainError` (如 `duplicateCoreSubject`) 或其他持久化相关的错误。
    func save(_ subject: Subject) async throws

    /// 根据名称查找一个 `Subject` 实例。
    /// 可以查找核心学科或自定义学科。
    /// - Parameter name: 要查找的学科名称。
    /// - Returns: 找到的 `Subject` 实例，如果不存在则为 `nil`。
    /// - Throws: `QuestionDomainError` 或其他持久化相关的错误。
    func find(by name: String) async throws -> Subject?

    /// 删除一个 `Subject` 实例。
    /// 主要用于删除用户自定义学科。核心学科不可删除。
    /// - Parameter subject: 要删除的 `Subject` 实例。
    /// - Throws: `QuestionDomainError` (如 `invalidStateForOperation` 如果尝试删除核心学科) 或其他持久化相关的错误。
    func delete(_ subject: Subject) async throws

    /// 获取所有学科（包括核心学科和自定义学科）。
    /// - Returns: 包含所有 `Subject` 实例的数组。
    /// - Throws: `QuestionDomainError` 或其他持久化相关的错误。
    func findAll() async throws -> [Subject]

    /// 获取所有自定义学科。
    /// - Returns: 包含所有用户自定义 `Subject` 实例的数组。
    /// - Throws: `QuestionDomainError` 或其他持久化相关的错误。
    func findCustomSubjects() async throws -> [Subject]

    // 您可以根据业务需求添加更多查询方法，例如：
    // func searchSubjects(searchTerm: String) async throws -> [Subject]
}

