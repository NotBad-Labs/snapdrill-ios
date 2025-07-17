//
//  TabCoordinator.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/17/25.
//

import Foundation
import SwiftUI

/// Tab导航协调器 - 管理主Tab导航
@MainActor @Observable
class TabCoordinator {
    
    // MARK: - Tab Definition
    enum Tab: String, CaseIterable {
        case home = "home"
        case practice = "practice"
        case addQuestion = "addQuestion"
        case discover = "discover"
        case profile = "profile"
        
        var title: String {
            switch self {
            case .home: return "首页"
            case .practice: return "练习"
            case .addQuestion: return "拍照"
            case .discover: return "发现"
            case .profile: return "我的"
            }
        }
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .practice: return "brain.head.profile"
            case .addQuestion: return "camera.fill"
            case .discover: return "safari.fill"
            case .profile: return "person.fill"
            }
        }
    }
    
    // MARK: - Navigation State
    var selectedTab: Tab = .home
    
    // MARK: - Presentation State
    var showingCamera: Bool = false
    var showingOCREditor: Bool = false
    var showingSettings: Bool = false
    
    // MARK: - Navigation Methods
    
    /// 切换到指定Tab
    func switchToTab(_ tab: Tab) {
        selectedTab = tab
    }
    
    /// 显示拍照界面
    func presentCamera() {
        showingCamera = true
    }
    
    /// 显示OCR编辑界面
    func presentOCREditor() {
        showingOCREditor = true
    }
    
    /// 显示设置界面
    func presentSettings() {
        showingSettings = true
    }
    
    /// 重置所有presentation状态
    func resetPresentationState() {
        showingCamera = false
        showingOCREditor = false
        showingSettings = false
    }
    
    /// 处理Tab特定的深链接
    func handleTabDeepLink(_ url: URL) {
        // 处理特定Tab的深链接
        // 例如：notbad://practice/mistake-book
    }
}