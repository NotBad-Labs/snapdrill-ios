//
//  EducationSystem.swift
//  NotBad
//
//  教育体系基础类型定义
//
//  包含 EducationRegion、SchoolLevel 等核心枚举。
//  具体国家数据由 EducationSystems.json 驱动。
//

import Foundation

// MARK: - EducationRegion

/// 教育地区
///
/// 定义支持的教育体系地区，每个地区有独特的学制结构。
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

    public init(
        level: SchoolLevel,
        nameKey: String,
        startGrade: Int,
        endGrade: Int,
        icon: String
    ) {
        self.id = level
        self.nameKey = nameKey
        self.startGrade = startGrade
        self.endGrade = endGrade
        self.gradeCount = endGrade - startGrade + 1
        self.icon = icon
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
