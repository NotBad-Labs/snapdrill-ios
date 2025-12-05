//
//  SortOption.swift
//  NotBad
//
//  错题列表排序选项
//

import Foundation

/// 排序选项
enum SortOption: String, Sendable, CaseIterable, Identifiable {
    case createdAtDesc
    case createdAtAsc
    case titleAsc
    case masteryAsc
    case masteryDesc
    case difficultyDesc
    case reviewDateAsc

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .createdAtDesc: String(localized: "sort_newest")
        case .createdAtAsc: String(localized: "sort_oldest")
        case .titleAsc: String(localized: "sort_title")
        case .masteryAsc: String(localized: "sort_mastery_asc")
        case .masteryDesc: String(localized: "sort_mastery_desc")
        case .difficultyDesc: String(localized: "sort_difficulty")
        case .reviewDateAsc: String(localized: "sort_review_needed")
        }
    }
    
    /// 简短名称（用于筛选栏按钮显示）
    var shortName: String {
        switch self {
        case .createdAtDesc: String(localized: "sort_short_newest")
        case .createdAtAsc: String(localized: "sort_short_oldest")
        case .titleAsc: String(localized: "sort_short_title")
        case .masteryAsc: String(localized: "sort_short_mastery_asc")
        case .masteryDesc: String(localized: "sort_short_mastery_desc")
        case .difficultyDesc: String(localized: "sort_short_difficulty")
        case .reviewDateAsc: String(localized: "sort_short_review")
        }
    }

    var icon: String {
        switch self {
        case .createdAtDesc: "arrow.down.circle"
        case .createdAtAsc: "arrow.up.circle"
        case .titleAsc: "textformat.abc"
        case .masteryAsc, .masteryDesc: "chart.bar"
        case .difficultyDesc: "flame"
        case .reviewDateAsc: "clock"
        }
    }
}

// MARK: - FilteredStatistics

/// 筛选结果统计
struct FilteredStatistics: Sendable, Equatable {
    let totalCount: Int
    let filteredCount: Int
    let masteredCount: Int
    let pendingReviewCount: Int

    /// 筛选率描述
    var filterDescription: String {
        if filteredCount == totalCount {
            return String(format: String(localized: "filter_total_count"), totalCount)
        } else {
            return String(format: String(localized: "filter_filtered_count"), filteredCount, totalCount)
        }
    }
}
