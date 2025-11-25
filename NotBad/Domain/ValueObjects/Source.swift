//
//  Source.swift
//  NotBad
//
//  题目来源值对象 - K12完整覆盖
//

import SwiftUI

/// 来源分类
enum SourceCategory: String, CaseIterable, Codable {
    case official = "官方"     // 课本、真题
    case school = "学校"       // 试卷、作业、模拟考
    case extra = "课外"        // 练习册、辅导班、竞赛
    case other = "其他"        // 网络、自测、其他
    
    var displayName: String { rawValue }
    
    /// 图标
    var icon: String {
        switch self {
        case .official: return "building.columns"
        case .school: return "graduationcap"
        case .extra: return "books.vertical"
        case .other: return "ellipsis.circle"
        }
    }
    
    /// 颜色
    var color: Color {
        switch self {
        case .official: return .red
        case .school: return .blue
        case .extra: return .orange
        case .other: return .gray
        }
    }
}

/// 题目来源
enum Source: String, CaseIterable, Codable {
    // 官方
    case textbook = "课本"
    case pastExam = "历年真题"
    
    // 学校
    case exam = "考试"
    case mock = "模拟考"
    case homework = "作业"
    
    // 课外
    case workbook = "练习册"
    case tutor = "辅导班"
    case competition = "竞赛"
    
    // 其他
    case online = "网络"
    case selfTest = "自测"
    case other = "其他"
    
    /// 显示名称
    var displayName: String { rawValue }
    
    /// 简短标签
    var shortLabel: String {
        switch self {
        case .textbook: return "课本"
        case .pastExam: return "真题"
        case .exam: return "考试"
        case .mock: return "模考"
        case .homework: return "作业"
        case .workbook: return "练习"
        case .tutor: return "辅导"
        case .competition: return "竞赛"
        case .online: return "网络"
        case .selfTest: return "自测"
        case .other: return "其他"
        }
    }
    
    /// 来源分类
    var category: SourceCategory {
        switch self {
        case .textbook, .pastExam:
            return .official
        case .exam, .mock, .homework:
            return .school
        case .workbook, .tutor, .competition:
            return .extra
        case .online, .selfTest, .other:
            return .other
        }
    }
    
    /// 图标
    var icon: String {
        switch self {
        case .textbook: return "book.closed"
        case .pastExam: return "doc.badge.clock"
        case .exam: return "doc.text.fill"
        case .mock: return "doc.text"
        case .homework: return "pencil.and.list.clipboard"
        case .workbook: return "book"
        case .tutor: return "person.2"
        case .competition: return "trophy"
        case .online: return "globe"
        case .selfTest: return "person.crop.circle.badge.questionmark"
        case .other: return "ellipsis.circle"
        }
    }
    
    /// 颜色
    var color: Color {
        switch self {
        case .textbook: return .blue
        case .pastExam: return .red
        case .exam: return .red
        case .mock: return .orange
        case .homework: return .green
        case .workbook: return .cyan
        case .tutor: return .purple
        case .competition: return .yellow
        case .online: return .indigo
        case .selfTest: return .mint
        case .other: return .gray
        }
    }
    
    /// 重要程度（1-5，越高越重要）
    var importance: Int {
        switch self {
        case .pastExam: return 5      // 历年真题最重要
        case .exam: return 5          // 正式考试
        case .competition: return 4   // 竞赛题有拔高价值
        case .mock: return 4          // 模拟考接近真实
        case .textbook: return 4      // 课本是基础
        case .tutor: return 3         // 辅导班针对性强
        case .workbook: return 3      // 练习册有系统性
        case .homework: return 2      // 日常作业
        case .online: return 2        // 网络资源质量参差
        case .selfTest: return 1      // 自测
        case .other: return 1         // 其他
        }
    }
    
    /// 是否为高权威来源
    var isAuthoritative: Bool {
        category == .official || self == .exam
    }
    
    /// 是否为考试相关
    var isExamRelated: Bool {
        [.pastExam, .exam, .mock].contains(self)
    }
}

// MARK: - 统计辅助

extension Source {
    /// 获取某分类下的所有来源
    static func sources(in category: SourceCategory) -> [Source] {
        allCases.filter { $0.category == category }
    }
    
    /// 高重要性来源（重要程度 >= 4）
    static var highImportanceSources: [Source] {
        allCases.filter { $0.importance >= 4 }
    }
}
