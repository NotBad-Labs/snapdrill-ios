//
//  AppState.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class AppState {
    // 全局应用状态
    var isLoading = false
    var currentUser: User?
    var showOnboarding = false
    
    // 导航状态
    var selectedTab: MainTab = .home
    
    init() {
        checkOnboardingStatus()
    }
    
    private func checkOnboardingStatus() {
        // 检查是否需要显示引导页面
        showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}

enum MainTab: String, CaseIterable {
    case home = "home"
    case practice = "practice"
    case addQuestion = "addQuestion"
    case discovery = "discovery"
    case profile = "profile"
}
