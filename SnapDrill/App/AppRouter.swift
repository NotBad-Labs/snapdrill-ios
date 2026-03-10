//
//  AppRouter.swift
//  SnapDrill
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  应用层级路由管理，定义一级 Tab 和全局导航状态
//

import SwiftUI
import Observation
import UIKit
import SnapDrillFeatureCapture
import SnapDrillFeatureLibrary
import SnapDrillFeatureReview
import SnapDrillFeatureDashboard
import SnapDrillFeatureSettings

/// 应用的一级导航标签
enum AppTab: Hashable {
    /// 首页看板
    case dashboard
    /// 题库浏览
    case library
    /// 题目采集
    case capture
    /// 复习计划
    case review
    /// 系统设置
    case settings
}

/// 应用层级路由器
///
/// 负责管理一级 Tab 切换和各功能模块的子路由。
@MainActor
@Observable
final class AppRouter {
    
    // MARK: - Properties
    
    /// 当前选中的 Tab
    var selectedTab: AppTab = .dashboard
    
    /// 首页模块路由
    let dashboardRouter = DashboardRouter()
    /// 题库模块路由
    let libraryRouter = LibraryRouter()
    /// 采集模块路由
    let captureRouter = CaptureRouter()
    /// 复习模块路由
    let reviewRouter = ReviewRouter()
    /// 设置模块路由
    let settingsRouter = SettingsRouter()
    
    // MARK: - Initialization
    
    /// 初始化并设立绑定
    init() {
        dashboardRouter.onNavigateToReview = { [weak self] in
            self?.selectedTab = .review
        }
        
        dashboardRouter.onNavigateToCapture = { [weak self] draft in
            withAnimation(.spring(duration: 0.4)) {
                self?.selectedTab = .capture
            }
            if let draft = draft {
                self?.captureRouter.restoreDraft(draft)
            }
        }
        
        reviewRouter.onNavigateToLibrary = { [weak self] in
            self?.selectedTab = .library
        }
        
        reviewRouter.onNavigateToCapture = { [weak self] in
            self?.selectedTab = .capture
        }
    }

    // MARK: - Public API

    /// App Groups 共享容器标识符
    private static let appGroupID = "group.com.snapdrill.app"
    /// 待处理图片在共享容器中的文件名（与 ShareViewController 一致）
    private static let pendingFileName = "pending_share.jpg"

    /// 处理 Share Extension 传入的深链接
    ///
    /// 从 App Groups 共享容器读取待处理图片，切换到采集 Tab 并进入 OCR 编辑流程。
    /// 处理完成后自动清理临时文件。
    func handleShareExtensionURL() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupID
        ) else { return }

        let pendingURL = containerURL.appendingPathComponent(Self.pendingFileName)
        guard FileManager.default.fileExists(atPath: pendingURL.path),
              let data = try? Data(contentsOf: pendingURL),
              let image = UIImage(data: data) else { return }

        // 清理临时文件
        try? FileManager.default.removeItem(at: pendingURL)

        // 切换到采集 Tab，重置导航栈后推入编辑页
        selectedTab = .capture
        captureRouter.path = NavigationPath()
        captureRouter.push(.scannerResult(content: "", image: image))
    }
}
