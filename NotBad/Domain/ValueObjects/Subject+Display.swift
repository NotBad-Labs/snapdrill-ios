//
//  Subject+Display.swift
//  NotBad
//
//  学科显示属性扩展
//

import Foundation

// MARK: - Display Properties

extension Subject {
    /// 显示名称
    nonisolated var displayName: String {
        String(localized: localizationKey)
    }

    /// 本地化键值
    private var localizationKey: String.LocalizationValue {
        switch self {
        case .chinese: "subject_chinese"
        case .english: "subject_english"
        case .math: "subject_math"
        case .physics: "subject_physics"
        case .chemistry: "subject_chemistry"
        case .biology: "subject_biology"
        case .science: "subject_science"
        case .history: "subject_history"
        case .geography: "subject_geography"
        case .politics: "subject_politics"
        case .ethics: "subject_ethics"
        case .informationTech: "subject_information_tech"
        case .generalTech: "subject_general_tech"
        case .other: "subject_other"
        }
    }

    /// 简短标签（单字）
    nonisolated var shortLabel: String {
        String(localized: shortLabelKey)
    }

    /// 简短标签本地化键值
    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .chinese: "subject_chinese_short"
        case .english: "subject_english_short"
        case .math: "subject_math_short"
        case .physics: "subject_physics_short"
        case .chemistry: "subject_chemistry_short"
        case .biology: "subject_biology_short"
        case .science: "subject_science_short"
        case .history: "subject_history_short"
        case .geography: "subject_geography_short"
        case .politics: "subject_politics_short"
        case .ethics: "subject_ethics_short"
        case .informationTech: "subject_information_tech_short"
        case .generalTech: "subject_general_tech_short"
        case .other: "subject_other_short"
        }
    }

    /// SF Symbol 图标名称
    nonisolated var icon: String {
        switch self {
        case .chinese: "character.book.closed"
        case .english: "abc"
        case .math: "function"
        case .physics: "atom"
        case .chemistry: "testtube.2"
        case .biology: "leaf"
        case .science: "sparkles"
        case .history: "clock.arrow.circlepath"
        case .geography: "globe.asia.australia"
        case .politics: "building.columns"
        case .ethics: "heart.text.square"
        case .informationTech: "desktopcomputer"
        case .generalTech: "wrench.and.screwdriver"
        case .other: "ellipsis.circle"
        }
    }
}

// MARK: - CustomStringConvertible

extension Subject: CustomStringConvertible {
    nonisolated var description: String { displayName }
}
