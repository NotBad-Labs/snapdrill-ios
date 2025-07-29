//
//  AppFlow.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/7/29.
//


import Foundation

// MARK: - 应用流程定义
// 位置: App/Navigation/AppFlow.swift

/// 应用级别的导航路由
enum AppFlow {
    case splash
    case onboarding
    case authentication
    case mainFlow
}

/// 主Tab的路由
enum MainTabFlow {
    case dashboard
    case questionManagement
    case studyPractice
    case discovery
    case userProfile
}

/// Dashboard模块的路由
enum DashboardFlow {
    case home
    case weatherDetail
    case studyStatsDetail
    case recommendationDetail
}

/// 题目管理模块的路由
enum QuestionManagementFlow {
    case home
    case cameraCapture
    case ocrReview
    case manualInput
    case fileImport
    case questionPreview
    case questionDetail(questionID: String)
    case questionEdit(questionID: String)
}

/// 学习练习模块的路由
enum StudyPracticeFlow {
    case home
    case modeSelection
    case studySession
    case questionPractice
    case studyResult
    case studyHistory
    case performanceAnalysis
}

/// 发现模块的路由
enum DiscoveryFlow {
    case home
    case search
    case searchResults(query: String)
    case trending
    case recommendations
    case categories
    case feedItemDetail(itemID: String)
}

/// 用户资料模块的路由
enum UserProfileFlow {
    case home
    case editProfile
    case settings
    case notificationSettings
    case privacySettings
    case statistics
    case achievements
    case dataExport
    case helpCenter
    case about
}

/// 认证流程的路由
enum AuthenticationFlow {
    case login
    case register
    case forgotPassword
    case resetPassword
    case verificationCode
    case biometricSetup
}

/// 引导流程的路由
enum OnboardingFlow {
    case welcome
    case featureIntro
    case permissionRequest
    case initialSetup
}

// MARK: - Tab配置

/// Tab项的配置
struct TabConfiguration {
    let flow: MainTabFlow
    let title: String
    let icon: String
    let selectedIcon: String
    
    static let allTabs: [TabConfiguration] = [
        TabConfiguration(
            flow: .dashboard,
            title: "首页",
            icon: "house",
            selectedIcon: "house.fill"
        ),
        TabConfiguration(
            flow: .questionManagement,
            title: "录题",
            icon: "plus.circle",
            selectedIcon: "plus.circle.fill"
        ),
        TabConfiguration(
            flow: .studyPractice,
            title: "练习",
            icon: "book",
            selectedIcon: "book.fill"
        ),
        TabConfiguration(
            flow: .discovery,
            title: "发现",
            icon: "magnifyingglass.circle",
            selectedIcon: "magnifyingglass.circle.fill"
        ),
        TabConfiguration(
            flow: .userProfile,
            title: "我的",
            icon: "person.circle",
            selectedIcon: "person.circle.fill"
        )
    ]
}