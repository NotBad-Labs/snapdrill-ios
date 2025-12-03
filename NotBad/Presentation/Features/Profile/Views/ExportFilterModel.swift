//
//  ExportFilterModel.swift
//  NotBad
//
//  导出筛选模型 - 基于东亚/中国学生实际使用场景设计
//
//  ## 设计理念
//
//  中国学生的错题导出场景分析：
//
//  1. **考前复习** - 最常见场景
//     - 期中/期末考试前，按科目导出未掌握的题目
//     - 月考前，导出本月积累的错题
//     - 重点突破难题或薄弱知识点
//
//  2. **周末巩固** - 高频场景
//     - 每周末导出本周错题，打印后练习
//     - 家长检查孩子学习情况
//
//  3. **专项训练** - 针对性学习
//     - 针对某一科目的专项突破
//     - 针对某类错误类型（计算失误、概念不清等）
//     - 按难度阶梯式练习
//
//  4. **学期总结** - 周期性场景
//     - 学期末整理错题本
//     - 寒暑假复习资料准备
//

import SwiftUI

// MARK: - Export Filter Configuration

/// 导出筛选配置
///
/// 综合考虑时间、学科、难度、掌握程度等多维度筛选条件
@Observable
final class ExportFilterConfig {
    
    // MARK: - 时间维度
    
    /// 时间范围类型
    var dateRangeType: ExportDateRangeType = .all
    
    /// 自定义开始日期
    var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    
    /// 自定义结束日期
    var customEndDate: Date = Date()
    
    // MARK: - 学科维度
    
    /// 是否启用学科筛选
    var filterBySubject: Bool = false
    
    /// 选中的学科（多选）
    var selectedSubjects: Set<Subject> = []
    
    // MARK: - 难度维度
    
    /// 是否启用难度筛选
    var filterByDifficulty: Bool = false
    
    /// 最小难度（1-5）
    var minDifficulty: Int = 1
    
    /// 最大难度（1-5）
    var maxDifficulty: Int = 5
    
    // MARK: - 掌握程度维度（最重要！）
    
    /// 是否启用掌握程度筛选
    var filterByMastery: Bool = false
    
    /// 掌握程度筛选类型
    var masteryFilterType: MasteryFilterType = .notMastered
    
    // MARK: - 错误类型维度
    
    /// 是否启用错误类型筛选
    var filterByErrorType: Bool = false
    
    /// 选中的错误类型（多选）
    var selectedErrorTypes: Set<ErrorType> = []
    
    // MARK: - 来源维度
    
    /// 是否启用来源筛选
    var filterBySource: Bool = false
    
    /// 选中的来源（多选）
    var selectedSources: Set<Source> = []
    
    // MARK: - 快捷预设
    
    /// 应用预设配置
    func applyPreset(_ preset: ExportPreset) {
        // 重置所有筛选
        resetAll()
        
        switch preset {
        case .all:
            break // 默认全部
            
        case .thisWeekReview:
            // 本周复习：本周 + 未掌握
            dateRangeType = .thisWeek
            filterByMastery = true
            masteryFilterType = .notMastered
            
        case .examPrep:
            // 考前冲刺：未掌握 + 中高难度
            filterByMastery = true
            masteryFilterType = .notMastered
            filterByDifficulty = true
            minDifficulty = 3
            maxDifficulty = 5
            
        case .monthlyReview:
            // 月度复习：本月全部
            dateRangeType = .thisMonth
            
        case .weakPoints:
            // 薄弱点专项：掌握度<50%
            filterByMastery = true
            masteryFilterType = .veryWeak
            
        case .easyFirst:
            // 先易后难：低难度 + 未掌握
            filterByMastery = true
            masteryFilterType = .notMastered
            filterByDifficulty = true
            minDifficulty = 1
            maxDifficulty = 2
            
        case .hardChallenge:
            // 难题挑战：高难度
            filterByDifficulty = true
            minDifficulty = 4
            maxDifficulty = 5
        }
    }
    
    /// 重置所有筛选条件
    func resetAll() {
        dateRangeType = .all
        customStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        customEndDate = Date()
        filterBySubject = false
        selectedSubjects = []
        filterByDifficulty = false
        minDifficulty = 1
        maxDifficulty = 5
        filterByMastery = false
        masteryFilterType = .notMastered
        filterByErrorType = false
        selectedErrorTypes = []
        filterBySource = false
        selectedSources = []
    }
    
    // MARK: - 筛选逻辑
    
