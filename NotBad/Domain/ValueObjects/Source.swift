//
//  Source.swift
//  NotBad
//
//  题目来源值对象
//

import SwiftUI

// MARK: - Source

/// 题目来源
///
/// K12 教育中常见的题目来源，按分类组织。
///
/// ## 来源分布
///
/// ### 官方来源（2种）
/// - 课本、历年真题
///
/// ### 学校来源（3种）
/// - 考试、模拟考、作业
///
/// ### 课外来源（3种）
/// - 练习册、辅导班、竞赛
///
/// ### 其他来源（3种）
/// - 网络、自测、其他
///
/// ## 使用示例
///
/// ```swift
/// let source = Source.pastExam
/// print(source.displayName)     // "历年真题"
/// print(source.importance)      // 5
/// print(source.isAuthoritative) // true
///
/// // 获取高重要性来源
/// let important = Source.highImportanceSources
/// ```
enum Source: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {

    // MARK: - Official Sources (官方)

    /// 课本
    ///
    /// 教材教辅，官方权威。
    case textbook = "课本"

    /// 历年真题
    ///
    /// 中考、高考等正式考试真题。
    case pastExam = "历年真题"

    // MARK: - School Sources (学校)

    /// 考试
    ///
    /// 校内正式考试（期中、期末等）。
    case exam = "考试"

    /// 模拟考
    ///
    /// 模拟考试，仿真度较高。
    case mock = "模拟考"

    /// 作业
    ///
    /// 日常作业、课后练习。
    case homework = "作业"

    // MARK: - Extra Sources (课外)

    /// 练习册
    ///
    /// 市售练习册、习题集。
    case workbook = "练习册"

    /// 辅导班
    ///
    /// 课外辅导机构资料。
    case tutor = "辅导班"

    /// 竞赛
    ///
    /// 学科竞赛、奥赛等。
    case competition = "竞赛"

    // MARK: - Other Sources (其他)

    /// 网络
    ///
    /// 网络资源、在线题库。
    case online = "网络"

    /// 自测
    ///
    /// 自主测试、自我检验。
    case selfTest = "自测"

    /// 其他
    ///
    /// 其他来源。
    case other = "其他"

    // MARK: - Identifiable

    /// 唯一标识符
    nonisolated var id: String { rawValue }
}

// MARK: - Source Display Properties

extension Source {

    /// 显示名称
    nonisolated var displayName: String {
        String(localized: localizationKey)
    }

    /// 本地化键值
    private var localizationKey: String.LocalizationValue {
        switch self {
        case .textbook: "source_textbook"
        case .pastExam: "source_past_exam"
        case .exam: "source_exam"
        case .mock: "source_mock"
        case .homework: "source_homework"
        case .workbook: "source_workbook"
        case .tutor: "source_tutor"
        case .competition: "source_competition"
        case .online: "source_online"
        case .selfTest: "source_self_test"
        case .other: "source_other"
        }
    }

    /// 简短标签
    ///
    /// 用于空间有限的 UI 展示。
    nonisolated var shortLabel: String {
        String(localized: shortLabelKey)
    }

    /// 简短标签本地化键值
    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .textbook: "source_textbook_short"
        case .pastExam: "source_past_exam_short"
        case .exam: "source_exam_short"
        case .mock: "source_mock_short"
        case .homework: "source_homework_short"
        case .workbook: "source_workbook_short"
        case .tutor: "source_tutor_short"
        case .competition: "source_competition_short"
        case .online: "source_online_short"
        case .selfTest: "source_self_test_short"
        case .other: "source_other_short"
        }
    }

    /// SF Symbol 图标名称
    nonisolated var icon: String {
        switch self {
        case .textbook: "book.closed"
        case .pastExam: "doc.badge.clock"
        case .exam: "doc.text.fill"
        case .mock: "doc.text"
        case .homework: "pencil.and.list.clipboard"
        case .workbook: "book"
        case .tutor: "person.2"
        case .competition: "trophy"
        case .online: "globe"
        case .selfTest: "person.crop.circle.badge.questionmark"
        case .other: "ellipsis.circle"
        }
    }

    /// 主题颜色
    nonisolated var color: Color {
        switch self {
        case .textbook: .blue
        case .pastExam: .red
        case .exam: .red
        case .mock: .orange
        case .homework: .green
        case .workbook: .cyan
        case .tutor: .purple
        case .competition: .yellow
        case .online: .indigo
        case .selfTest: .mint
        case .other: .gray
        }
    }
}

// MARK: - Source Category

extension Source {

