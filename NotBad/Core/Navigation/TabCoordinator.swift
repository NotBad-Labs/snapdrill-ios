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
        
        var color: Color {
            switch self {
            case .home: return .blue
            case .practice: return .green
            case .addQuestion: return .blue
            case .discover: return .purple
            case .profile: return .orange
            }
        }
    }
    
    // MARK: - Navigation State
    var selectedTab: Tab = .home
    
    // MARK: - Presentation State
    var showingCamera: Bool = false
    var showingOCREditor: Bool = false
    var showingSettings: Bool = false
    var showingQuestionDetail: Bool = false
    
    // MARK: - Data State
    var selectedQuestionID: UUID?
    var ocrImage: UIImage?
    
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
    func presentOCREditor(with image: UIImage) {
        ocrImage = image
        showingOCREditor = true
    }
    
    /// 显示设置界面
    func presentSettings() {
        showingSettings = true
    }
    
    /// 显示题目详情
    func presentQuestionDetail(questionID: UUID) {
        selectedQuestionID = questionID
        showingQuestionDetail = true
    }
    
    /// 重置所有presentation状态
    func resetPresentationState() {
        showingCamera = false
        showingOCREditor = false
        showingSettings = false
        showingQuestionDetail = false
        selectedQuestionID = nil
        ocrImage = nil
    }
    
    /// 处理Tab特定的深链接
    func handleTabDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else { return }
        
        switch host {
        case "practice":
            selectedTab = .practice
            if let path = components.path.components(separatedBy: "/").last {
                handlePracticeDeepLink(path)
            }
        case "question":
            if let questionIDString = components.path.components(separatedBy: "/").last,
               let questionID = UUID(uuidString: questionIDString) {
                presentQuestionDetail(questionID: questionID)
            }
        case "add":
            selectedTab = .addQuestion
            presentCamera()
        default:
            selectedTab = .home
        }
    }
    
    /// 处理应用内导航
    func handleAppNavigation(_ action: AppNavigationAction) {
        switch action {
        case .openCamera:
            selectedTab = .addQuestion
            presentCamera()
        case .openPractice(let mode):
            selectedTab = .practice
            // TODO: 设置练习模式
        case .openQuestionDetail(let questionID):
            presentQuestionDetail(questionID: questionID)
        case .openSettings:
            presentSettings()
        }
    }
    
    // MARK: - Private Methods
    
    private func handlePracticeDeepLink(_ path: String) {
        switch path {
        case "mistake-book":
            // TODO: 跳转到错题本
            break
        case "random-test":
            // TODO: 启动随机测验
            break
        default:
            break
        }
    }
}

// MARK: - Supporting Types

enum AppNavigationAction {
    case openCamera
    case openPractice(mode: String)
    case openQuestionDetail(questionID: UUID)
    case openSettings
}