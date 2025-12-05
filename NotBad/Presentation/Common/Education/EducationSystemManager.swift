//
//  EducationSystemManager.swift
//  NotBad
//
//  教育体系管理器
//
//  负责管理和切换不同国家的教育体系配置。
//  使用类型擦除实现对不同教育体系的统一访问。
//

import Foundation
import SwiftUI
import Observation

// MARK: - AnyEducationSystem

/// 类型擦除的教育体系
///
/// 允许在运行时存储和切换不同类型的教育体系。
public struct AnyEducationSystem: Sendable {
    public let region: EducationRegion
    public let name: String

    private let _schoolLevels: @Sendable () -> [SchoolLevelConfiguration]
    private let _gradeCount: @Sendable () -> Int
    private let _subjectCount: @Sendable () -> Int
    private let _gradeDisplayName: @Sendable (Int) -> String?
    private let _gradeShortLabel: @Sendable (Int) -> String?
    private let _gradeSchoolLevel: @Sendable (Int) -> SchoolLevel?
    private let _gradeIcon: @Sendable (Int) -> String?

    private let _gradeIds: @Sendable () -> [String]
    private let _subjectIds: @Sendable () -> [String]

    // ID-based lookups
    private let _gradeDisplayNameById: @Sendable (String) -> String?
    private let _gradeShortLabelById: @Sendable (String) -> String?
    private let _gradeSchoolLevelById: @Sendable (String) -> SchoolLevel?
    private let _gradeIconById: @Sendable (String) -> String?

    private let _subjectDisplayNameById: @Sendable (String) -> String?
    private let _subjectShortLabelById: @Sendable (String) -> String?
    private let _subjectIconById: @Sendable (String) -> String?

    public init<T: EducationSystemProtocol>(_ system: T) {
        self.region = system.region
        self.name = system.name

        let grades = system.grades
        let subjects = system.subjects

        self._schoolLevels = { system.schoolLevels }
        self._gradeCount = { grades.count }
        self._subjectCount = { subjects.count }

        self._gradeIds = { grades.map(\.id) }
        self._subjectIds = { subjects.map(\.id) }

        // Order-based lookups
        self._gradeDisplayName = { order in
            grades.first { $0.order == order }?.displayName
        }
        self._gradeShortLabel = { order in
            grades.first { $0.order == order }?.shortLabel
        }
        self._gradeSchoolLevel = { order in
            grades.first { $0.order == order }?.schoolLevel
        }
        self._gradeIcon = { order in
            grades.first { $0.order == order }?.icon
        }

        // ID-based lookups
        self._gradeDisplayNameById = { id in
            grades.first { $0.id == id }?.displayName
        }
        self._gradeShortLabelById = { id in
            grades.first { $0.id == id }?.shortLabel
        }
        self._gradeSchoolLevelById = { id in
            grades.first { $0.id == id }?.schoolLevel
        }
        self._gradeIconById = { id in
            grades.first { $0.id == id }?.icon
        }

        self._subjectDisplayNameById = { id in
            subjects.first { $0.id == id }?.displayName
        }
        self._subjectShortLabelById = { id in
            subjects.first { $0.id == id }?.shortLabel
        }
        self._subjectIconById = { id in
            subjects.first { $0.id == id }?.icon
        }
    }

    public var schoolLevels: [SchoolLevelConfiguration] { _schoolLevels() }
    public var gradeCount: Int { _gradeCount() }
    public var subjectCount: Int { _subjectCount() }

    public var gradeIds: [String] { _gradeIds() }
    public var subjectIds: [String] { _subjectIds() }

    public func gradeDisplayName(for order: Int) -> String? { _gradeDisplayName(order) }
    public func gradeShortLabel(for order: Int) -> String? { _gradeShortLabel(order) }
    public func gradeSchoolLevel(for order: Int) -> SchoolLevel? { _gradeSchoolLevel(order) }
    public func gradeIcon(for order: Int) -> String? { _gradeIcon(order) }

    public func gradeDisplayName(for id: String) -> String? { _gradeDisplayNameById(id) }
    public func gradeShortLabel(for id: String) -> String? { _gradeShortLabelById(id) }
    public func gradeSchoolLevel(for id: String) -> SchoolLevel? { _gradeSchoolLevelById(id) }
    public func gradeIcon(for id: String) -> String? { _gradeIconById(id) }

    public func subjectDisplayName(for id: String) -> String? { _subjectDisplayNameById(id) }
    public func subjectShortLabel(for id: String) -> String? { _subjectShortLabelById(id) }
    public func subjectIcon(for id: String) -> String? { _subjectIconById(id) }
}

// MARK: - EducationSystemManager

