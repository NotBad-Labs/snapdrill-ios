//
//  Subject+Classification.swift
//  NotBad
//
//  学科分类与学段适用性扩展
//

import Foundation

// MARK: - Classification

extension Subject {
    /// 学科分类
    nonisolated var category: SubjectCategory {
        switch self {
        case .chinese, .english:
            .language
        case .math, .physics, .chemistry, .biology, .science:
            .science
        case .history, .geography, .politics, .ethics:
            .humanities
        case .informationTech, .generalTech:
            .technology
        case .other:
            .other
        }
    }
}

// MARK: - Applicable Stages

extension Subject {
    /// 适用学段（中国大陆学制）
    /// 
    /// 此属性返回中国大陆教育体系下的学科适用学段。
    /// 如需获取其他地区的适用学段，请使用 `applicableStages(for:)` 方法。
    nonisolated var applicableStages: [GradeStage] {
        applicableStages(for: .china)
    }
    
    /// 获取指定教育地区的适用学段
    /// - Parameter region: 教育地区
    /// - Returns: 适用的学段数组
    nonisolated func applicableStages(for region: EducationRegion) -> [GradeStage] {
        switch region {
        case .china:
            chinaApplicableStages
        case .japan:
            japanApplicableStages
        case .korea:
            koreaApplicableStages
        case .singapore:
            singaporeApplicableStages
        case .usa:
            usaApplicableStages
        case .uk:
            ukApplicableStages
        case .international, .custom:
            internationalApplicableStages
        }
    }
    
    // MARK: - Regional Applicable Stages
    
    /// 中国大陆学制
    private var chinaApplicableStages: [GradeStage] {
        switch self {
        case .chinese, .math, .english:
            [.primary, .junior, .senior]
        case .science, .ethics:
            [.primary, .junior]
        case .physics, .chemistry, .history, .geography, .politics, .biology:
            [.junior, .senior]
        case .generalTech:
            [.senior]
        case .informationTech, .other:
            [.primary, .junior, .senior]
        }
    }
    
    /// 日本学制：理科(科学)贯穿全学段，社会科目从小学开始
    private var japanApplicableStages: [GradeStage] {
        switch self {
        case .chinese, .math, .english:
            [.primary, .junior, .senior]
        case .science:  // 日本的理科从小学就有
            [.primary, .junior, .senior]
        case .physics, .chemistry, .biology:
            [.junior, .senior]
        case .history, .geography, .politics:  // 社会科从小学开始
            [.primary, .junior, .senior]
        case .ethics:  // 道德教育贯穿
            [.primary, .junior, .senior]
        case .informationTech:
            [.junior, .senior]
        case .generalTech, .other:
            [.primary, .junior, .senior]
        }
    }
    
    /// 韩国学制：6-3-3结构，与中国类似但有细微差别
    private var koreaApplicableStages: [GradeStage] {
        switch self {
        case .chinese, .math, .english:
            [.primary, .junior, .senior]
        case .science:  // 韩国小学有"科学"课
            [.primary, .junior]
        case .physics, .chemistry, .biology:
            [.junior, .senior]
        case .history, .geography, .politics:  // 社会科从小学开始（사회）
            [.primary, .junior, .senior]
        case .ethics:  // 道德从小学开始（도덕）
            [.primary, .junior]
        case .informationTech:  // 信息从小学高年级开始
            [.primary, .junior, .senior]
        case .generalTech:
            [.senior]
        case .other:
            [.primary, .junior, .senior]
        }
    }
    
    /// 新加坡学制：6-4-2结构（小学6年+中学4年+初级学院2年）
    private var singaporeApplicableStages: [GradeStage] {
        switch self {
        case .chinese, .math, .english:  // 双语教育，从小学开始
            [.primary, .junior, .senior]
        case .science:  // Primary Science 从小学开始
            [.primary, .junior, .senior]
        case .physics, .chemistry, .biology:  // 中学分科
            [.junior, .senior]
        case .history, .geography:  // Social Studies/Humanities
            [.primary, .junior, .senior]
        case .politics:  // Social Studies 的一部分
            [.junior, .senior]
        case .ethics:  // Character and Citizenship Education
            [.primary, .junior, .senior]
        case .informationTech:  // Computing 从中学开始
            [.junior, .senior]
        case .generalTech:  // Design & Technology
            [.junior, .senior]
        case .other:
            [.primary, .junior, .senior]
        }
    }
    
