//
//  SubjectCategory.swift
//  NotBad
//
//  学科分类值对象
//

import Foundation

// MARK: - SubjectCategory

/// 学科分类
///
/// 将学科按性质分为五大类别，便于筛选和展示。
///
/// ## 分类说明
/// - ``language``: 语言类 - 语文、英语
/// - ``science``: 理科类 - 数学、物理、化学、生物、科学
/// - ``humanities``: 人文类 - 历史、地理、政治、道德与法治
/// - ``technology``: 技术类 - 信息技术、通用技术
/// - ``other``: 其他 - 无法归类的学科
///
/// ## 使用示例
/// ```swift
/// let category = SubjectCategory.science
/// print(category.displayName)  // "理科"
/// print(category.icon)         // "flask"
/// ```
enum SubjectCategory: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    case language = "language"
    case science = "science"
    case humanities = "humanities"
    case technology = "technology"
    case other = "other"

    // MARK: Identifiable

    nonisolated var id: String { rawValue }
}

// MARK: - Display Properties

extension SubjectCategory {
    /// 显示名称
    nonisolated var displayName: String {
        String(localized: localizationKey)
    }

    /// 本地化键值
    private var localizationKey: String.LocalizationValue {
        switch self {
        case .language: "subject_category_language"
        case .science: "subject_category_science"
        case .humanities: "subject_category_humanities"
        case .technology: "subject_category_technology"
        case .other: "subject_category_other"
        }
    }

    /// 简短标签
    nonisolated var shortLabel: String {
        String(localized: shortLabelKey)
    }

    /// 简短标签本地化键值
    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .language: "subject_category_language_short"
        case .science: "subject_category_science_short"
        case .humanities: "subject_category_humanities_short"
        case .technology: "subject_category_technology_short"
        case .other: "subject_category_other_short"
        }
    }

    /// SF Symbol 图标名称
    nonisolated var icon: String {
        switch self {
        case .language: "textformat"
        case .science: "flask"
        case .humanities: "book"
        case .technology: "desktopcomputer"
        case .other: "ellipsis.circle"
        }
    }
}
