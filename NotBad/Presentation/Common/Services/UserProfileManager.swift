//
//  UserProfileManager.swift
//  NotBad
//
//  用户个人资料管理器
//

import Foundation
import SwiftUI

// MARK: - UserProfileManager

/// 用户个人资料管理器
///
/// 管理用户的昵称、头像等个人设置，支持本地存储和 iCloud 同步。
@MainActor
final class UserProfileManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = UserProfileManager()
    
    // MARK: - Keys
    
    private enum Keys {
        static let nickname = "user_nickname"
        static let avatar = "user_avatar"
        static let gradientIndex = "user_gradient_index"
        static let enabledSubjects = "user_enabled_subjects"
        static let customSubjects = "user_custom_subjects"
        static let enabledCustomSubjectIds = "user_enabled_custom_subject_ids"
    }
    
    // MARK: - Published Properties
    
    @Published var nickname: String {
        didSet {
            saveToLocal(nickname, forKey: Keys.nickname)
            syncToCloud(nickname, forKey: Keys.nickname)
        }
    }
    
    @Published var avatar: String {
        didSet {
            saveToLocal(avatar, forKey: Keys.avatar)
            syncToCloud(avatar, forKey: Keys.avatar)
        }
    }
    
    @Published var gradientIndex: Int {
        didSet {
            saveToLocal(gradientIndex, forKey: Keys.gradientIndex)
            syncToCloud(gradientIndex, forKey: Keys.gradientIndex)
        }
    }
    
    /// 用户启用的学科列表
    /// 默认启用：语文、数学、英语、物理、化学
    @Published var enabledSubjects: Set<Subject> {
        didSet {
            let rawValues = enabledSubjects.map { $0.rawValue }
            saveToLocal(rawValues, forKey: Keys.enabledSubjects)
            syncToCloud(rawValues, forKey: Keys.enabledSubjects)
        }
    }
    
    /// 用户自定义的学科列表
    @Published var customSubjects: [CustomSubject] {
        didSet {
            saveCustomSubjects()
        }
    }
    
    /// 用户启用的自定义学科ID列表
    @Published var enabledCustomSubjectIds: Set<UUID> {
        didSet {
            let idStrings = enabledCustomSubjectIds.map { $0.uuidString }
            saveToLocal(idStrings, forKey: Keys.enabledCustomSubjectIds)
            syncToCloud(idStrings, forKey: Keys.enabledCustomSubjectIds)
        }
    }
    
    // MARK: - Gradient Colors
    
    /// 头像背景渐变色选项
    var gradientColors: [Color] {
        let options: [[Color]] = [
            [Color.brand.primary, Color.brand.secondary],
            [.purple, .pink],
            [.orange, .red],
            [.green, .mint],
            [.blue, .cyan],
            [.indigo, .purple]
        ]
        let index = min(gradientIndex, options.count - 1)
        return options[max(0, index)]
    }
    
    // MARK: - Initialization
    
    private init() {
        // 优先从 iCloud 加载，否则从本地加载
        self.nickname = Self.loadFromCloud(forKey: Keys.nickname) 
            ?? Self.loadFromLocal(forKey: Keys.nickname) 
            ?? String(localized: "profile_nickname")
        
        self.avatar = Self.loadFromCloud(forKey: Keys.avatar) 
            ?? Self.loadFromLocal(forKey: Keys.avatar) 
            ?? "person.fill"
        
        self.gradientIndex = Self.loadFromCloud(forKey: Keys.gradientIndex) 
            ?? Self.loadFromLocal(forKey: Keys.gradientIndex) 
            ?? 0
        
        // 加载学科偏好（如果用户还没设置过，默认为空集合，会在 Onboarding 中设置）
        if let savedRawValues: [String] = Self.loadFromCloud(forKey: Keys.enabledSubjects)
            ?? Self.loadFromLocal(forKey: Keys.enabledSubjects) {
            self.enabledSubjects = Set(savedRawValues.compactMap { Subject(rawValue: $0) })
        } else {
            // 首次使用时为空，在 Onboarding 中由用户选择
            self.enabledSubjects = []
        }
        
        // 加载自定义学科
        self.customSubjects = Self.loadCustomSubjects()
        
        // 加载启用的自定义学科ID
        if let idStrings: [String] = Self.loadFromCloud(forKey: Keys.enabledCustomSubjectIds)
            ?? Self.loadFromLocal(forKey: Keys.enabledCustomSubjectIds) {
            self.enabledCustomSubjectIds = Set(idStrings.compactMap { UUID(uuidString: $0) })
        } else {
            self.enabledCustomSubjectIds = []
        }
        
        // 监听 iCloud 变更
        setupCloudObserver()
    }
    
    // MARK: - Local Storage
    
    private func saveToLocal<T>(_ value: T, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    private static func loadFromLocal<T>(forKey key: String) -> T? {
        UserDefaults.standard.object(forKey: key) as? T
    }
    
    // MARK: - iCloud Storage
    
    private func syncToCloud<T>(_ value: T, forKey key: String) {
        NSUbiquitousKeyValueStore.default.set(value, forKey: key)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    private static func loadFromCloud<T>(forKey key: String) -> T? {
        NSUbiquitousKeyValueStore.default.object(forKey: key) as? T
    }
    
    private func setupCloudObserver() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            // 直接从 iCloud 重新读取数据，避免 Sendable 问题
            Task { @MainActor in
                self?.reloadFromCloud()
            }
        }
        
        // 初始同步
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    private func reloadFromCloud() {
        if let value: String = Self.loadFromCloud(forKey: Keys.nickname) {
            self.nickname = value
        }
        if let value: String = Self.loadFromCloud(forKey: Keys.avatar) {
            self.avatar = value
        }
        if let value: Int = Self.loadFromCloud(forKey: Keys.gradientIndex) {
            self.gradientIndex = value
        }
        if let rawValues: [String] = Self.loadFromCloud(forKey: Keys.enabledSubjects) {
            self.enabledSubjects = Set(rawValues.compactMap { Subject(rawValue: $0) })
        }
        // 重新加载自定义学科
        self.customSubjects = Self.loadCustomSubjects()
        if let idStrings: [String] = Self.loadFromCloud(forKey: Keys.enabledCustomSubjectIds) {
            self.enabledCustomSubjectIds = Set(idStrings.compactMap { UUID(uuidString: $0) })
        }
    }
    
    // MARK: - Custom Subject Storage
    
    private func saveCustomSubjects() {
        if let data = try? JSONEncoder().encode(customSubjects) {
            saveToLocal(data, forKey: Keys.customSubjects)
            syncToCloud(data, forKey: Keys.customSubjects)
        }
    }
    
    private static func loadCustomSubjects() -> [CustomSubject] {
        let data: Data? = loadFromCloud(forKey: Keys.customSubjects)
            ?? loadFromLocal(forKey: Keys.customSubjects)
        guard let data = data,
              let subjects = try? JSONDecoder().decode([CustomSubject].self, from: data) else {
            return []
        }
        return subjects.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    // MARK: - Subject Management
    
    /// 切换学科启用状态
    func toggleSubject(_ subject: Subject) {
        if enabledSubjects.contains(subject) {
            // 至少保留一个学科
            if enabledSubjects.count > 1 {
                enabledSubjects.remove(subject)
            }
        } else {
            enabledSubjects.insert(subject)
        }
    }
    
    /// 检查学科是否启用
    func isSubjectEnabled(_ subject: Subject) -> Bool {
        enabledSubjects.contains(subject)
    }
    
    /// 重置为默认学科
    func resetToDefaultSubjects() {
        enabledSubjects = [.chinese, .math, .english, .physics, .chemistry]
    }
    
    // MARK: - Custom Subject Management
    
    /// 添加自定义学科
    func addCustomSubject(_ subject: CustomSubject) {
        var newSubject = subject
        // 设置排序顺序为当前最大值 + 1
        newSubject.sortOrder = (customSubjects.map { $0.sortOrder }.max() ?? -1) + 1
        customSubjects.append(newSubject)
        // 默认启用新添加的学科
        enabledCustomSubjectIds.insert(newSubject.id)
    }
    
    /// 更新自定义学科
    func updateCustomSubject(_ subject: CustomSubject) {
        if let index = customSubjects.firstIndex(where: { $0.id == subject.id }) {
            var updatedSubject = subject
            updatedSubject.updatedAt = Date()
            customSubjects[index] = updatedSubject
        }
    }
    
    /// 删除自定义学科
    func deleteCustomSubject(id: UUID) {
        customSubjects.removeAll { $0.id == id }
        enabledCustomSubjectIds.remove(id)
    }
    
    /// 切换自定义学科启用状态
    func toggleCustomSubject(_ subject: CustomSubject) {
        if enabledCustomSubjectIds.contains(subject.id) {
            enabledCustomSubjectIds.remove(subject.id)
        } else {
            enabledCustomSubjectIds.insert(subject.id)
        }
    }
    
    /// 检查自定义学科是否启用
    func isCustomSubjectEnabled(_ subject: CustomSubject) -> Bool {
        enabledCustomSubjectIds.contains(subject.id)
    }
    
    /// 获取所有启用的自定义学科
    func enabledCustomSubjects() -> [CustomSubject] {
        customSubjects.filter { enabledCustomSubjectIds.contains($0.id) }
    }
    
    /// 重新排序自定义学科
    func reorderCustomSubjects(_ subjects: [CustomSubject]) {
        var reorderedSubjects = subjects
        for (index, _) in reorderedSubjects.enumerated() {
            reorderedSubjects[index].sortOrder = index
        }
        customSubjects = reorderedSubjects
    }
}
