//
//  AppRouter.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/17/25.
//


//
//  AppRouter.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/17/25.
//

import Foundation
import SwiftUI

/// 应用级路由器 - 管理应用的主要流程
@MainActor @Observable
class AppRouter {
    
    // MARK: - App Flow Definition
    enum AppFlow {
        case onboarding    // 引导流程
        case authentication // 认证流程
        case main          // 主应用流程
    }
    
    // MARK: - State
    var currentFlow: AppFlow = .main
    
    // MARK: - Navigation Methods
    
    /// 确定初始流程
    func determineInitialFlow() {
        // 检查用户是否首次使用
        if UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
            // 检查用户是否已登录
            if AuthenticationService.shared.isAuthenticated {
                currentFlow = .main
            } else {
                currentFlow = .authentication
            }
        } else {
            currentFlow = .onboarding
        }
    }
    
    /// 完成引导流程
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        currentFlow = .authentication
    }
    
    /// 完成认证流程
    func completeAuthentication() {
        currentFlow = .main
    }
    
    /// 退出登录
    func logout() {
        AuthenticationService.shared.logout()
        currentFlow = .authentication
    }
    
    /// 重置应用状态
    func resetToOnboarding() {
        UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
        currentFlow = .onboarding
    }
}