    /// 筛选错题
    func filter(_ items: [ReviewItem]) -> [ReviewItem] {
        items.filter { item in
            // 时间筛选
            if !passesDateFilter(item) { return false }
            
            // 学科筛选
            if filterBySubject && !selectedSubjects.isEmpty {
                if !selectedSubjects.contains(item.subject) { return false }
            }
            
            // 难度筛选
            if filterByDifficulty {
                let difficulty = item.difficulty.stars  // 1-5
                if difficulty < minDifficulty || difficulty > maxDifficulty { return false }
            }
            
            // 掌握程度筛选
            if filterByMastery {
                if !passesMasteryFilter(item) { return false }
            }
            
            // 错误类型筛选
            if filterByErrorType && !selectedErrorTypes.isEmpty {
                if !selectedErrorTypes.contains(item.errorType) { return false }
            }
            
            // 来源筛选
            if filterBySource && !selectedSources.isEmpty {
                if !selectedSources.contains(item.source) { return false }
            }
            
            return true
        }
    }
    
    /// 检查是否通过时间筛选
    private func passesDateFilter(_ item: ReviewItem) -> Bool {
        let (startDate, endDate) = dateRangeType.dateRange(
            customStart: customStartDate,
            customEnd: customEndDate
        )
        
        if let start = startDate, item.createdAt < start { return false }
        if let end = endDate, item.createdAt > end { return false }
        
        return true
    }
    
    /// 检查是否通过掌握程度筛选
    private func passesMasteryFilter(_ item: ReviewItem) -> Bool {
        let mastery = item.masteryLevel
        
        switch masteryFilterType {
        case .notMastered:
            return mastery < 80 // 未掌握：<80%
        case .veryWeak:
            return mastery < 50 // 非常薄弱：<50%
        case .needsReview:
            return mastery >= 50 && mastery < 80 // 需要复习：50-80%
        case .mastered:
            return mastery >= 80 // 已掌握：≥80%
        case .customRange(let min, let max):
            return mastery >= min && mastery <= max
        }
    }
    
    // MARK: - 描述
    
    /// 获取筛选条件的描述文本
    var filterDescription: String {
        var parts: [String] = []
        
        // 时间
        if dateRangeType != .all {
            parts.append(dateRangeType.shortDescription)
        }
        
        // 学科
        if filterBySubject && !selectedSubjects.isEmpty {
            if selectedSubjects.count <= 2 {
                parts.append(selectedSubjects.map { $0.displayName }.joined(separator: "、"))
            } else {
                parts.append("\(selectedSubjects.count)个学科")
            }
        }
        
        // 难度
        if filterByDifficulty {
            if minDifficulty == maxDifficulty {
                parts.append("\(minDifficulty)星难度")
            } else {
                parts.append("\(minDifficulty)-\(maxDifficulty)星")
            }
        }
        
        // 掌握程度
        if filterByMastery {
            parts.append(masteryFilterType.shortDescription)
        }
        
        // 错误类型
        if filterByErrorType && !selectedErrorTypes.isEmpty {
            if selectedErrorTypes.count == 1 {
                parts.append(selectedErrorTypes.first!.displayName)
            } else {
                parts.append("\(selectedErrorTypes.count)种错误类型")
            }
        }
        
        return parts.isEmpty ? "全部错题" : parts.joined(separator: " · ")
    }
    
    /// 是否有任何筛选条件
    var hasAnyFilter: Bool {
        dateRangeType != .all ||
        (filterBySubject && !selectedSubjects.isEmpty) ||
        filterByDifficulty ||
        filterByMastery ||
        (filterByErrorType && !selectedErrorTypes.isEmpty) ||
        (filterBySource && !selectedSources.isEmpty)
    }
}

// MARK: - Export Date Range Type

/// 导出时间范围类型
enum ExportDateRangeType: String, CaseIterable, Identifiable {
    case all = "all"
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case lastMonth = "last_month"
    case thisYear = "this_year"
    case custom = "custom"
    
    var id: String { rawValue }
    
    var displayName: LocalizedStringKey {
        switch self {
        case .all: return "export_range_all"
        case .thisWeek: return "export_range_this_week"
        case .thisMonth: return "export_range_this_month"
        case .lastMonth: return "export_range_last_month"
        case .thisYear: return "export_range_this_year"
        case .custom: return "export_range_custom"
        }
    }
    
    var shortDescription: String {
        switch self {
        case .all: return "全部"
        case .thisWeek: return "本周"
        case .thisMonth: return "本月"
        case .lastMonth: return "上月"
        case .thisYear: return "今年"
        case .custom: return "自定义"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "infinity"
        case .thisWeek: return "calendar.badge.clock"
        case .thisMonth: return "calendar"
        case .lastMonth: return "calendar.badge.minus"
        case .thisYear: return "calendar.circle"
        case .custom: return "calendar.badge.plus"
        }
    }
    
