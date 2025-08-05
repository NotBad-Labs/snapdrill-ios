// MARK: - AppState.swift
/**
 * 全局应用状态管理器
 * 
 * 职责：
 * - 管理应用生命周期状态（启动页、引导页、主界面）
 * - 维护用户登录状态和配置文件
 * - 处理应用设置的状态同步
 * - 提供状态持久化能力
 * 
 * 设计原则：
 * - 使用 @Observable 宏实现响应式状态管理
 * - 所有状态变更都在 @MainActor 上下文中执行
 * - 状态持久化通过 UserDefaults 实现
 * 
 * 使用方式：
 * ```swift
 * @EnvironmentObject private var appState: AppState
 * 
 * // 状态读取
 * if appState.isUserLoggedIn { ... }
 * 
 * // 状态变更
 * appState.transitionTo(.main)
 * ```
 * 
 * 注意事项：
 * - 该类为单例模式，整个应用只应有一个实例
 * - 所有公开方法都是线程安全的（@MainActor 保证）
 * - 状态变更会自动触发 UI 更新
 * 
 * @author NotBad Team
 * @since 1.0.0
 * @updated 2025-08-01
 */

import SwiftUI
import Observation

@Observable
@MainActor
class AppState {
    
    // MARK: - 类型定义
    
    /**
     * 应用主要流程状态枚举
     * 
     * 描述应用在不同阶段的状态，用于驱动根视图的显示逻辑
     */
    enum AppFlow: Equatable {
        case splash      /// 启动页：显示 Logo 和初始化进度
        case onboarding  /// 引导页：首次使用的功能介绍
        case main        /// 主界面：应用的核心功能界面
    }
    
    /**
     * 引导页步骤枚举
     * 
     * 定义用户首次使用应用时的引导流程步骤
     */
    enum OnboardingStep: CaseIterable {
        case welcome     /// 欢迎页面
        case features    /// 功能介绍
        case permissions /// 权限申请
        case completed   /// 引导完成
    }
    
    // MARK: - 应用流程状态
    
    /// 当前应用流程状态，默认为启动页
    var currentFlow: AppFlow = .splash
    
    /// 当前引导页步骤，仅在 currentFlow 为 .onboarding 时有效
    var onboardingStep: OnboardingStep = .welcome
    
    /// 是否为首次启动应用，用于决定是否显示引导页
    var isFirstLaunch: Bool = true
    
    // MARK: - 用户状态
    
    /// 用户是否已登录，影响部分功能的可用性
    var isUserLoggedIn: Bool = false
    
    /// 当前登录用户的 ID，用于数据关联和权限控制
    var userId: String?
    
    /// 用户配置文件，包含用户的基本信息和偏好设置
    var userProfile: UserProfile?
    
    // MARK: - 应用设置状态
    
    /// 是否启用深色模式，影响整个应用的主题
    var isDarkModeEnabled: Bool = false
    
    /// 选择的语言代码，用于国际化显示
    var selectedLanguage: String = "zh-Hans"
    
    /// 是否启用推送通知
    var notificationsEnabled: Bool = true
    
    // MARK: - 加载状态
    
    /// 应用是否正在初始化中，用于控制启动页的显示
    var isInitializing: Bool = true
    
    /// 初始化过程中发生的错误，用于错误处理和用户提示
    var initializationError: Error?
    
    // MARK: - 初始化
    
    /**
     * 初始化应用状态
     * 
     * 从持久化存储中加载之前保存的状态，确保应用重启后状态的连续性
     */
    init() {
        loadPersistedState()
    }
    
    // MARK: - 公开方法 - 流程控制
    
