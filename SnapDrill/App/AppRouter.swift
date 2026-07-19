//
//  AppRouter.swift
//  SnapDrill
//
//  Created by NotBad Labs.
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
    private let captureDraftService: CaptureDraftServiceProtocol
    var shareImportErrorMessage: String?
    
    // MARK: - Initialization
    
    /// 初始化并设立绑定
    init(captureDraftService: CaptureDraftServiceProtocol) {
        self.captureDraftService = captureDraftService
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
    private static let appGroupID = "group.com.snapdrill.global"

    /// 处理 Share Extension 传入的深链接
    ///
    /// 从 URL 参数中解析文件名，在 App Groups 共享容器中读取对应图片，
    /// 切换到采集 Tab 并进入 OCR 编辑流程。处理完成后自动清理临时文件。
    ///
    /// - Parameter url: 深链接 URL，格式为 `snapdrill://share?file=<UUID>.jpg`
    func handleShareExtensionURL(_ url: URL) {
        // 解析文件名参数
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let fileName = components.queryItems?.first(where: { $0.name == "file" })?.value,
              !fileName.isEmpty else {
            reportShareImportFailure("Share Extension URL 缺少 file 参数: \(url.absoluteString)")
            return
        }
        guard Self.isValidShareFileName(fileName) else {
            reportShareImportFailure("Share Extension URL 包含非法 file 参数: \(fileName)")
            return
        }

        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupID
        ) else {
            reportShareImportFailure("无法获取 App Groups 共享容器路径")
            return
        }

        let pendingURL = containerURL.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: pendingURL.path) else {
            reportShareImportFailure("Share Extension 文件不存在（可能被系统清理）: \(fileName)")
            return
        }
        let data: Data
        do {
            data = try Data(contentsOf: pendingURL)
        } catch {
            reportShareImportFailure(
                "Share Extension 文件读取失败: \(fileName) - \(error.localizedDescription)"
            )
            return
        }
        guard let image = UIImage(data: data) else {
            reportShareImportFailure(
                "Share Extension 图片解码失败: \(fileName)（data size: \(data.count) bytes）"
            )
            return
        }

        Task {
            await persistSharedImage(image, sourceURL: pendingURL)
        }
    }

    private func persistSharedImage(_ image: UIImage, sourceURL: URL) async {
        let token: CaptureDraftToken
        do {
            token = try await captureDraftService.saveDraft(
                image: image,
                content: "",
                category: nil,
                captureID: nil,
                expected: nil
            )
        } catch {
            // Keep the App Group source intact so a failed handoff is retryable.
            reportShareImportFailure(
                "Share Extension durable handoff failed: \(error.localizedDescription)"
            )
            return
        }
        do {
            try FileManager.default.removeItem(at: sourceURL)
        } catch {
            SnapDrillLogger.capture.warning(
                "Share Extension source cleanup deferred: \(error.localizedDescription)"
            )
        }
        // 先切换 Tab 并重置导航栈，延迟一个 RunLoop 周期后再 push，
        // 避免 Tab 切换动画与导航 push 在同一帧竞争导致 push 丢失
        selectedTab = .capture
        captureRouter.path = NavigationPath()
        // best-effort: 等待 Tab 切换动画完成，取消不影响正确性
        try? await Task.sleep(for: .milliseconds(100))
        captureRouter.push(
            .scannerResult(
                content: "",
                image: image,
                draftToken: token
            )
        )
    }

    private func reportShareImportFailure(_ logMessage: String) {
        selectedTab = .capture
        shareImportErrorMessage = L10n.AppRoot.shareImportFailed
        SnapDrillLogger.capture.error("\(logMessage)")
    }

    private static func isValidShareFileName(_ fileName: String) -> Bool {
        guard !fileName.isEmpty else { return false }
        guard !fileName.contains(".."),
              !fileName.contains("/"),
              !fileName.contains("\\"),
              !fileName.contains("\0") else {
            return false
        }
        return true
    }
}
