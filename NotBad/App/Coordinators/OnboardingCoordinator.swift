//
//  OnboardingCoordinator.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import Foundation
import Observation

// MARK: - OnboardingCoordinator

/// Onboarding 流程协调器
///
/// 负责管理首次启动引导流程的状态。
@MainActor
@Observable
final class OnboardingCoordinator {
    
    // MARK: - Constants
    
    private enum UserDefaultsKey {
        static let hasCompletedOnboarding = "has_completed_onboarding"
    }
    
    // MARK: - State
    
    /// 是否显示 Onboarding
    var showOnboarding: Bool = false
    
    /// 是否已完成 Onboarding
    var hasCompleted: Bool {
        UserDefaults.standard.bool(forKey: UserDefaultsKey.hasCompletedOnboarding)
    }
    
    // MARK: - Actions
    
    /// 检查是否需要显示 Onboarding
    func checkStatus() {
        if !hasCompleted {
            showOnboarding = true
        }
    }
    
    /// 标记 Onboarding 完成
    func complete() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKey.hasCompletedOnboarding)
        showOnboarding = false
    }
    
    /// 关闭 Onboarding（不标记完成，用于手动关闭）
    func dismiss() {
        showOnboarding = false
    }
    
    /// 重置 Onboarding 状态（用于测试）
    func reset() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.hasCompletedOnboarding)
        showOnboarding = false
    }
}