/// 教育体系管理器
///
/// 全局单例，负责管理当前使用的教育体系。
///
/// ## 使用示例
/// ```swift
/// // 获取当前教育体系
/// let current = EducationSystemManager.shared.currentSystem
///
/// // 切换到美国教育体系
/// EducationSystemManager.shared.switchTo(.usa)
///
/// // 获取当前年级显示名称
/// let gradeName = EducationSystemManager.shared.gradeDisplayName(for: 9)
/// ```
@Observable
@MainActor
public final class EducationSystemManager: Sendable {

    // MARK: - Singleton

    /// 共享实例
    public static let shared = EducationSystemManager()

    // MARK: - Properties

    /// 当前教育地区
    public private(set) var currentRegion: EducationRegion {
        didSet {
            if oldValue != currentRegion {
                UserDefaults.standard.set(currentRegion.rawValue, forKey: "education_region")
                updateCurrentSystem()
            }
        }
    }

    /// 当前教育体系（类型擦除）
    public private(set) var currentSystem: AnyEducationSystem

    // MARK: - Initialization

    private init() {
        // 从 UserDefaults 读取保存的地区，或使用自动检测
        let region: EducationRegion
        if let savedRegion = UserDefaults.standard.string(forKey: "education_region"),
           let saved = EducationRegion(rawValue: savedRegion) {
            region = saved
        } else {
            region = EducationRegion.detectFromLocale()
        }

        // 初始化所有存储属性
        self.currentRegion = region
        self.currentSystem = Self.createSystem(for: region)
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
        currentSystem.schoolLevels
    }

    /// 年级数量
    public var gradeCount: Int {
        currentSystem.gradeCount
    }

    /// 学科数量
    public var subjectCount: Int {
        currentSystem.subjectCount
    }

    /// 所有年级 ID
    public var gradeIds: [String] {
        currentSystem.gradeIds
    }

    /// 所有学科 ID
    public var subjectIds: [String] {
        currentSystem.subjectIds
    }

    // MARK: - Order-based Accessors

    /// 获取年级显示名称
    public func gradeDisplayName(for order: Int) -> String {
        currentSystem.gradeDisplayName(for: order) ?? "Grade \(order)"
    }

    /// 获取年级简短标签
    public func gradeShortLabel(for order: Int) -> String {
        currentSystem.gradeShortLabel(for: order) ?? "\(order)"
    }

    /// 获取年级所属学段
    public func gradeSchoolLevel(for order: Int) -> SchoolLevel? {
        currentSystem.gradeSchoolLevel(for: order)
    }

    /// 获取年级图标
    public func gradeIcon(for order: Int) -> String {
        currentSystem.gradeIcon(for: order) ?? "graduationcap"
    }

    // MARK: - ID-based Accessors

    /// 获取年级显示名称 (ID)
    public func gradeDisplayName(for id: String) -> String {
        currentSystem.gradeDisplayName(for: id) ?? id
    }

    /// 获取年级简短标签 (ID)
    public func gradeShortLabel(for id: String) -> String {
        currentSystem.gradeShortLabel(for: id) ?? id
    }

    /// 获取年级所属学段 (ID)
    public func gradeSchoolLevel(for id: String) -> SchoolLevel? {
        currentSystem.gradeSchoolLevel(for: id)
    }

    /// 获取年级图标 (ID)
    public func gradeIcon(for id: String) -> String {
        currentSystem.gradeIcon(for: id) ?? "graduationcap"
    }

    /// 获取学科显示名称 (ID)
    public func subjectDisplayName(for id: String) -> String {
        currentSystem.subjectDisplayName(for: id) ?? id
    }

    /// 获取学科简短标签 (ID)
    public func subjectShortLabel(for id: String) -> String {
        currentSystem.subjectShortLabel(for: id) ?? id
    }

    /// 获取学科图标 (ID)
    public func subjectIcon(for id: String) -> String {
        currentSystem.subjectIcon(for: id) ?? "book"
    }

    // MARK: - Private Methods

    private func updateCurrentSystem() {
        currentSystem = Self.createSystem(for: currentRegion)
    }

    private static func createSystem(for region: EducationRegion) -> AnyEducationSystem {
        switch region {
        case .china:
            return AnyEducationSystem(ChinaEducationSystem())
        case .japan:
            return AnyEducationSystem(JapanEducationSystem())
        case .korea:
            return AnyEducationSystem(KoreaEducationSystem())
        case .singapore:
            return AnyEducationSystem(SingaporeEducationSystem())
        case .international:
            return AnyEducationSystem(InternationalEducationSystem())
        case .usa:
            return AnyEducationSystem(USEducationSystem())
        default:
            // 默认使用国际通用体系
            return AnyEducationSystem(InternationalEducationSystem())
        }
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

    /// 用于预览的美国教育体系
    @MainActor
    public static var previewUSA: EducationSystemManager {
        let manager = EducationSystemManager.shared
        manager.switchTo(.usa)
        return manager
    }
}