    /**
     * 切换到指定的应用流程状态
     * 
     * 该方法会自动添加过渡动画，提供流畅的用户体验
     * 
     * @param flow 目标流程状态
     * 
     * 使用示例：
     * ```swift
     * appState.transitionTo(.main)  // 切换到主界面
     * ```
     */
    func transitionTo(_ flow: AppFlow) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentFlow = flow
        }
    }
    
    /**
     * 完成引导流程
     * 
     * 标记用户已完成首次引导，更新首次启动标记，
     * 持久化状态，并自动切换到主界面
     * 
     * 调用时机：用户完成所有引导步骤后
     */
    func completeOnboarding() {
        isFirstLaunch = false
        persistState()
        transitionTo(.main)
    }
    
    /**
     * 进入下一个引导步骤
     * 
     * 如果还有更多步骤，则进入下一步；
     * 如果已是最后一步，则自动完成引导流程
     * 
     * 使用示例：
     * ```swift
     * Button("下一步") {
     *     appState.nextOnboardingStep()
     * }
     * ```
     */
    func nextOnboardingStep() {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: onboardingStep),
              currentIndex < OnboardingStep.allCases.count - 1 else {
            completeOnboarding()
            return
        }
        
        onboardingStep = OnboardingStep.allCases[currentIndex + 1]
    }
    
    // MARK: - 公开方法 - 用户管理
    
    /**
     * 设置用户配置文件
     * 
     * 当用户登录成功后调用，会自动更新登录状态和用户 ID，
     * 并持久化相关状态信息
     * 
     * @param profile 用户配置文件对象
     * 
     * 使用示例：
     * ```swift
     * let profile = UserProfile(id: "123", name: "张三", ...)
     * appState.setUserProfile(profile)
     * ```
     */
    func setUserProfile(_ profile: UserProfile) {
        userProfile = profile
        userId = profile.id
        isUserLoggedIn = true
        persistState()
    }
    
    /**
     * 用户登出
     * 
     * 清除所有用户相关状态，包括配置文件、用户 ID 和登录状态，
     * 并持久化变更
     * 
     * 使用示例：
     * ```swift
     * Button("退出登录") {
     *     appState.logout()
     * }
     * ```
     */
    func logout() {
        userProfile = nil
        userId = nil
        isUserLoggedIn = false
        persistState()
    }
    
    // MARK: - 公开方法 - 初始化控制
    
    /**
     * 完成应用初始化
     * 
     * 由 AppCoordinator 在初始化任务完成后调用，
     * 会根据 isFirstLaunch 状态决定显示引导页还是主界面
     * 
     * 注意：该方法应该只被 AppCoordinator 调用
     */
    func finishInitialization() {
        isInitializing = false
        
        if isFirstLaunch {
            transitionTo(.onboarding)
        } else {
            transitionTo(.main)
        }
    }
    
    /**
     * 设置初始化错误
     * 
     * 当初始化过程中发生错误时调用，会停止初始化状态
     * 并保存错误信息用于错误处理
     * 
     * @param error 初始化过程中发生的错误
     * 
     * 注意：该方法应该只被 AppCoordinator 调用
     */
    func setInitializationError(_ error: Error) {
        initializationError = error
        isInitializing = false
    }
    
    // MARK: - 私有方法 - 状态持久化
    
    /**
     * 从 UserDefaults 加载持久化状态
     * 
     * 在初始化时调用，恢复上次保存的用户设置和状态
     * 如果是首次安装，会使用默认值
     */
    private func loadPersistedState() {
        // 加载应用状态
        isFirstLaunch = UserDefaults.standard.object(forKey: "isFirstLaunch") as? Bool ?? true
        
        // 加载应用设置
        isDarkModeEnabled = UserDefaults.standard.bool(forKey: "isDarkModeEnabled")
        selectedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "zh-Hans"
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        
        // 加载用户状态
        if let userIdString = UserDefaults.standard.string(forKey: "userId") {
            userId = userIdString
            isUserLoggedIn = true
        }
    }
    
    /**
     * 将当前状态持久化到 UserDefaults
     * 
     * 保存用户设置和关键状态信息，确保应用重启后状态的连续性
     * 
     * 注意：用户配置文件对象本身不在此持久化，
     * 应该通过专门的用户仓储进行管理
     */
    private func persistState() {
        // 保存应用状态
        UserDefaults.standard.set(isFirstLaunch, forKey: "isFirstLaunch")
        
        // 保存应用设置
        UserDefaults.standard.set(isDarkModeEnabled, forKey: "isDarkModeEnabled")
        UserDefaults.standard.set(selectedLanguage, forKey: "selectedLanguage")
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        
        // 保存用户状态
        if let userId = userId {
            UserDefaults.standard.set(userId, forKey: "userId")
        } else {
            UserDefaults.standard.removeObject(forKey: "userId")
        }
    }
}

// MARK: - 支持类型

/**
 * 用户配置文件数据模型
 * 
 * 表示系统中的用户基本信息，实现 Codable 以支持序列化，
 * 实现 Identifiable 以支持 SwiftUI 列表渲染
 * 
 * @property id 用户唯一标识符
 * @property name 用户显示名称
 * @property email 用户邮箱地址
 * @property createdAt 账户创建时间
 * @property updatedAt 最后更新时间
 */
struct UserProfile: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let createdAt: Date
    let updatedAt: Date
}