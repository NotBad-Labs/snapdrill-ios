//
//  Difficulty.swift
//  NotBad
//
//  题目难度值对象 - 5级制
//

import Foundation

// MARK: - Difficulty

/// 题目难度等级（5级制）
///
/// 表示题目的难度等级，从基础到压轴共5个级别。
/// 用于帮助学生识别题目难度，合理分配复习时间。
///
/// ## 难度等级
/// - ``basic``: 送分题 - 基础概念直接应用
/// - ``easy``: 简单题 - 常规题型
/// - ``medium``: 中等题 - 需要分析思考
/// - ``hard``: 困难题 - 综合性强
/// - ``extreme``: 压轴题 - 极具挑战性
///
/// ## 使用示例
/// ```swift
/// let difficulty = Difficulty.medium
/// print(difficulty.displayName)  // "中等"
/// print(difficulty.stars)        // 3
/// print(difficulty.coefficient)  // 0.5
/// ```
enum Difficulty: Int, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    /// 送分题 - 基础概念直接应用，几乎不会出错
    case basic = 0

    /// 简单题 - 常规题型，稍加思考即可解决
    case easy = 1

    /// 中等题 - 需要一定分析，容易粗心出错
    case medium = 2

    /// 困难题 - 综合性强，需要灵活运用多个知识点
    case hard = 3

    /// 压轴题 - 压轴难度，极具挑战性
    case extreme = 4

    // MARK: Identifiable

    nonisolated var id: Int { rawValue }
}

// MARK: - Difficulty Display Properties

extension Difficulty {
    /// 显示名称
    ///
    /// 用于在 UI 中显示完整的难度名称
    nonisolated var displayName: String {
        String(localized: localizationKey)
    }

    /// 本地化键值
    private var localizationKey: String.LocalizationValue {
        switch self {
        case .basic: "difficulty_basic"
        case .easy: "difficulty_easy"
        case .medium: "difficulty_medium"
        case .hard: "difficulty_hard"
        case .extreme: "difficulty_extreme"
        }
    }

    /// 简短标签
    ///
    /// 单字标签，适用于空间受限的场景（如徽章、标签）
    nonisolated var shortLabel: String {
        String(localized: shortLabelKey)
    }

    /// 简短标签本地化键值
    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .basic: "difficulty_basic_short"
        case .easy: "difficulty_easy_short"
        case .medium: "difficulty_medium_short"
        case .hard: "difficulty_hard_short"
        case .extreme: "difficulty_extreme_short"
        }
    }

    /// 详细描述
    ///
    /// 提供该难度等级的详细说明，帮助用户理解
    nonisolated var detailText: String {
        String(localized: detailTextKey)
    }

    /// 详细描述本地化键值
    private var detailTextKey: String.LocalizationValue {
        switch self {
        case .basic: "difficulty_basic_detail"
        case .easy: "difficulty_easy_detail"
        case .medium: "difficulty_medium_detail"
        case .hard: "difficulty_hard_detail"
        case .extreme: "difficulty_extreme_detail"
        }
    }
}

// MARK: - Difficulty Visual Properties

extension Difficulty {
    /// SF Symbol 图标名称
    ///
    /// 返回适合该难度等级的 SF Symbol 图标
    nonisolated var icon: String {
        switch self {
        case .basic: "gift"
        case .easy: "star"
        case .medium: "star.leadinghalf.filled"
        case .hard: "star.fill"
        case .extreme: "flame.fill"
        }
    }

    /// 星级评分（1-5）
    ///
    /// 用于可视化显示难度等级
    nonisolated var stars: Int { rawValue + 1 }
}

// MARK: - Difficulty Metrics

extension Difficulty {
    /// 难度系数（0.0-1.0）
    ///
    /// 归一化的难度值，可用于算法计算
    /// - Returns: 0.0（最简单）到 1.0（最困难）之间的值
    nonisolated var coefficient: Double {
        Double(rawValue) / Double(Self.allCases.count - 1)
    }

    /// 预计耗时倍数
    ///
    /// 相对于题型标准时间（`ReviewItemType.estimatedMinutes`）的倍数。
    /// 例如：中等难度计算题 = 8分钟 × 1.5 = 12分钟
    /// - Returns: 0.5（送分题）到 3.0（压轴题）的倍数系数
    nonisolated var timeMultiplier: Double {
        switch self {
        case .basic: 0.5
        case .easy: 1.0
        case .medium: 1.5
        case .hard: 2.0
        case .extreme: 3.0
        }
    }
}

// MARK: - Difficulty Comparable

extension Difficulty: Comparable {
    /// 比较两个难度等级
    ///
    /// 基于 rawValue 进行比较，数值越大难度越高
    nonisolated static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Difficulty CustomStringConvertible

extension Difficulty: CustomStringConvertible {
    nonisolated var description: String { displayName }
}

// MARK: - Difficulty Factory Methods

extension Difficulty {
    /// 从星级创建难度（1-5）
    /// - Parameter stars: 星级数量
    /// - Returns: 对应的难度等级，无效输入返回 nil
    static func from(stars: Int) -> Difficulty? {
        Self(rawValue: stars - 1)
    }

    /// 从系数创建难度（0.0-1.0）
    /// - Parameter coefficient: 难度系数
    /// - Returns: 最接近的难度等级
    static func from(coefficient: Double) -> Difficulty {
        let clamped = max(0, min(1, coefficient))
        let index = Int(round(clamped * Double(Self.allCases.count - 1)))
        return Self(rawValue: index) ?? .medium
    }
}
