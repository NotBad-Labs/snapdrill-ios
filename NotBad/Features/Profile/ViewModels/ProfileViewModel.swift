//
//  ProfileViewModel.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/17/25.
//

import Foundation
import SwiftUI

@MainActor @Observable
class ProfileViewModel {
    
    // MARK: - Properties
    var isLoading = false
    var userProfile = UserProfile()
    var studyStatistics = StudyStatistics()
    var settings = UserSettings()
    
    // 编辑状态
    var isEditingProfile = false
    var tempUserName = ""
    var tempAvatar: Data?
    
    // MARK: - Initialization
    init() {
        loadUserData()
    }
    
    // MARK: - Public Methods
    
    /// 刷新用户数据
    func refresh() async {
        isLoading = true
        
        await loadUserProfile()
        await loadStudyStatistics()
        await loadUserSettings()
        
        isLoading = false
    }
    
    /// 开始编辑个人资料
    func startEditingProfile() {
        isEditingProfile = true
        tempUserName = userProfile.name
    }
    
    /// 保存个人资料
    func saveProfile() async -> Bool {
        guard !tempUserName.isEmpty else {
            return false
        }
        
        isLoading = true
        
        // 模拟保存过程
        try? await Task.sleep(for: .milliseconds(800))
        
        // 更新用户资料
        userProfile.name = tempUserName
        if let avatarData = tempAvatar {
            userProfile.avatarData = avatarData
        }
        
        // TODO: 实际保存到数据库
        print("保存用户资料: \(userProfile.name)")
        
        isEditingProfile = false
        isLoading = false
        return true
    }
    
    /// 取消编辑
    func cancelEditing() {
        isEditingProfile = false
        tempUserName = ""
        tempAvatar = nil
    }
    
    /// 更新设置
    func updateSetting(_ setting: SettingType, value: Any) async {
        switch setting {
        case .studyReminder:
            settings.studyReminderEnabled = value as? Bool ?? false
        case .dataBackup:
            settings.dataBackupEnabled = value as? Bool ?? false
        case .privacyMode:
            settings.privacyModeEnabled = value as? Bool ?? false
        }
        
        // TODO: 保存设置到本地存储
        print("更新设置: \(setting.title) = \(value)")
    }
    
    /// 导出学习数据
    func exportStudyData() async -> Bool {
        isLoading = true
        
        // 模拟导出过程
        try? await Task.sleep(for: .milliseconds(1500))
        
        // TODO: 实际导出逻辑
        print("导出学习数据")
        
        isLoading = false
        return true
    }
    
    /// 清除所有数据
    func clearAllData() async -> Bool {
        isLoading = true
        
        // 模拟清除过程
        try? await Task.sleep(for: .milliseconds(1000))
        
        // TODO: 实际清除逻辑
        print("清除所有数据")
        
        // 重置统计数据
        studyStatistics = StudyStatistics()
        
        isLoading = false
        return true
    }
    
    /// 退出登录
    func logout() {
        // TODO: 实际退出登录逻辑
        print("退出登录")
    }
    
    // MARK: - Private Methods
    
    private func loadUserData() {
        userProfile = UserProfile(
            id: UUID(),
            name: "学习者",
            email: "learner@example.com",
            avatarData: nil,
            joinDate: Calendar.current.date(byAdding: .day, value: -23, to: Date())!,
            studyDays: 23
        )
        
        studyStatistics = StudyStatistics(
            totalQuestions: 156,
            correctAnswers: 122,
            studyHours: 45.5,
            streakDays: 7,
            averageAccuracy: 0.78,
            weakSubjects: ["物理", "化学"],
            strongSubjects: ["数学", "语文"]
        )
        
        settings = UserSettings(
            studyReminderEnabled: true,
            dataBackupEnabled: true,
            privacyModeEnabled: false,
            preferredDifficulty: .中等,
            dailyGoal: 10
        )
    }
    
    private func loadUserProfile() async {
        // 模拟网络请求
        try? await Task.sleep(for: .milliseconds(400))
        
        // 更新用户资料
        userProfile.studyDays = Int.random(in: 20...50)
    }
    
    private func loadStudyStatistics() async {
        // 模拟网络请求
        try? await Task.sleep(for: .milliseconds(600))
        
        // 更新统计数据
        studyStatistics.totalQuestions = Int.random(in: 100...200)
        studyStatistics.correctAnswers = Int.random(in: 80...180)
        studyStatistics.averageAccuracy = Double.random(in: 0.6...0.9)
        studyStatistics.streakDays = Int.random(in: 1...30)
    }
    
    private func loadUserSettings() async {
        // 模拟网络请求
        try? await Task.sleep(for: .milliseconds(200))
        
        // 从本地存储加载设置
        settings.studyReminderEnabled = UserDefaults.standard.bool(forKey: "studyReminderEnabled")
        settings.dataBackupEnabled = UserDefaults.standard.bool(forKey: "dataBackupEnabled")
        settings.privacyModeEnabled = UserDefaults.standard.bool(forKey: "privacyModeEnabled")
    }
}

// MARK: - Supporting Types

struct UserProfile {
    let id: UUID
    var name: String
    var email: String
    var avatarData: Data?
    let joinDate: Date
    var studyDays: Int
    
    init(id: UUID = UUID(), name: String = "", email: String = "", avatarData: Data? = nil, joinDate: Date = Date(), studyDays: Int = 0) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarData = avatarData
        self.joinDate = joinDate
        self.studyDays = studyDays
    }
}

struct StudyStatistics {
    var totalQuestions: Int
    var correctAnswers: Int
    var studyHours: Double
    var streakDays: Int
    var averageAccuracy: Double
    var weakSubjects: [String]
    var strongSubjects: [String]
    
    init(totalQuestions: Int = 0, correctAnswers: Int = 0, studyHours: Double = 0.0, streakDays: Int = 0, averageAccuracy: Double = 0.0, weakSubjects: [String] = [], strongSubjects: [String] = []) {
        self.totalQuestions = totalQuestions
        self.correctAnswers = correctAnswers
        self.studyHours = studyHours
        self.streakDays = streakDays
        self.averageAccuracy = averageAccuracy
        self.weakSubjects = weakSubjects
        self.strongSubjects = strongSubjects
    }
    
    var correctRate: Double {
        guard totalQuestions > 0 else { return 0.0 }
        return Double(correctAnswers) / Double(totalQuestions)
    }
}

struct UserSettings {
    var studyReminderEnabled: Bool
    var dataBackupEnabled: Bool
    var privacyModeEnabled: Bool
    var preferredDifficulty: Difficulty
    var dailyGoal: Int
    
    init(studyReminderEnabled: Bool = false, dataBackupEnabled: Bool = false, privacyModeEnabled: Bool = false, preferredDifficulty: Difficulty = .中等, dailyGoal: Int = 10) {
        self.studyReminderEnabled = studyReminderEnabled
        self.dataBackupEnabled = dataBackupEnabled
        self.privacyModeEnabled = privacyModeEnabled
        self.preferredDifficulty = preferredDifficulty
        self.dailyGoal = dailyGoal
    }
}

enum SettingType {
    case studyReminder
    case dataBackup
    case privacyMode
    
    var title: String {
        switch self {
        case .studyReminder: return "学习提醒"
        case .dataBackup: return "数据备份"
        case .privacyMode: return "隐私模式"
        }
    }
    
    var icon: String {
        switch self {
        case .studyReminder: return "bell.fill"
        case .dataBackup: return "icloud.fill"
        case .privacyMode: return "lock.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .studyReminder: return .orange
        case .dataBackup: return .blue
        case .privacyMode: return .purple
        }
    }
}