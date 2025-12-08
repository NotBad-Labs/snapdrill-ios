//
//  EducationDataModels.swift
//  NotBad
//
//  JSON 数据驱动的教育体系模型
//
//  从 EducationSystems.json 加载配置，替代硬编码的 Swift 枚举。
//

import Foundation
import os.log

private let logger = Logger(subsystem: "com.notbad", category: "Education")

// MARK: - JSON Root

/// 教育系统 JSON 根结构
public struct EducationSystemsData: Codable, Sendable {
    public let version: String
    public let systems: [String: EducationSystemData]
}

// MARK: - Education System Data

/// 单个教育体系数据
public struct EducationSystemData: Codable, Sendable {
    public let name: String
    public let schoolLevels: [SchoolLevelData]
    public let grades: [GradeData]
    public let subjects: [SubjectData]
    public let subjectCategories: [SubjectCategoryData]
}

// MARK: - School Level Data

/// 学段数据
public struct SchoolLevelData: Codable, Sendable {
    public let level: String
    public let nameKey: String
    public let startGrade: Int
    public let endGrade: Int
    public let icon: String
    
    public var schoolLevel: SchoolLevel? {
        SchoolLevel(rawValue: level)
    }
    
    public func toConfiguration() -> SchoolLevelConfiguration {
        SchoolLevelConfiguration(
            level: schoolLevel ?? .primary,
            nameKey: nameKey,
            startGrade: startGrade,
            endGrade: endGrade,
            icon: icon
        )
    }
}

// MARK: - Grade Data

/// 年级数据
public struct GradeData: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let order: Int
    public let level: String
    public let nameKey: String
    public let shortKey: String
    public let icon: String
    public let isGraduation: Bool
    
    public var schoolLevel: SchoolLevel? {
        SchoolLevel(rawValue: level)
    }
    
    public var displayName: String {
        String(localized: String.LocalizationValue(stringLiteral: nameKey))
    }
    
    public var shortLabel: String {
        String(localized: String.LocalizationValue(stringLiteral: shortKey))
    }
}

// MARK: - Subject Data

/// 学科数据
public struct SubjectData: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let category: String
    public let nameKey: String
    public let shortKey: String
    public let icon: String
    public let levels: [String]
    
    public var displayName: String {
        String(localized: String.LocalizationValue(stringLiteral: nameKey))
    }
    
    public var shortLabel: String {
        String(localized: String.LocalizationValue(stringLiteral: shortKey))
    }
    
    public var applicableLevels: [SchoolLevel] {
        levels.compactMap { SchoolLevel(rawValue: $0) }
    }
    
    public func isApplicable(for level: SchoolLevel) -> Bool {
        levels.contains(level.rawValue)
    }
}

// MARK: - Subject Category Data

/// 学科分类数据
public struct SubjectCategoryData: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let nameKey: String
    public let icon: String
    
    public var displayName: String {
        String(localized: String.LocalizationValue(stringLiteral: nameKey))
    }
}

// MARK: - Education Data Loader

/// 教育数据加载器
public enum EducationDataLoader {
    
    /// 从 Bundle 加载教育系统数据
    public static func load() -> EducationSystemsData? {
        guard let url = Bundle.main.url(forResource: "EducationSystems", withExtension: "json") else {
            logger.warning("EducationSystems.json not found in bundle")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(EducationSystemsData.self, from: data)
        } catch {
            logger.warning("Failed to decode EducationSystems.json: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 获取指定地区的教育体系
    public static func system(for region: EducationRegion) -> EducationSystemData? {
        load()?.systems[region.rawValue]
    }
}

// MARK: - DataDrivenEducationSystem

/// 数据驱动的教育体系（替代硬编码的 struct）
public struct DataDrivenEducationSystem: Sendable {
    public let region: EducationRegion
    public let data: EducationSystemData
    
    public init(region: EducationRegion, data: EducationSystemData) {
        self.region = region
        self.data = data
    }
    
    public var name: String {
        String(localized: String.LocalizationValue(stringLiteral: data.name))
    }
    
    public var schoolLevels: [SchoolLevelConfiguration] {
        data.schoolLevels.map { $0.toConfiguration() }
    }
    
    public var grades: [GradeData] {
        data.grades
    }
    
    public var subjects: [SubjectData] {
        data.subjects
    }
    
    public var subjectCategories: [SubjectCategoryData] {
        data.subjectCategories
    }
    
    // MARK: - Query Methods
    
    public func grades(for level: SchoolLevel) -> [GradeData] {
        data.grades.filter { $0.level == level.rawValue }
    }
    
    public func subjects(for level: SchoolLevel) -> [SubjectData] {
        data.subjects.filter { $0.isApplicable(for: level) }
    }
    
    public func grade(byId id: String) -> GradeData? {
        data.grades.first { $0.id == id }
    }
    
    public func grade(byOrder order: Int) -> GradeData? {
        data.grades.first { $0.order == order }
    }
    
    public func subject(byId id: String) -> SubjectData? {
        data.subjects.first { $0.id == id }
    }
    
    public func category(byId id: String) -> SubjectCategoryData? {
        data.subjectCategories.first { $0.id == id }
    }
}
