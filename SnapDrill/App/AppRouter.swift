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
import SnapDrillCore
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

    /// 处理 Share Extension 传入的深链接
    ///
    /// 从 URL 参数中解析文件名，在 App Groups 共享容器中读取对应图片，
    /// 切换到采集 Tab 并进入 OCR 编辑流程。处理完成后自动清理临时文件。
    ///
    /// 图片读取与解码在后台线程执行，避免大图阻塞主线程。
    ///
    /// - Parameter url: 深链接 URL，格式为 `snapdrill://share?file=<UUID>.jpg`
    func handleShareExtensionURL(_ url: URL) {
        // 解析文件名参数
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let fileName = components.queryItems?.first(where: { $0.name == "file" })?.value,
              !fileName.isEmpty else {
            SnapDrillLogger.capture.error("Share Extension URL 缺少 file 参数: \(url.absoluteString)")
            return
        }

        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupID
        ) else {
            SnapDrillLogger.capture.error("无法获取 App Groups 共享容器路径")
            return
        }

        let pendingURL = containerURL.appendingPathComponent(fileName)

        // 在后台线程读取文件和解码图片，避免大图阻塞主线程
        let captureRouter = self.captureRouter
        Task.detached {
            guard FileManager.default.fileExists(atPath: pendingURL.path) else {
                SnapDrillLogger.capture.error("共享容器中图片文件不存在: \(fileName)")
                return
            }

            let data: Data
            do {
                data = try Data(contentsOf: pendingURL)
            } catch {
                SnapDrillLogger.capture.error("读取共享容器图片文件失败（\(fileName)）: \(error.localizedDescription)")
                return
            }

            guard let image = UIImage(data: data) else {
                SnapDrillLogger.capture.error("共享容器图片解码失败: \(fileName)")
                return
            }

            // best-effort: 临时文件清理，失败不影响功能
            do {
                try FileManager.default.removeItem(at: pendingURL)
            } catch {
                SnapDrillLogger.capture.warning("清理 Share Extension 临时文件失败（\(fileName)）: \(error.localizedDescription)")
            }

            // 回到主线程做路由切换
            await MainActor.run {
                self.selectedTab = .capture
                captureRouter.path = NavigationPath()
            }

            // 等待 Tab 切换动画完成后再 push，避免动画竞争导致 push 丢失
            try? await Task.sleep(for: .milliseconds(100))

            await MainActor.run {
                captureRouter.push(.scannerResult(content: "", image: image))
            }
        }
    }
}
