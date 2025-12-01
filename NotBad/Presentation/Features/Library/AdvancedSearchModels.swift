//
//  AdvancedSearchModels.swift
//  NotBad
//
//  Created by LIAOYIMING on 2025/6/5.
//

import SwiftUI

// MARK: - SearchCriteria

/// 搜索条件模型
struct SearchCriteria: Equatable, Sendable {
    /// 关键词
    var keyword: String = ""

    /// 选中的学科
    var subjects: Set<Subject> = []

    /// 选中的难度
    var difficulties: Set<Difficulty> = []

    /// 选中的掌握程度
    var masteryLevels: Set<MasteryLevel> = []

    /// 日期范围
    var dateRange: DateRangeOption = .all

    /// 仅显示待复习
    var needsReviewOnly: Bool = false

    /// 仅显示已逾期
    var overdueOnly: Bool = false

    /// 仅显示有图片
    var hasImageOnly: Bool = false

    /// 仅显示有笔记
    var hasNoteOnly: Bool = false

    /// 是否有活动筛选条件
    var hasActiveFilters: Bool {
        !keyword.isEmpty ||
        !subjects.isEmpty ||
        !difficulties.isEmpty ||
        !masteryLevels.isEmpty ||
        dateRange != .all ||
        needsReviewOnly ||
        overdueOnly ||
        hasImageOnly ||
        hasNoteOnly
    }

    /// 活动筛选条件数量
    var activeFilterCount: Int {
        var count = 0
        if !keyword.isEmpty { count += 1 }
        if !subjects.isEmpty { count += 1 }
        if !difficulties.isEmpty { count += 1 }
        if !masteryLevels.isEmpty { count += 1 }
        if dateRange != .all { count += 1 }
        if needsReviewOnly { count += 1 }
        if overdueOnly { count += 1 }
        if hasImageOnly { count += 1 }
        if hasNoteOnly { count += 1 }
        return count
    }
}

// MARK: - DateRangeOption

/// 日期范围选项
enum DateRangeOption: String, CaseIterable, Sendable {
    case all = "全部时间"
    case today = "今天"
    case thisWeek = "本周"
    case thisMonth = "本月"
    case lastMonth = "上月"
    case thisYear = "今年"
    case custom = "自定义"

    /// 获取日期范围
    var dateRange: ClosedRange<Date>? {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .all:
            return nil
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return start...end
        case .thisWeek:
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
            return start...end
        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return start...end
        case .lastMonth:
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let start = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)!
            return start...thisMonthStart
        case .thisYear:
            let start = calendar.date(from: calendar.dateComponents([.year], from: now))!
            let end = calendar.date(byAdding: .year, value: 1, to: start)!
            return start...end
        case .custom:
            return nil
        }
    }
}

// MARK: - SearchCriteria Extension for Filtering

extension SearchCriteria {

    /// 应用筛选条件到错题列表
    func filter(_ items: [ReviewItem]) -> [ReviewItem] {
        items.filter { item in
            // 关键词筛选
            if !keyword.isEmpty {
                let lowercasedKeyword = keyword.lowercased()
                let matchesKeyword = item.title.lowercased().contains(lowercasedKeyword) ||
                    item.note.lowercased().contains(lowercasedKeyword) ||
                    item.knowledgePoints.matches(keyword)
                if !matchesKeyword { return false }
            }

            // 学科筛选
            if !subjects.isEmpty && !subjects.contains(item.subject) {
                return false
            }

            // 难度筛选
            if !difficulties.isEmpty && !difficulties.contains(item.difficulty) {
                return false
            }

            // 掌握程度筛选
            if !masteryLevels.isEmpty && !masteryLevels.contains(item.mastery) {
                return false
            }

            // 日期范围筛选
            if let range = dateRange.dateRange {
                if !range.contains(item.createdAt) {
                    return false
                }
            }

            // 待复习筛选
            if needsReviewOnly && !item.needsReview {
                return false
            }

            // 逾期筛选
            if overdueOnly && !item.isOverdue {
                return false
            }

            // 有图片筛选
            if hasImageOnly && !item.hasImage {
                return false
            }

            // 有笔记筛选
            if hasNoteOnly && !item.hasNote {
                return false
            }

            return true
        }
    }
}
