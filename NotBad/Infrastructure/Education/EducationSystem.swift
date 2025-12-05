//
//  EducationSystem.swift
//  NotBad
//
//  教育体系抽象协议 - 支持多国K12教育体系
//
//  不同国家的K12教育体系差异：
//  - 中国：小学6年 + 初中3年 + 高中3年 (6-3-3)
//  - 美国：Elementary K-5 + Middle 6-8 + High 9-12 (6-3-4)
//  - 日本：小学校6年 + 中学校3年 + 高等学校3年 (6-3-3)
//  - 韩国：초등학교6年 + 중학교3年 + 고등학교3年 (6-3-3)
//  - 英国：Primary 1-6 + Secondary 7-11 + Sixth Form 12-13 (6-5-2)
//

import Foundation
import SwiftUI

// MARK: - EducationRegion

/// 教育地区
///
/// 定义支持的教育体系地区，每个地区有独特的学制结构。
///
/// ## 支持的地区
/// - ``china``: 中国大陆 (6-3-3学制)
/// - ``usa``: 美国 (K-5, 6-8, 9-12)
/// - ``japan``: 日本 (6-3-3学制)
/// - ``korea``: 韩国 (6-3-3学制)
/// - ``uk``: 英国 (6-5-2学制)
/// - ``singapore``: 新加坡教育体系
/// - ``international``: 国际通用体系
/// - ``custom``: 自定义配置
public enum EducationRegion: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    case china = "CN"
    case japan = "JP"
    case korea = "KR"
    case singapore = "SG"
    case international = "INTL"
    case usa = "US"
    case uk = "GB"
    case custom = "CUSTOM"

    public var id: String { rawValue }

    /// 本地化显示名称
    public var displayName: String {
        String(localized: localizationKey)
    }

    private var localizationKey: String.LocalizationValue {
        switch self {
        case .china: "education_region_china"
        case .japan: "education_region_japan"
        case .korea: "education_region_korea"
        case .singapore: "education_region_singapore"
        case .international: "education_region_international"
        case .usa: "education_region_usa"
        case .uk: "education_region_uk"
        case .custom: "education_region_custom"
        }
    }

    /// 地区旗帜 emoji
    public var flag: String {
        switch self {
        case .china: "🇨🇳"
        case .japan: "🇯🇵"
        case .korea: "🇰🇷"
        case .singapore: "🇸🇬"
        case .international: "🌍"
        case .usa: "🇺🇸"
        case .uk: "🇬🇧"
        case .custom: "⚙️"
        }
    }

    /// 应用内置支持的地区（用于 Onboarding 选择）
    public static var builtInRegions: [EducationRegion] {
        [.china, .japan, .korea, .singapore, .international]
    }

    /// 根据设备地区自动检测
    public static func detectFromLocale() -> EducationRegion {
        let regionCode = Locale.current.region?.identifier ?? "CN"
        // 尝试匹配内置地区
        if let matched = EducationRegion(rawValue: regionCode),
           builtInRegions.contains(matched) {
            return matched
        }
        // 未匹配的地区使用国际通用体系
        return .international
    }
}

// MARK: - SchoolLevel

/// 学段/学校级别
///
/// 通用的学段定义，不同教育体系映射到这些通用学段。
public enum SchoolLevel: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    /// 小学/Elementary
    case primary
    /// 初中/Middle School
    case middle
    /// 高中/High School
    case high

    public var id: String { rawValue }
}

// MARK: - GradeLevel Protocol

/// 年级协议
///
/// 定义年级必须实现的属性和方法。
public protocol GradeLevelProtocol: Sendable, Hashable, Identifiable, CaseIterable {
    /// 年级唯一标识符
    var id: String { get }
    /// 年级序号（从1开始）
    var order: Int { get }
    /// 所属学段
    var schoolLevel: SchoolLevel { get }
    /// 本地化显示名称
    var displayName: String { get }
    /// 简短标签
    var shortLabel: String { get }
    /// 图标
    var icon: String { get }
    /// 主题颜色
    var color: Color { get }
}

// MARK: - SubjectProtocol

