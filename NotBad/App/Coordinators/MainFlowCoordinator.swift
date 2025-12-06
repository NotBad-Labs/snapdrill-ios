//
//  MainFlowCoordinator.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import Observation

// MARK: - Main Flow State

/// 主流程状态
///
/// 控制主流程中显示哪个界面
enum MainFlowState: Equatable {
    /// Onboarding 引导流程
    case onboarding
    
    /// 主界面（Tab 导航）
    case home
    
    /// 权限请求（相机、通知等）
    case permissionRequest(PermissionType)
}

// MARK: - Permission Type

/// 权限类型
enum PermissionType: String, CaseIterable {
    case camera
    case notifications
    case photoLibrary
    
    var title: LocalizedStringKey {
        switch self {
        case .camera: "permission_camera_title"
        case .notifications: "permission_notifications_title"
        case .photoLibrary: "permission_photo_library_title"
        }
    }
    
    var description: LocalizedStringKey {
        switch self {
        case .camera: "permission_camera_description"
        case .notifications: "permission_notifications_description"
        case .photoLibrary: "permission_photo_library_description"
        }
    }
    
    var icon: String {
        switch self {
        case .camera: "camera.fill"
        case .notifications: "bell.fill"
        case .photoLibrary: "photo.fill"
        }
    }
}

// MARK: - MainFlowCoordinator

/// 主流程协调器
///
/// 管理主流程的状态切换，包括：
/// - Onboarding 引导
/// - 权限请求流程
/// - 主界面切换
///
/// ## 流程顺序
///
/// ```
/// 启动 → Onboarding（首次） → 权限请求（可选） → 主界面
///        ↓
///      已完成 → 直接进入主界面
/// ```
@MainActor
@Observable
final class MainFlowCoordinator {
    
    // MARK: - State
    
    /// 当前流程状态
    var flowState: MainFlowState = .home
    
    /// 是否显示 Onboarding（作为全屏覆盖）
    var showOnboarding: Bool = false
    
    // MARK: - Sub-Coordinators
    
    /// Tab 协调器
    let tabCoordinator: TabCoordinator
    
    /// Onboarding 协调器
    let onboardingCoordinator: OnboardingCoordinator
    
    // MARK: - Constants
    
    private enum UserDefaultsKey {
        static let hasCompletedOnboarding = "has_completed_onboarding"
        static let hasRequestedPermissions = "has_requested_permissions"
    }
    
    // MARK: - Initialization
    
    init(tabCoordinator: TabCoordinator, onboardingCoordinator: OnboardingCoordinator) {
        self.tabCoordinator = tabCoordinator
        self.onboardingCoordinator = onboardingCoordinator
    }
    
    // MARK: - Lifecycle
    
    /// 检查并设置初始状态
    func checkInitialState() {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: UserDefaultsKey.hasCompletedOnboarding)
        
        if !hasCompletedOnboarding {
            showOnboarding = true
        }
    }
    
    /// 完成 Onboarding
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKey.hasCompletedOnboarding)
        showOnboarding = false
        flowState = .home
    }
    
    /// 跳过 Onboarding
    func skipOnboarding() {
        showOnboarding = false
        flowState = .home
    }
    
    /// 请求权限
    func requestPermission(_ type: PermissionType) {
        flowState = .permissionRequest(type)
    }
    
    /// 完成权限请求
    func completePermissionRequest() {
        flowState = .home
    }
    
    /// 重置 Onboarding 状态（用于测试）
    func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.hasCompletedOnboarding)
    }
}

// MARK: - MainFlowView

/// 主流程视图
///
/// 根据 `MainFlowState` 显示不同的界面
struct MainFlowView: View {
    
    // MARK: - Coordinator
    
    @Bindable var coordinator: MainFlowCoordinator
    
    // MARK: - Body
    
    var body: some View {
        TabFlowView(coordinator: coordinator.tabCoordinator)
            .fullScreenCover(isPresented: $coordinator.showOnboarding) {
                OnboardingView {
                    coordinator.completeOnboarding()
                }
            }
            .onAppear {
                coordinator.checkInitialState()
            }
    }
}

// MARK: - Environment Key

private struct MainFlowCoordinatorKey: EnvironmentKey {
    static let defaultValue: MainFlowCoordinator? = nil
}

extension EnvironmentValues {
    var mainFlowCoordinator: MainFlowCoordinator? {
        get { self[MainFlowCoordinatorKey.self] }
        set { self[MainFlowCoordinatorKey.self] = newValue }
    }
}
