//
//  Difficulty.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainErrors // 如果有 Difficulty 相关的错误，或 QuestionDomainError

/// 难度对应的颜色概念（不绑定具体UI框架）
/// 这是一个值对象，用于在领域层表达与难度相关的颜色语义。
/// UI层会根据此处的 hexValue 进行具体的颜色渲染。
enum DifficultyColor: String, CaseIterable, Codable, Sendable, Hashable {
    case green = "绿色"
    case blue = "蓝色"
    case yellow = "黄色"
    case orange = "橙色"
    case red = "红色"

    /// 颜色的十六进制值（领域层定义，UI层使用）
    var hexValue: String {
        switch self {
        case .green: return "#34C759"
        case .blue: return "#007AFF"
        case .yellow: return "#FFCC00"
        case .orange: return "#FF9500"
        case .red: return "#FF3B30"
        }
    }

    /// 颜色的语义含义
    var meaning: String {
        switch self {
        case .green: return "简单安全"
        case .blue: return "稳定可靠"
        case .yellow: return "需要注意"
        case .orange: return "具有挑战"
        case .red: return "高度困难"
        }
    }
}

/// 题目难度级别
/// 使用整数值表示难度等级，数值越大难度越高。
/// 这是一个值对象，它封装了难度的核心属性、业务逻辑和行为。
enum Difficulty: Int, CaseIterable, Codable, Identifiable, Sendable, Hashable {
    case veryEasy = 1 // 很简单
    case easy = 2     // 简单
    case medium = 3   // 中等
    case hard = 4     // 困难
    case veryHard = 5 // 很困难

    /// Identifiable 协议要求的 id 属性，使用 rawValue 作为唯一标识
    var id: Int { rawValue }

    /// 难度的中文显示名称
    var displayName: String {
        switch self {
        case .veryEasy: return "很简单"
        case .easy: return "简单"
        case .medium: return "中等"
        case .hard: return "困难"
        case .veryHard: return "很困难"
        }
    }

    /// 难度的英文名称（用于日志或API，保持领域层纯粹性）
    var englishName: String {
        switch self {
        case .veryEasy: return "very_easy"
        case .easy: return "easy"
        case .medium: return "medium"
        case .hard: return "hard"
        case .veryHard: return "very_hard"
        }
    }

    /// 难度对应的颜色概念名称（领域概念，不绑定具体UI颜色值）
    var colorName: DifficultyColor {
        switch self {
        case .veryEasy: return .green
        case .easy: return .blue
        case .medium: return .yellow
        case .hard: return .orange
        case .veryHard: return .red
        }
    }

    /// 难度系数（用于计算分数权重、复习间隔等业务逻辑）
    var coefficient: Double {
        switch self {
        case .veryEasy: return 0.8
        case .easy: return 1.0
        case .medium: return 1.2
        case .hard: return 1.5
        case .veryHard: return 2.0
        }
    }
}

// MARK: - 业务方法
extension Difficulty {
    /// 获取下一个难度级别
    /// - Returns: 下一个难度级别，如果已是最高级别则返回 nil
    func next() -> Difficulty? {
        return Difficulty(rawValue: rawValue + 1)
    }

    /// 获取上一个难度级别
    /// - Returns: 上一个难度级别，如果已是最低级别则返回 nil
    func previous() -> Difficulty? {
        return Difficulty(rawValue: rawValue - 1)
    }

    /// 判断是否为简单级别（很简单或简单）
    /// - Returns: true 如果是简单级别
    func isEasy() -> Bool {
        return self == .veryEasy || self == .easy
    }

    /// 判断是否为困难级别（困难或很困难）
    /// - Returns: true 如果是困难级别
    func isHard() -> Bool {
        return self == .hard || self == .veryHard
    }

    /// 判断是否为中等级别
    /// - Returns: true 如果是中等级别
    func isMedium() -> Bool {
        return self == .medium
    }

    /// 比较两个难度的差距
    /// - Parameter other: 另一个难度
    /// - Returns: 难度级别的差距（正数表示当前难度更高）
    func gap(from other: Difficulty) -> Int {
        return self.rawValue - other.rawValue
    }

    /// 根据用户表现建议下一个难度
    /// 此方法封装了难度调整的业务逻辑。
    /// - Parameter accuracy: 用户在当前难度下的准确率 (0.0-1.0)
    /// - Returns: 建议的下一个难度级别
    func suggestedNext(basedOn accuracy: Double) -> Difficulty {
        switch accuracy {
        case 0.9...:
            // 准确率很高，可以增加难度
            return next() ?? self // 如果已是最高难度，则保持当前难度
        case 0.7..<0.9:
            // 准确率适中，保持当前难度
            return self
        case 0.5..<0.7:
            // 准确率偏低，可能需要降低难度
            return previous() ?? self // 如果已是最低难度，则保持当前难度
        default:
            // 准确率很低，应该降低难度
            return previous() ?? .veryEasy // 如果已是最低难度，则直接返回最低难度
        }
    }
}

// MARK: - 静态方法
extension Difficulty {
    /// 从字符串创建难度
    /// - Parameter string: 难度的显示名称或英文名称
    /// - Returns: 对应的难度级别，如果无法识别则返回 nil
    static func from(string: String) -> Difficulty? {
        // 先尝试中文显示名称，再尝试英文名称
        for difficulty in allCases {
            if difficulty.displayName == string || difficulty.englishName == string {
                return difficulty
            }
        }
        return nil
    }

    /// 从系数范围获取建议难度
    /// 此方法用于根据给定的系数找到最匹配的难度级别。
    /// - Parameter coefficient: 系数值
    /// - Returns: 最接近该系数的难度级别
    static func from(coefficient: Double) -> Difficulty {
        // 计算每个难度系数与给定系数的绝对差值
        let differences = allCases.map { abs($0.coefficient - coefficient) }
        // 找到差值最小的索引
        let minIndex = differences.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
        // 返回对应索引的难度级别
        return allCases[minIndex]
    }

    /// 获取所有难度级别，按从易到难排序
    /// - Returns: 排序后的难度数组
    static func allOrderedByLevel() -> [Difficulty] {
        // 由于 rawValue 已经是有序的，直接使用 allCases 即可，或者明确排序
        return allCases.sorted { $0.rawValue < $1.rawValue }
    }
}

// MARK: - Comparable 支持
extension Difficulty: Comparable {
    /// 比较两个难度级别的大小，基于其 rawValue（整数值）
    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - CustomStringConvertible (用于调试和日志)
extension Difficulty: CustomStringConvertible {
    var description: String {
        displayName
    }
}

