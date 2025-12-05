//
//  Subject.swift
//  NotBad
//
//  学科值对象 - K12 完整覆盖
//
//  ## 文件结构
//  - `Subject.swift` - 核心枚举定义
//  - `Subject+Display.swift` - 显示属性 (displayName, shortLabel, icon)
//  - `Subject+Placeholders.swift` - 占位符文本
//  - `Subject+Classification.swift` - 分类与学段适用性
//  - `Subject+Collections.swift` - 静态集合
//  - `SubjectCategory.swift` - 学科分类枚举
//

import Foundation

// MARK: - Subject

/// 学科（K12全覆盖）
///
/// 覆盖小学、初中、高中所有主要学科，支持按学段筛选。
///
/// ## 学科列表
///
/// ### 语言类
/// - ``chinese``: 语文
/// - ``english``: 英语
///
/// ### 理科类
/// - ``math``: 数学
/// - ``physics``: 物理
/// - ``chemistry``: 化学
/// - ``biology``: 生物
/// - ``science``: 科学（小学、初中）
///
/// ### 人文类
/// - ``history``: 历史
/// - ``geography``: 地理
/// - ``politics``: 政治
/// - ``ethics``: 道德与法治
///
/// ### 技术类
/// - ``informationTech``: 信息技术
/// - ``generalTech``: 通用技术
///
/// ## 使用示例
/// ```swift
/// // 获取高中适用学科
/// let seniorSubjects = Subject.subjects(for: .senior)
///
/// // 检查学科是否适用于某学段
/// let isApplicable = Subject.physics.isApplicable(for: .junior)
/// ```
///
/// ## 相关类型
/// - ``SubjectCategory``: 学科分类
/// - ``Grade``: 年级
/// - ``GradeStage``: 学段
enum Subject: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    // MARK: - 语言类
    
    /// 语文
    case chinese = "chinese"
    /// 英语
    case english = "english"

    // MARK: - 理科类
    
    /// 数学
    case math = "math"
    /// 物理（初中、高中）
    case physics = "physics"
    /// 化学（初中、高中）
    case chemistry = "chemistry"
    /// 生物（高中）
    case biology = "biology"
    /// 科学（小学、初中科学课）
    case science = "science"

    // MARK: - 人文类
    
    /// 历史（初中、高中）
    case history = "history"
    /// 地理（初中、高中）
    case geography = "geography"
    /// 政治（初中、高中）
    case politics = "politics"
    /// 道德与法治（小学、初中）
    case ethics = "ethics"

    // MARK: - 技术类
    
    /// 信息技术
    case informationTech = "information_tech"
    /// 通用技术（高中）
    case generalTech = "general_tech"

    // MARK: - 其他
    
    /// 其他学科
    case other = "other"

    // MARK: - Identifiable

    nonisolated var id: String { rawValue }
}