    /// 获取日期范围
    func dateRange(customStart: Date? = nil, customEnd: Date? = nil) -> (start: Date?, end: Date?) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .all:
            return (nil, nil)
        case .thisWeek:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start
            return (start, now)
        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: now)?.start
            return (start, now)
        case .lastMonth:
            guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now),
                  let interval = calendar.dateInterval(of: .month, for: lastMonth) else {
                return (nil, nil)
            }
            return (interval.start, interval.end)
        case .thisYear:
            let start = calendar.dateInterval(of: .year, for: now)?.start
            return (start, now)
        case .custom:
            return (customStart, customEnd)
        }
    }
}

// MARK: - Mastery Filter Type

/// 掌握程度筛选类型
enum MasteryFilterType: Equatable, Hashable {
    case notMastered      // 未掌握 <80%
    case veryWeak         // 非常薄弱 <50%
    case needsReview      // 需要复习 50-80%
    case mastered         // 已掌握 ≥80%
    case customRange(min: Int, max: Int)  // 自定义范围
    
    var displayName: LocalizedStringKey {
        switch self {
        case .notMastered: return "export_mastery_not_mastered"
        case .veryWeak: return "export_mastery_very_weak"
        case .needsReview: return "export_mastery_needs_review"
        case .mastered: return "export_mastery_mastered"
        case .customRange: return "export_mastery_custom"
        }
    }
    
    var shortDescription: String {
        switch self {
        case .notMastered: return "未掌握"
        case .veryWeak: return "薄弱"
        case .needsReview: return "需复习"
        case .mastered: return "已掌握"
        case .customRange(let min, let max): return "\(min)-\(max)%"
        }
    }
    
    var description: LocalizedStringKey {
        switch self {
        case .notMastered: return "export_mastery_not_mastered_desc"
        case .veryWeak: return "export_mastery_very_weak_desc"
        case .needsReview: return "export_mastery_needs_review_desc"
        case .mastered: return "export_mastery_mastered_desc"
        case .customRange: return "export_mastery_custom_desc"
        }
    }
    
    var icon: String {
        switch self {
        case .notMastered: return "exclamationmark.triangle.fill"
        case .veryWeak: return "xmark.circle.fill"
        case .needsReview: return "arrow.clockwise.circle.fill"
        case .mastered: return "checkmark.circle.fill"
        case .customRange: return "slider.horizontal.3"
        }
    }
    
    var color: Color {
        switch self {
        case .notMastered: return .orange
        case .veryWeak: return .red
        case .needsReview: return .yellow
        case .mastered: return .green
        case .customRange: return .blue
        }
    }
    
    /// 预设选项（不包含自定义）
    static var presets: [MasteryFilterType] {
        [.notMastered, .veryWeak, .needsReview, .mastered]
    }
}

// MARK: - Export Preset

/// 导出预设配置
///
/// 基于中国学生常见使用场景设计的快捷预设
enum ExportPreset: String, CaseIterable, Identifiable {
    case all = "all"
    case thisWeekReview = "this_week_review"
    case examPrep = "exam_prep"
    case monthlyReview = "monthly_review"
    case weakPoints = "weak_points"
    case easyFirst = "easy_first"
    case hardChallenge = "hard_challenge"
    
    var id: String { rawValue }
    
    var displayName: LocalizedStringKey {
        switch self {
        case .all: return "export_preset_all"
        case .thisWeekReview: return "export_preset_this_week"
        case .examPrep: return "export_preset_exam_prep"
        case .monthlyReview: return "export_preset_monthly"
        case .weakPoints: return "export_preset_weak_points"
        case .easyFirst: return "export_preset_easy_first"
        case .hardChallenge: return "export_preset_hard_challenge"
        }
    }
    
    var description: LocalizedStringKey {
        switch self {
        case .all: return "export_preset_all_desc"
        case .thisWeekReview: return "export_preset_this_week_desc"
        case .examPrep: return "export_preset_exam_prep_desc"
        case .monthlyReview: return "export_preset_monthly_desc"
        case .weakPoints: return "export_preset_weak_points_desc"
        case .easyFirst: return "export_preset_easy_first_desc"
        case .hardChallenge: return "export_preset_hard_challenge_desc"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "tray.full.fill"
        case .thisWeekReview: return "calendar.badge.clock"
        case .examPrep: return "graduationcap.fill"
        case .monthlyReview: return "calendar"
        case .weakPoints: return "exclamationmark.triangle.fill"
        case .easyFirst: return "leaf.fill"
        case .hardChallenge: return "flame.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .secondary
        case .thisWeekReview: return .blue
        case .examPrep: return .purple
        case .monthlyReview: return .green
        case .weakPoints: return .red
        case .easyFirst: return .mint
        case .hardChallenge: return .orange
        }
    }
}
