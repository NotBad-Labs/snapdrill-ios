//
//  EducationSystemManager.swift
//  NotBad
//
//  教育体系管理器（JSON 数据驱动）
//
//  从 EducationSystems.json 加载配置，替代硬编码的 Swift 枚举。
//  ~2400 行代码 → ~200 行代码 + JSON 配置
//

import Foundation
import SwiftUI
import Observation

// MARK: - EducationSystemManager

/// 教育体系管理器
///
/// 全局单例，负责管理当前使用的教育体系。
/// 使用 JSON 数据驱动，支持热更新。
///
/// ## 使用示例
/// ```swift
/// // 获取当前教育体系
/// let current = EducationSystemManager.shared.currentSystem
///
/// // 切换到日本教育体系
/// EducationSystemManager.shared.switchTo(.japan)
///
/// // 获取当前年级显示名称
/// let gradeName = EducationSystemManager.shared.gradeDisplayName(for: "grade_9")
/// ```
@Observable
@MainActor
public final class EducationSystemManager: Sendable {

    // MARK: - Singleton

    /// 共享实例
    public static let shared = EducationSystemManager()

    // MARK: - Properties

    /// 所有教育体系数据（从 JSON 加载）
    private let allSystems: EducationSystemsData?
    
    /// 当前教育地区
    public private(set) var currentRegion: EducationRegion {
        didSet {
            if oldValue != currentRegion {
                UserDefaults.standard.set(currentRegion.rawValue, forKey: "education_region")
                updateCurrentSystem()
            }
        }
    }

    /// 当前教育体系
    public private(set) var currentSystem: DataDrivenEducationSystem?

    // MARK: - Initialization

    private init() {
        // 加载 JSON 数据
        self.allSystems = EducationDataLoader.load()
        
        // 从 UserDefaults 读取保存的地区，或使用自动检测
        let region: EducationRegion
        if let savedRegion = UserDefaults.standard.string(forKey: "education_region"),
           let saved = EducationRegion(rawValue: savedRegion) {
            region = saved
        } else {
            region = EducationRegion.detectFromLocale()
        }

        self.currentRegion = region
        self.currentSystem = Self.createSystem(for: region, from: allSystems)
    }

    // MARK: - Public Methods

    /// 切换教育体系
    public func switchTo(_ region: EducationRegion) {
        guard region != currentRegion else { return }
        currentRegion = region
    }

    /// 重置为自动检测的地区
    public func resetToAutoDetected() {
        let detected = EducationRegion.detectFromLocale()
        switchTo(detected)
    }

    // MARK: - Convenience Accessors

    /// 当前学段配置
    public var schoolLevels: [SchoolLevelConfiguration] {
        currentSystem?.schoolLevels ?? []
    }

    /// 年级数量
    public var gradeCount: Int {
        currentSystem?.grades.count ?? 0
    }

    /// 学科数量
    public var subjectCount: Int {
        currentSystem?.subjects.count ?? 0
    }

    /// 所有年级 ID
    public var gradeIds: [String] {
        currentSystem?.grades.map(\.id) ?? []
    }

    /// 所有学科 ID
    public var subjectIds: [String] {
        currentSystem?.subjects.map(\.id) ?? []
    }
    
    /// 所有年级数据
    public var grades: [GradeData] {
        currentSystem?.grades ?? []
    }
    
    /// 所有学科数据
    public var subjects: [SubjectData] {
        currentSystem?.subjects ?? []
    }

    // MARK: - Order-based Accessors

    /// 获取年级显示名称
    public func gradeDisplayName(for order: Int) -> String {
        currentSystem?.grade(byOrder: order)?.displayName ?? "Grade \(order)"
    }

    /// 获取年级简短标签
    public func gradeShortLabel(for order: Int) -> String {
        currentSystem?.grade(byOrder: order)?.shortLabel ?? "\(order)"
    }

    /// 获取年级所属学段
    public func gradeSchoolLevel(for order: Int) -> SchoolLevel? {
        currentSystem?.grade(byOrder: order)?.schoolLevel
    }

    /// 获取年级图标
    public func gradeIcon(for order: Int) -> String {
        currentSystem?.grade(byOrder: order)?.icon ?? "graduationcap"
    }

    // MARK: - ID-based Accessors

    /// 获取年级显示名称 (ID)
    public func gradeDisplayName(for id: String) -> String {
        currentSystem?.grade(byId: id)?.displayName ?? id
    }

    /// 获取年级简短标签 (ID)
    public func gradeShortLabel(for id: String) -> String {
        currentSystem?.grade(byId: id)?.shortLabel ?? id
    }

    /// 获取年级所属学段 (ID)
    public func gradeSchoolLevel(for id: String) -> SchoolLevel? {
        currentSystem?.grade(byId: id)?.schoolLevel
    }

    /// 获取年级图标 (ID)
    public func gradeIcon(for id: String) -> String {
        currentSystem?.grade(byId: id)?.icon ?? "graduationcap"
    }

    /// 获取学科显示名称 (ID)
    public func subjectDisplayName(for id: String) -> String {
        currentSystem?.subject(byId: id)?.displayName ?? id
    }

    /// 获取学科简短标签 (ID)
    public func subjectShortLabel(for id: String) -> String {
        currentSystem?.subject(byId: id)?.shortLabel ?? id
    }

    /// 获取学科图标 (ID)
    public func subjectIcon(for id: String) -> String {
        currentSystem?.subject(byId: id)?.icon ?? "book"
    }
    
    /// 获取指定学段的年级
    public func grades(for level: SchoolLevel) -> [GradeData] {
        currentSystem?.grades(for: level) ?? []
    }
    
    /// 获取指定学段的学科
    public func subjects(for level: SchoolLevel) -> [SubjectData] {
        currentSystem?.subjects(for: level) ?? []
    }

    // MARK: - Private Methods

    private func updateCurrentSystem() {
        currentSystem = Self.createSystem(for: currentRegion, from: allSystems)
    }

    private static func createSystem(for region: EducationRegion, from data: EducationSystemsData?) -> DataDrivenEducationSystem? {
        guard let systemData = data?.systems[region.rawValue] else {
            // Fallback to international
            if let intlData = data?.systems[EducationRegion.international.rawValue] {
                return DataDrivenEducationSystem(region: .international, data: intlData)
            }
            return nil
        }
        return DataDrivenEducationSystem(region: region, data: systemData)
    }
}

// MARK: - SwiftUI Environment

/// 教育体系环境键
private struct EducationSystemKey: EnvironmentKey {
    static var defaultValue: EducationSystemManager {
        MainActor.assumeIsolated {
            EducationSystemManager.shared
        }
    }
}

extension EnvironmentValues {
    /// 当前教育体系管理器
    public var educationSystem: EducationSystemManager {
        get { self[EducationSystemKey.self] }
        set { self[EducationSystemKey.self] = newValue }
    }
}

// MARK: - Preview Support

extension EducationSystemManager {
    /// 用于预览的中国教育体系
    @MainActor
    public static var previewChina: EducationSystemManager {
        let manager = EducationSystemManager.shared
        manager.switchTo(.china)
        return manager
    }

    /// 用于预览的日本教育体系
    @MainActor
    public static var previewJapan: EducationSystemManager {
        let manager = EducationSystemManager.shared
        manager.switchTo(.japan)
        return manager
    }
}
