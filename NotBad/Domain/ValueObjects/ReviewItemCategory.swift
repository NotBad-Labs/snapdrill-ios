//
//  ReviewItemCategory.swift
//  NotBad
//
//  题型分类值对象
//

import SwiftUI

// MARK: - ReviewItemCategory

/// 题型分类
///
/// 将各种题型按评分方式和答案特点分为四大类。
///
/// ## 分类标准
///
/// - **客观题**：答案唯一，对错分明
/// - **主观题**：答案开放，按步给分
/// - **综合题**：综合能力，整体评分
/// - **其他**：不便分类的特殊题型
///
/// ## 使用示例
///
/// ```swift
/// let category = ReviewItemCategory.objective
/// print(category.displayName)  // "客观题"
/// print(category.gradingCharacteristic)  // "答案唯一，对错分明"
/// ```
enum ReviewItemCategory: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {

    /// 客观题
    ///
    /// 包括选择、多选、判断、填空、连线等题型。
    /// 答案唯一，评分标准明确。
    case objective = "客观题"

    /// 主观题
    ///
    /// 包括简答、计算、证明、作图、实验、材料分析等题型。
    /// 答案开放，通常按步骤给分。
    case subjective = "主观题"

    /// 综合题
    ///
    /// 包括阅读理解、作文、完形填空等题型。
    /// 考察综合能力，整体评分。
    case comprehensive = "综合题"

    /// 其他
    ///
    /// 不便分类的特殊题型。
    case other = "其他"

    // MARK: - Identifiable

    /// 唯一标识符
    nonisolated var id: String { rawValue }
}

// MARK: - ReviewItemCategory Display Properties

extension ReviewItemCategory {

    /// 显示名称
    nonisolated var displayName: String {
        String(localized: localizationKey)
    }

    /// 本地化键值
    private var localizationKey: String.LocalizationValue {
        switch self {
        case .objective: "item_category_objective"
        case .subjective: "item_category_subjective"
        case .comprehensive: "item_category_comprehensive"
        case .other: "item_category_other"
        }
    }

    /// SF Symbol 图标名称
    nonisolated var icon: String {
        switch self {
        case .objective: "checkmark.square"
        case .subjective: "pencil"
        case .comprehensive: "doc.text"
        case .other: "ellipsis.circle"
        }
    }

    /// 主题颜色
    nonisolated var color: Color {
        switch self {
        case .objective: .blue
        case .subjective: .orange
        case .comprehensive: .purple
        case .other: .gray
        }
    }

    /// 评分特点描述
    nonisolated var gradingCharacteristic: String {
        String(localized: gradingCharacteristicKey)
    }

    /// 评分特点本地化键值
    private var gradingCharacteristicKey: String.LocalizationValue {
        switch self {
        case .objective: "item_category_objective_grading"
        case .subjective: "item_category_subjective_grading"
        case .comprehensive: "item_category_comprehensive_grading"
        case .other: "item_category_other_grading"
        }
    }
}