    /// 来源分类
    nonisolated var category: SourceCategory {
        switch self {
        case .textbook, .pastExam:
            .official
        case .exam, .mock, .homework:
            .school
        case .workbook, .tutor, .competition:
            .extra
        case .online, .selfTest, .other:
            .other
        }
    }

    /// 是否为官方来源
    nonisolated var isOfficial: Bool { category == .official }

    /// 是否为学校来源
    nonisolated var isSchool: Bool { category == .school }

    /// 是否为课外来源
    nonisolated var isExtra: Bool { category == .extra }
}

// MARK: - Source Importance

extension Source {

    /// 重要程度
    ///
    /// 1-5 分，数字越大越重要：
    /// - 5：历年真题、正式考试
    /// - 4：竞赛、模拟考、课本
    /// - 3：辅导班、练习册
    /// - 2：作业、网络
    /// - 1：自测、其他
    nonisolated var importance: Int {
        switch self {
        case .pastExam: 5
        case .exam: 5
        case .textbook: 5
        case .competition: 4
        case .mock: 4
        case .tutor: 3
        case .workbook: 3
        case .homework: 3
        case .online: 2
        case .selfTest: 1
        case .other: 1
        }
    }

    /// 重要程度描述
    nonisolated var importanceDescription: String {
        switch importance {
        case 5: "非常重要"
        case 4: "重要"
        case 3: "一般"
        case 2: "次要"
        default: "低"
        }
    }

    /// 是否为高重要性来源
    ///
    /// 重要程度 >= 4 视为高重要性。
    nonisolated var isHighImportance: Bool { importance >= 4 }

    /// 是否为中等重要性来源
    ///
    /// 重要程度 >= 3 且 < 4。
    nonisolated var isMediumImportance: Bool { importance == 3 }

    /// 是否为低重要性来源
    ///
    /// 重要程度 < 3。
    nonisolated var isLowImportance: Bool { importance < 3 }
}

// MARK: - Source Authority & Exam

extension Source {

    /// 是否为高权威来源
    ///
    /// 官方来源或正式考试视为高权威。
    nonisolated var isAuthoritative: Bool {
        category == .official || self == .exam
    }

    /// 是否为考试相关
    ///
    /// 包括历年真题、正式考试、模拟考。
    nonisolated var isExamRelated: Bool {
        [.pastExam, .exam, .mock].contains(self)
    }

    /// 是否为提升类来源
    ///
    /// 竞赛、辅导班等提升类来源。
    nonisolated var isAdvanced: Bool {
        [.competition, .tutor].contains(self)
    }
}

// MARK: - Source Static Collections

extension Source {

    /// 所有官方来源
    nonisolated static var officialSources: [Source] {
        [.textbook, .pastExam]
    }

    /// 所有学校来源
    nonisolated static var schoolSources: [Source] {
        [.exam, .mock, .homework]
    }

    /// 所有课外来源
    nonisolated static var extraSources: [Source] {
        [.workbook, .tutor, .competition]
    }

    /// 所有考试相关来源
    nonisolated static var examRelatedSources: [Source] {
        [.pastExam, .exam, .mock]
    }

    /// 高重要性来源
    ///
    /// 重要程度 >= 4 的所有来源。
    nonisolated static var highImportanceSources: [Source] {
        allCases.filter { $0.importance >= 4 }
    }

    /// 高权威来源
    nonisolated static var authoritativeSources: [Source] {
        allCases.filter { $0.isAuthoritative }
    }
}

// MARK: - Source Query Methods

extension Source {

    /// 获取某分类下的所有来源
    ///
    /// - Parameter category: 来源分类
    /// - Returns: 该分类下的所有来源
    nonisolated static func sources(in category: SourceCategory) -> [Source] {
        allCases.filter { $0.category == category }
    }

    /// 获取指定重要程度的所有来源
    ///
    /// - Parameter level: 重要程度（1-5）
    /// - Returns: 该重要程度的所有来源
    nonisolated static func sources(withImportance level: Int) -> [Source] {
        allCases.filter { $0.importance == level }
    }

    /// 获取重要程度大于等于指定值的所有来源
    ///
    /// - Parameter minLevel: 最低重要程度
    /// - Returns: 符合条件的所有来源
    nonisolated static func sources(withMinImportance minLevel: Int) -> [Source] {
        allCases.filter { $0.importance >= minLevel }
    }

    /// 按重要程度排序的所有来源
    ///
    /// 从高到低排序。
    nonisolated static var sortedByImportance: [Source] {
        allCases.sorted { $0.importance > $1.importance }
    }
}
