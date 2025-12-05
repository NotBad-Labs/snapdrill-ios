//
//  SourceCategory.swift
//  NotBad
//
//  来源分类值对象
//

import Foundation

// MARK: - SourceCategory

/// 来源分类
///
/// 将题目来源按性质分为四大类。
///
/// ## 分类说明
///
/// - **官方**：课本、历年真题等权威来源
/// - **学校**：校内考试、模拟考、作业
/// - **课外**：练习册、辅导班、竞赛
/// - **其他**：网络、自测等
///
/// ## 使用示例
///
/// ```swift
/// let category = SourceCategory.official
/// print(category.displayName)  // "官方"
/// print(category.icon)         // "building.columns"
/// ```
enum SourceCategory: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {

    /// 官方来源
    ///
    /// 包括课本、历年真题等权威出版物。
    case official = "official"

    /// 学校来源
    ///
    /// 包括考试、模拟考、作业等校内资料。
    case school = "school"

    /// 课外来源
    ///
    /// 包括练习册、辅导班、竞赛等校外资料。
    case extra = "extra"

    /// 其他来源
    ///
    /// 包括网络、自测等来源不明确的资料。
    case other = "other"

    // MARK: - Identifiable

    /// 唯一标识符
    nonisolated var id: String { rawValue }
}

// MARK: - SourceCategory Display Properties

extension SourceCategory {

    /// 显示名称
    nonisolated var displayName: String {
        String(localized: localizationKey)
    }

    /// 本地化键值
    private var localizationKey: String.LocalizationValue {
        switch self {
        case .official: "source_category_official"
        case .school: "source_category_school"
        case .extra: "source_category_extra"
        case .other: "source_category_other"
        }
    }

    /// 简短标签
    nonisolated var shortLabel: String {
        String(localized: shortLabelKey)
    }

    /// 简短标签本地化键值
    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .official: "source_category_official_short"
        case .school: "source_category_school_short"
        case .extra: "source_category_extra_short"
        case .other: "source_category_other_short"
        }
    }

    /// SF Symbol 图标名称
    nonisolated var icon: String {
        switch self {
        case .official: "building.columns"
        case .school: "graduationcap"
        case .extra: "books.vertical"
        case .other: "ellipsis.circle"
        }
    }

    /// 分类描述
    nonisolated var categoryDescription: String {
        String(localized: categoryDescriptionKey)
    }

    /// 分类描述本地化键值
    private var categoryDescriptionKey: String.LocalizationValue {
        switch self {
        case .official: "source_category_official_desc"
        case .school: "source_category_school_desc"
        case .extra: "source_category_extra_desc"
        case .other: "source_category_other_desc"
        }
    }
}