/// 学科协议
///
/// 定义学科必须实现的属性和方法。
public protocol SubjectProtocol: Sendable, Hashable, Identifiable, CaseIterable {
    /// 学科唯一标识符
    var id: String { get }
    /// 本地化显示名称
    var displayName: String { get }
    /// 简短标签
    var shortLabel: String { get }
    /// 学科分类
    var category: any SubjectCategoryProtocol { get }
    /// 适用的学段
    var applicableLevels: [SchoolLevel] { get }
    /// 图标
    var icon: String { get }
    /// 主题颜色
    var color: Color { get }

    /// 是否适用于指定学段
    func isApplicable(for level: SchoolLevel) -> Bool
}

extension SubjectProtocol {
    public func isApplicable(for level: SchoolLevel) -> Bool {
        applicableLevels.contains(level)
    }
}

// MARK: - SubjectCategoryProtocol

/// 学科分类协议
public protocol SubjectCategoryProtocol: Sendable, Hashable, Identifiable {
    var id: String { get }
    var displayName: String { get }
    var icon: String { get }
    var color: Color { get }
}

// MARK: - EducationSystemProtocol

/// 教育体系协议
///
/// 定义完整教育体系必须提供的配置。
///
/// ## 实现示例
/// ```swift
/// struct ChinaEducationSystem: EducationSystemProtocol {
///     let region = EducationRegion.china
///     let grades = ChinaGrade.allCases
///     let subjects = ChinaSubject.allCases
///     // ...
/// }
/// ```
public protocol EducationSystemProtocol: Sendable {
    /// 关联的年级类型
    associatedtype GradeType: GradeLevelProtocol
    /// 关联的学科类型
    associatedtype SubjectType: SubjectProtocol

    /// 教育地区
    var region: EducationRegion { get }

    /// 体系名称
    var name: String { get }

    /// 所有年级
    var grades: [GradeType] { get }

    /// 所有学科
    var subjects: [SubjectType] { get }

    /// 学段配置
    var schoolLevels: [SchoolLevelConfiguration] { get }

    /// 获取指定学段的年级
    func grades(for level: SchoolLevel) -> [GradeType]

    /// 获取指定学段的学科
    func subjects(for level: SchoolLevel) -> [SubjectType]
}

extension EducationSystemProtocol {
    public func grades(for level: SchoolLevel) -> [GradeType] {
        grades.filter { $0.schoolLevel == level }
    }

    public func subjects(for level: SchoolLevel) -> [SubjectType] {
        subjects.filter { $0.isApplicable(for: level) }
    }
}

// MARK: - SchoolLevelConfiguration

/// 学段配置
///
/// 定义每个学段的具体参数。
public struct SchoolLevelConfiguration: Sendable, Hashable, Identifiable {
    public let id: SchoolLevel
    /// 学段名称键（用于本地化）
    public let nameKey: String
    /// 年级起始序号
    public let startGrade: Int
    /// 年级结束序号
    public let endGrade: Int
    /// 年级数量
    public let gradeCount: Int
    /// 图标
    public let icon: String
    /// 颜色
    public let color: Color

    public init(
        level: SchoolLevel,
        nameKey: String,
        startGrade: Int,
        endGrade: Int,
        icon: String,
        color: Color
    ) {
        self.id = level
        self.nameKey = nameKey
        self.startGrade = startGrade
        self.endGrade = endGrade
        self.gradeCount = endGrade - startGrade + 1
        self.icon = icon
        self.color = color
    }

    /// 本地化名称
    public var displayName: String {
        String(localized: String.LocalizationValue(stringLiteral: nameKey))
    }

    /// 年级范围描述
    public var gradeRange: String {
        "\(startGrade)-\(endGrade)"
    }
}

// MARK: - EducationSystemError

/// 教育体系错误
public enum EducationSystemError: Error, LocalizedError {
    case unsupportedRegion(EducationRegion)
    case invalidGradeOrder(Int)
    case subjectNotApplicable(String, SchoolLevel)

    public var errorDescription: String? {
        switch self {
        case .unsupportedRegion(let region):
            return "Unsupported education region: \(region.displayName)"
        case .invalidGradeOrder(let order):
            return "Invalid grade order: \(order)"
        case .subjectNotApplicable(let subject, let level):
            return "Subject '\(subject)' is not applicable for \(level)"
        }
    }
}
