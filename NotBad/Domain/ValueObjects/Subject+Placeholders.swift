//
//  Subject+Placeholders.swift
//  NotBad
//
//  学科占位符文本扩展
//

import Foundation

// MARK: - Placeholders

extension Subject {
    /// 根据年级获取标题占位符
    /// - Parameter grade: 年级
    /// - Returns: 标题占位符示例
    nonisolated func titlePlaceholder(for grade: Grade) -> String {
        let key = titlePlaceholderKey(for: grade.stage)
        return String(localized: key)
    }
    
    /// 标题占位符本地化键值（根据学段）
    private func titlePlaceholderKey(for stage: GradeStage) -> String.LocalizationValue {
        switch (self, stage) {
        // 语文
        case (.chinese, .primary): return "subject_placeholder_title_chinese_primary"
        case (.chinese, .junior): return "subject_placeholder_title_chinese_junior"
        case (.chinese, .senior): return "subject_placeholder_title_chinese_senior"
        // 英语
        case (.english, .primary): return "subject_placeholder_title_english_primary"
        case (.english, .junior): return "subject_placeholder_title_english_junior"
        case (.english, .senior): return "subject_placeholder_title_english_senior"
        // 数学
        case (.math, .primary): return "subject_placeholder_title_math_primary"
        case (.math, .junior): return "subject_placeholder_title_math_junior"
        case (.math, .senior): return "subject_placeholder_title_math_senior"
        // 物理（初中+高中）
        case (.physics, .primary): return "subject_placeholder_title_physics_junior"
        case (.physics, .junior): return "subject_placeholder_title_physics_junior"
        case (.physics, .senior): return "subject_placeholder_title_physics_senior"
        // 化学（初中+高中）
        case (.chemistry, .primary): return "subject_placeholder_title_chemistry_junior"
        case (.chemistry, .junior): return "subject_placeholder_title_chemistry_junior"
        case (.chemistry, .senior): return "subject_placeholder_title_chemistry_senior"
        // 生物（初中+高中）
        case (.biology, .primary): return "subject_placeholder_title_biology_junior"
        case (.biology, .junior): return "subject_placeholder_title_biology_junior"
        case (.biology, .senior): return "subject_placeholder_title_biology_senior"
        // 科学（小学+初中）
        case (.science, .primary): return "subject_placeholder_title_science_primary"
        case (.science, .junior): return "subject_placeholder_title_science_junior"
        case (.science, .senior): return "subject_placeholder_title_science_junior"
        // 历史（初中+高中）
        case (.history, .primary): return "subject_placeholder_title_history_junior"
        case (.history, .junior): return "subject_placeholder_title_history_junior"
        case (.history, .senior): return "subject_placeholder_title_history_senior"
        // 地理（初中+高中）
        case (.geography, .primary): return "subject_placeholder_title_geography_junior"
        case (.geography, .junior): return "subject_placeholder_title_geography_junior"
        case (.geography, .senior): return "subject_placeholder_title_geography_senior"
        // 政治（初中+高中）
        case (.politics, .primary): return "subject_placeholder_title_politics_junior"
        case (.politics, .junior): return "subject_placeholder_title_politics_junior"
        case (.politics, .senior): return "subject_placeholder_title_politics_senior"
        // 道德与法治（小学+初中）
        case (.ethics, .primary): return "subject_placeholder_title_ethics_primary"
        case (.ethics, .junior): return "subject_placeholder_title_ethics_junior"
        case (.ethics, .senior): return "subject_placeholder_title_ethics_junior"
        // 信息技术
        case (.informationTech, .primary): return "subject_placeholder_title_it_primary"
        case (.informationTech, .junior): return "subject_placeholder_title_it_junior"
        case (.informationTech, .senior): return "subject_placeholder_title_it_senior"
        // 通用技术（高中）
        case (.generalTech, _): return "subject_placeholder_title_tech"
        // 其他
        case (.other, _): return "subject_placeholder_title_other"
        }
    }
    
    /// 根据年级获取知识点占位符
    /// - Parameter grade: 年级
    /// - Returns: 知识点占位符示例
    nonisolated func knowledgePointsPlaceholder(for grade: Grade) -> String {
        let key = knowledgePointsPlaceholderKey(for: grade.stage)
        return String(localized: key)
    }
    
    /// 知识点占位符本地化键值（根据学段）
    private func knowledgePointsPlaceholderKey(for stage: GradeStage) -> String.LocalizationValue {
        switch (self, stage) {
        // 语文
        case (.chinese, .primary): return "subject_placeholder_kp_chinese_primary"
        case (.chinese, .junior): return "subject_placeholder_kp_chinese_junior"
        case (.chinese, .senior): return "subject_placeholder_kp_chinese_senior"
        // 英语
        case (.english, .primary): return "subject_placeholder_kp_english_primary"
        case (.english, .junior): return "subject_placeholder_kp_english_junior"
        case (.english, .senior): return "subject_placeholder_kp_english_senior"
        // 数学
        case (.math, .primary): return "subject_placeholder_kp_math_primary"
        case (.math, .junior): return "subject_placeholder_kp_math_junior"
        case (.math, .senior): return "subject_placeholder_kp_math_senior"
        // 物理
        case (.physics, .primary): return "subject_placeholder_kp_physics_junior"
        case (.physics, .junior): return "subject_placeholder_kp_physics_junior"
        case (.physics, .senior): return "subject_placeholder_kp_physics_senior"
        // 化学
        case (.chemistry, .primary): return "subject_placeholder_kp_chemistry_junior"
        case (.chemistry, .junior): return "subject_placeholder_kp_chemistry_junior"
        case (.chemistry, .senior): return "subject_placeholder_kp_chemistry_senior"
        // 生物
        case (.biology, .primary): return "subject_placeholder_kp_biology_junior"
        case (.biology, .junior): return "subject_placeholder_kp_biology_junior"
        case (.biology, .senior): return "subject_placeholder_kp_biology_senior"
        // 科学
        case (.science, .primary): return "subject_placeholder_kp_science_primary"
        case (.science, .junior): return "subject_placeholder_kp_science_junior"
        case (.science, .senior): return "subject_placeholder_kp_science_junior"
        // 历史
        case (.history, .primary): return "subject_placeholder_kp_history_junior"
        case (.history, .junior): return "subject_placeholder_kp_history_junior"
        case (.history, .senior): return "subject_placeholder_kp_history_senior"
        // 地理
        case (.geography, .primary): return "subject_placeholder_kp_geography_junior"
        case (.geography, .junior): return "subject_placeholder_kp_geography_junior"
        case (.geography, .senior): return "subject_placeholder_kp_geography_senior"
        // 政治
        case (.politics, .primary): return "subject_placeholder_kp_politics_junior"
        case (.politics, .junior): return "subject_placeholder_kp_politics_junior"
        case (.politics, .senior): return "subject_placeholder_kp_politics_senior"
        // 道德与法治
        case (.ethics, .primary): return "subject_placeholder_kp_ethics_primary"
        case (.ethics, .junior): return "subject_placeholder_kp_ethics_junior"
        case (.ethics, .senior): return "subject_placeholder_kp_ethics_junior"
        // 信息技术
        case (.informationTech, .primary): return "subject_placeholder_kp_it_primary"
        case (.informationTech, .junior): return "subject_placeholder_kp_it_junior"
        case (.informationTech, .senior): return "subject_placeholder_kp_it_senior"
        // 通用技术
        case (.generalTech, _): return "subject_placeholder_kp_tech"
        // 其他
        case (.other, _): return "subject_placeholder_kp_other"
        }
    }
}