    /// 美国学制：K-5 + 6-8 + 9-12（因州而异）
    private var usaApplicableStages: [GradeStage] {
        switch self {
        case .chinese:  // 通常作为外语，从中学开始
            [.junior, .senior]
        case .math, .english:  // 核心课程，全学段
            [.primary, .junior, .senior]
        case .science:  // Science 贯穿 K-12
            [.primary, .junior, .senior]
        case .physics, .chemistry, .biology:  // 高中分科
            [.senior]
        case .history, .geography, .politics:  // Social Studies 从小学开始
            [.primary, .junior, .senior]
        case .ethics:  // 不单独设课，融入其他课程
            [.junior, .senior]
        case .informationTech:  // Computer Science
            [.primary, .junior, .senior]
        case .generalTech:  // Technology Education
            [.junior, .senior]
        case .other:
            [.primary, .junior, .senior]
        }
    }
    
    /// 英国学制：Primary 1-6 + Secondary 7-11 + Sixth Form 12-13
    private var ukApplicableStages: [GradeStage] {
        switch self {
        case .chinese:  // 作为 MFL（现代外语），从中学开始
            [.junior, .senior]
        case .math, .english:  // 核心课程，全学段必修
            [.primary, .junior, .senior]
        case .science:  // Science 必修到 GCSE
            [.primary, .junior, .senior]
        case .physics, .chemistry, .biology:  // A-Level 分科（Sixth Form）
            [.senior]
        case .history, .geography:  // 从小学开始（Key Stage 1）
            [.primary, .junior, .senior]
        case .politics:  // Citizenship/Politics A-Level
            [.junior, .senior]
        case .ethics:  // PSHE/Religious Education
            [.primary, .junior, .senior]
        case .informationTech:  // Computing
            [.primary, .junior, .senior]
        case .generalTech:  // Design and Technology
            [.primary, .junior, .senior]
        case .other:
            [.primary, .junior, .senior]
        }
    }
    
    /// 国际学校/IB体系/自定义：灵活配置，大多数学科全学段可选
    private var internationalApplicableStages: [GradeStage] {
        switch self {
        case .chinese, .math, .english:
            [.primary, .junior, .senior]
        case .science:
            [.primary, .junior, .senior]
        case .physics, .chemistry, .biology:
            [.junior, .senior]
        case .history, .geography, .politics:
            [.primary, .junior, .senior]
        case .ethics:
            [.primary, .junior, .senior]
        case .informationTech:
            [.primary, .junior, .senior]
        case .generalTech:
            [.junior, .senior]
        case .other:
            [.primary, .junior, .senior]
        }
    }
}

// MARK: - Applicability Checks

extension Subject {
    /// 是否适用于指定学段
    /// - Parameter stage: 学段
    /// - Returns: 是否适用
    nonisolated func isApplicable(for stage: GradeStage) -> Bool {
        applicableStages.contains(stage)
    }
    
    /// 是否适用于指定学段（指定教育地区）
    /// - Parameters:
    ///   - stage: 学段
    ///   - region: 教育地区
    /// - Returns: 是否适用
    nonisolated func isApplicable(for stage: GradeStage, in region: EducationRegion) -> Bool {
        applicableStages(for: region).contains(stage)
    }
    
    /// 是否适用于指定年级
    /// - Parameter grade: 年级
    /// - Returns: 是否适用
    nonisolated func isApplicable(for grade: Grade) -> Bool {
        applicableStages.contains(grade.stage)
    }
    
    /// 是否适用于指定年级（指定教育地区）
    /// - Parameters:
    ///   - grade: 年级
    ///   - region: 教育地区
    /// - Returns: 是否适用
    nonisolated func isApplicable(for grade: Grade, in region: EducationRegion) -> Bool {
        applicableStages(for: region).contains(grade.stage)
    }
    
    /// 获取该学科适用的所有年级（使用默认地区：中国大陆）
    /// - Returns: 适用的年级数组（不含幼儿园）
    nonisolated var applicableGrades: [Grade] {
        applicableGrades(for: .china)
    }
    
    /// 获取该学科在指定教育地区适用的所有年级
    /// - Parameter region: 教育地区
    /// - Returns: 适用的年级数组（不含幼儿园）
    nonisolated func applicableGrades(for region: EducationRegion) -> [Grade] {
        let stages = applicableStages(for: region)
        return Grade.allCases.filter { grade in
            grade != .kindergarten && stages.contains(grade.stage)
        }
    }
}

// MARK: - Query Methods

extension Subject {
    /// 获取指定学段的学科列表
    /// - Parameter stage: 学段
    /// - Returns: 适用的学科数组
    static func subjects(for stage: GradeStage) -> [Subject] {
        allCases.filter { $0.isApplicable(for: stage) }
    }

    /// 获取指定分类的学科列表
    /// - Parameter category: 学科分类
    /// - Returns: 该分类下的学科数组
    static func subjects(in category: SubjectCategory) -> [Subject] {
        allCases.filter { $0.category == category }
    }
}
