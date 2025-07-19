//
//  Grade.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainErrors // 包含 AcademicDomainError (或其他通用领域错误)

/// 学术领域错误 (仅为编译目的包含，实际应从 AcademicDomainError.swift 导入)
// Note: In a real project, this would be in its own file: Core/Domain/Errors/AcademicDomainError.swift
enum AcademicDomainError: Error, CustomStringConvertible, LocalizedError {
    case invalidGradeValue(Int) // 年级值无效
    case invalidGradeRange(Int, Int) // 年级范围无效
    case gradeNotFound(String) // 年级未找到

    var description: String {
        switch self {
        case .invalidGradeValue(let value):
            return "年级 '\(value)' 无效，必须在 1 到 12 之间。"
        case .invalidGradeRange(let min, let max):
            return "年级范围无效，最小值 '\(min)' 不能大于最大值 '\(max)'。"
        case .gradeNotFound(let name):
            return "未找到名为 '\(name)' 的年级。"
        }
    }

    var errorDescription: String? {
        return description
    }
}


/// 年级值对象
/// 封装了中国大陆教育体系中的年级信息。
/// 这是一个不可变的值对象，内部包含自验证逻辑，确保年级值的有效性。
///
/// 遵循 `Codable`, `Hashable`, `Sendable` 协议，以支持序列化、哈希和并发安全。
struct Grade: Codable, Sendable, Hashable {
    let value: Int // 年级的具体数值（例如：1代表小学一年级，7代表初一，10代表高一）

    /// 初始化 Grade
    /// - Parameter value: 年级的具体数值
    /// - Throws: AcademicDomainError 如果年级值超出有效范围（1到12）
    init(value: Int) throws {
        // 验证：年级值必须在 1 到 12 之间
        guard value >= 1 && value <= 12 else {
            throw AcademicDomainError.invalidGradeValue(value)
        }
        self.value = value
    }

    /// 获取年级的中文显示名称
    var displayName: String {
        switch value {
        case 1...6:
            return "小学\(value)年级"
        case 7...9:
            return "初中\(value - 6)年级"
        case 10...12:
            return "高中\(value - 9)年级"
        default:
            return "未知年级" // 理论上不会发生，因为初始化器已验证
        }
    }

    /// 判断年级是否属于小学阶段
    var isPrimarySchool: Bool {
        return value >= 1 && value <= 6
    }

    /// 判断年级是否属于初中阶段
    var isJuniorHighSchool: Bool {
        return value >= 7 && value <= 9
    }

    /// 判断年级是否属于高中阶段
    var isSeniorHighSchool: Bool {
        return value >= 10 && value <= 12
    }

    /// 获取下一个年级
    /// - Returns: 下一个年级的值对象，如果已是最高年级则返回 nil
    func next() -> Grade? {
        guard value < 12 else { return nil }
        return try? Grade(value: value + 1)
    }

    /// 获取上一个年级
    /// - Returns: 上一个年级的值对象，如果已是最低年级则返回 nil
    func previous() -> Grade? {
        guard value > 1 else { return nil }
        return try? Grade(value: value - 1)
    }
}

// MARK: - Comparable (使年级可比较大小)
extension Grade: Comparable {
    static func < (lhs: Grade, rhs: Grade) -> Bool {
        return lhs.value < rhs.value
    }
}

// MARK: - CustomStringConvertible (用于调试和日志)
extension Grade: CustomStringConvertible {
    var description: String {
        displayName
    }
}

// MARK: - Sample Data for Testing
extension Grade {
    static func primaryOne() -> Grade { return try! Grade(value: 1) }
    static func juniorOne() -> Grade { return try! Grade(value: 7) }
    static func seniorOne() -> Grade { return try! Grade(value: 10) }
    static func highest() -> Grade { return try! Grade(value: 12) }
    static func lowest() -> Grade { return try! Grade(value: 1) }

    static func invalidSample() -> Grade {
        return try! Grade(value: 0) // 这是一个无效的年级，用于测试错误处理
    }
}

