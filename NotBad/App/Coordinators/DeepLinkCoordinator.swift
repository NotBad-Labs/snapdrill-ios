//
//  DeepLinkCoordinator.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import Foundation
import OSLog

// MARK: - DeepLinkCoordinator

/// Deep Link 路由协调器
///
/// 负责处理来自 Widget、通知或外部应用的 URL Scheme 跳转。
///
/// ## 支持的 URL Scheme
///
/// - `notbad://review` - 导航到复习页面
/// - `notbad://library` - 导航到错题库
/// - `notbad://capture` - 导航到拍照录入
/// - `notbad://dashboard` - 导航到首页
/// - `notbad://profile` - 导航到个人中心
/// - `notbad://item/{id}` - 导航到指定错题详情
@MainActor
@Observable
final class DeepLinkCoordinator {
    
    // MARK: - Constants
    
    private enum Scheme {
        static let notbad = "notbad"
    }
    
    private enum Host: String {
        case review
        case library
        case capture
        case dashboard
        case profile
        case item
    }
    
    // MARK: - Dependencies
    
    private let tabCoordinator: TabCoordinator
    
    // MARK: - Initialization
    
    init(tabCoordinator: TabCoordinator) {
        self.tabCoordinator = tabCoordinator
    }
    
    // MARK: - Actions
    
    /// 处理 Deep Link URL
    ///
    /// - Parameter url: 待处理的 URL
    /// - Returns: 是否成功处理
    @discardableResult
    func handle(_ url: URL) -> Bool {
        guard url.scheme == Scheme.notbad else {
            Logger.app.warning("⚠️ 未知的 URL Scheme: \(url.scheme ?? "nil")")
            return false
        }
        
        guard let hostString = url.host,
              let host = Host(rawValue: hostString) else {
            Logger.app.warning("⚠️ 未知的 Deep Link host: \(url.host ?? "nil")")
            return false
        }
        
        switch host {
        case .item:
            // 处理 notbad://item/{uuid}
            if let itemIdString = url.pathComponents.dropFirst().first,
               let itemId = UUID(uuidString: itemIdString) {
                tabCoordinator.navigateToItemDetail(itemId: itemId)
                Logger.app.debug("✅ Deep Link 导航到错题: \(itemId)")
            }
            return true
            
        case .review:
            tabCoordinator.selectTab(.review)
        case .library:
            tabCoordinator.selectTab(.library)
        case .capture:
            tabCoordinator.selectTab(.capture)
        case .dashboard:
            tabCoordinator.selectTab(.dashboard)
        case .profile:
            tabCoordinator.selectTab(.profile)
        }
        
        Logger.app.debug("✅ Deep Link 导航: \(url.absoluteString)")
        return true
    }
}
