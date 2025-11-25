//
//  Subject.swift
//  NotBad
//
//  学科值对象 - K12完整覆盖
//

import SwiftUI

/// 学科分类
enum SubjectCategory: String, CaseIterable, Codable {
    case language = "语言"    // 语文、英语
    case science = "理科"     // 数学、物理、化学、生物、科学
    case humanities = "人文"  // 历史、地理、政治/道法
    case technology = "技术"  // 信息技术、通用技术
    case other = "其他"
    
    var displayName: String { rawValue }
    
    /// 图标
    var icon: String {
        switch self {
        case .language: return "textformat"
        case .science: return "flask"
        case .humanities: return "book"
        case .technology: return "desktopcomputer"
        case .other: return "ellipsis.circle"
        }
    }
    
    /// 颜色
    var color: Color {
        switch self {
        case .language: return .red
        case .science: return .blue
        case .humanities: return .orange
        case .technology: return .purple
        case .other: return .gray
        }
    }
}

/// 学科（K12全覆盖）
enum Subject: String, CaseIterable, Codable {
    // 语言类
    case chinese = "语文"
    case english = "英语"
    
    // 理科类
    case math = "数学"
    case physics = "物理"
    case chemistry = "化学"
    case biology = "生物"
    case science = "科学"           // 小学、初中科学课
    
    // 人文类
    case history = "历史"
    case geography = "地理"
    case politics = "政治"
    case ethics = "道德与法治"       // 小学、初中
    
    // 技术类
    case informationTech = "信息技术"
    case generalTech = "通用技术"    // 高中
    
    // 其他
    case other = "其他"
    
    /// 显示名称
    var displayName: String { rawValue }
    
    /// 简短标签
    var shortLabel: String {
        switch self {
        case .chinese: return "语"
        case .english: return "英"
        case .math: return "数"
        case .physics: return "物"
        case .chemistry: return "化"
        case .biology: return "生"
        case .science: return "科"
        case .history: return "史"
        case .geography: return "地"
        case .politics: return "政"
        case .ethics: return "道"
        case .informationTech: return "信"
        case .generalTech: return "技"
        case .other: return "他"
        }
    }
    
    /// 学科分类
    var category: SubjectCategory {
        switch self {
        case .chinese, .english:
            return .language
        case .math, .physics, .chemistry, .biology, .science:
            return .science
        case .history, .geography, .politics, .ethics:
            return .humanities
        case .informationTech, .generalTech:
            return .technology
        case .other:
            return .other
        }
    }
    
    /// 适用学段
    var applicableStages: [GradeStage] {
        switch self {
        // 全学段
        case .chinese, .math, .english:
            return [.primary, .junior, .senior]
        // 小学+初中
        case .science, .ethics:
            return [.primary, .junior]
        // 初中+高中
        case .physics, .chemistry, .history, .geography, .politics:
            return [.junior, .senior]
        // 仅高中
        case .biology, .generalTech:
            return [.senior]
        // 全学段（信息技术）
        case .informationTech:
            return [.primary, .junior, .senior]
        case .other:
            return [.primary, .junior, .senior]
        }
    }
    
    /// 是否适用于指定学段
    func isApplicable(for stage: GradeStage) -> Bool {
        applicableStages.contains(stage)
    }
    
    /// 获取指定学段的学科列表
    static func subjects(for stage: GradeStage) -> [Subject] {
        allCases.filter { $0.isApplicable(for: stage) }
    }
    
    /// 图标
    var icon: String {
        switch self {
        case .chinese: return "character.book.closed"
        case .english: return "abc"
        case .math: return "function"
        case .physics: return "atom"
        case .chemistry: return "testtube.2"
        case .biology: return "leaf"
        case .science: return "sparkles"
        case .history: return "clock.arrow.circlepath"
        case .geography: return "globe.asia.australia"
        case .politics: return "building.columns"
        case .ethics: return "heart.text.square"
        case .informationTech: return "desktopcomputer"
        case .generalTech: return "wrench.and.screwdriver"
        case .other: return "ellipsis.circle"
        }
    }
    
    /// 颜色
    var color: Color {
        switch self {
        case .chinese: return .red
        case .english: return .purple
        case .math: return .blue
        case .physics: return .orange
        case .chemistry: return .green
        case .biology: return .mint
        case .science: return .cyan
        case .history: return .brown
        case .geography: return .teal
        case .politics: return .indigo
        case .ethics: return .pink
        case .informationTech: return .purple
        case .generalTech: return .gray
        case .other: return .secondary
        }
    }
    
    /// 主要学科（语数英）
    static var coreSubjects: [Subject] {
        [.chinese, .math, .english]
    }
    
    /// 中考学科
    static var juniorExamSubjects: [Subject] {
        [.chinese, .math, .english, .physics, .chemistry, .history, .geography, .politics, .biology]
    }
    
    /// 高考学科
    static var seniorExamSubjects: [Subject] {
        [.chinese, .math, .english, .physics, .chemistry, .biology, .history, .geography, .politics]
    }
}
