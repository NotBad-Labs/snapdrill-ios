//
//  Score.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainErrors // 包含 QuestionDomainError (或其他通用领域错误)

/// 题目领域错误 (仅为编译目的包含，实际应从 QuestionDomainError.swift 导入)
// Note: In a real project, this would be in its own file: Core/Domain/Errors/QuestionDomainError.swift
enum QuestionDomainError: Error, CustomStringConvertible, LocalizedError {
    case invalidScoreValue(Double, Double, Double) // 分数无效，包含值、最小值、最大值

    var description: String {
        switch self {
        case .invalidScoreValue(let value, let min, let max):
            return "分数 '\(value)' 无效，必须在 \(min) 到 \(max) 之间。"
        default:
            return "发生未知题目领域错误。"
        }
    }

    var errorDescription: String? {
        return description
    }
}


/// 分数值对象
/// 封装了学习或测试中的分数，并包含分数范围的验证逻辑。
/// 这是一个不可变的值对象，确保分数的有效性和一致性。
///
/// 遵循 `Codable`, `Hashable`, `Sendable` 协议，以支持序列化、哈希和并发安全。
struct Score: Codable, Sendable, Hashable {
    let value: Double // 分数的具体数值
    let minValue: Double // 分数的最小值
    let maxValue: Double // 分数的最大值

    /// 初始化 Score
    /// - Parameters:
    ///   - value: 分数的具体数值
    ///   - minValue: 分数允许的最小值，默认为 0.0
    ///   - maxValue: 分数允许的最大值，默认为 100.0
    /// - Throws: QuestionDomainError 如果分数超出有效范围
    init(value: Double, minValue: Double = 0.0, maxValue: Double = 100.0) throws {
        guard value >= minValue && value <= maxValue else {
            throw QuestionDomainError.invalidScoreValue(value, minValue, maxValue) // 验证：分数范围
        }
        self.value = value
        self.minValue = minValue
        self.maxValue = maxValue
    }

    /// 判断分数是否为满分
    var isPerfectScore: Bool {
        value == maxValue
    }

    /// 判断分数是否为零分
    var isZeroScore: Bool {
        value == minValue
    }

    /// 计算分数相对于最大值的百分比
    var percentage: Double {
        guard maxValue > minValue else { return 0.0 } // 避免除以零
        return (value - minValue) / (maxValue - minValue) * 100.0
    }

    /// 比较两个分数是否相等（值和范围都相等）
    static func == (lhs: Score, rhs: Score) -> Bool {
        return lhs.value == rhs.value &&
               lhs.minValue == rhs.minValue &&
               lhs.maxValue == rhs.maxValue
    }

    /// 计算哈希值
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
        hasher.combine(minValue)
        hasher.combine(maxValue)
    }
}

// MARK: - CustomStringConvertible (用于调试和日志)
extension Score: CustomStringConvertible {
    var description: String {
        "\(value) / \(maxValue)"
    }
}

// MARK: - Comparable (使分数可比较大小)
extension Score: Comparable {
    static func < (lhs: Score, rhs: Score) -> Bool {
        // 只比较分数的值，不考虑范围
        return lhs.value < rhs.value
    }
}

// MARK: - Sample Data for Testing
extension Score {
    static func samplePerfect() -> Score {
        return try! Score(value: 100.0)
    }

    static func samplePassing() -> Score {
        return try! Score(value: 75.0)
    }

    static func sampleFailing() -> Score {
        return try! Score(value: 40.0)
    }

    static func sampleCustomRange() -> Score {
        return try! Score(value: 5.0, minValue: 0.0, maxValue: 10.0)
    }

    static func invalidSample() -> Score {
        return try! Score(value: 101.0) // 这是一个无效的分数，用于测试错误处理
    }
}

