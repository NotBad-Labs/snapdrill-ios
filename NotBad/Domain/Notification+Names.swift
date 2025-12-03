//
//  Notification+Names.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import Foundation

// MARK: - Notification Names

/// 应用通知名称定义
///
/// 集中管理应用内的通知名称，避免字符串硬编码。
///
/// ## 使用示例
///
/// ```swift
/// // 发送通知
/// NotificationCenter.default.post(name: .reviewItemAdded, object: newItem)
///
/// // 监听通知
/// NotificationCenter.default.addObserver(
///     forName: .reviewItemAdded,
///     object: nil,
///     queue: .main
/// ) { notification in
///     // 处理通知
/// }
/// ```
extension Notification.Name {

    // MARK: - App Lifecycle

    /// 应用进入后台
    static let appDidEnterBackground = Notification.Name("notbad.app.didEnterBackground")

    /// 应用进入前台
    static let appDidBecomeActive = Notification.Name("notbad.app.didBecomeActive")

    /// 应用即将终止
    static let appWillTerminate = Notification.Name("notbad.app.willTerminate")

    // MARK: - Review Item Events

    /// 错题已添加
    ///
    /// `object` 为新添加的 `ReviewItem`
    static let reviewItemAdded = Notification.Name("notbad.reviewItem.added")

    /// 错题已更新
    ///
    /// `object` 为更新后的 `ReviewItem`
    static let reviewItemUpdated = Notification.Name("notbad.reviewItem.updated")

    /// 错题已删除
    ///
    /// `object` 为被删除的 `ReviewItem` 的 ID (UUID)
    static let reviewItemDeleted = Notification.Name("notbad.reviewItem.deleted")

    /// 错题批量删除完成
    ///
    /// `userInfo` 包含 `count` (Int) 表示删除数量
    static let reviewItemsBatchDeleted = Notification.Name("notbad.reviewItem.batchDeleted")

    /// 错题数据已变更（用于 Widget 同步）
    ///
    /// 触发 Widget 数据刷新
    static let reviewItemsDidChange = Notification.Name("notbad.reviewItem.didChange")

    // MARK: - Review Session Events

    /// 复习会话开始
    static let reviewSessionStarted = Notification.Name("notbad.review.sessionStarted")

    /// 复习会话完成
    ///
    /// `userInfo` 包含 `statistics` (ReviewSessionStatistics)
    static let reviewSessionCompleted = Notification.Name("notbad.review.sessionCompleted")

    /// 复习会话取消
    static let reviewSessionCancelled = Notification.Name("notbad.review.sessionCancelled")

    // MARK: - Live Scanner Events

    /// 实时扫描完成请求
    static let liveScannerFinishRequest = Notification.Name("notbad.scanner.finishRequest")

    /// 实时扫描完成响应
    ///
    /// `object` 为识别的文本 (String)
    static let liveScannerFinishResponse = Notification.Name("notbad.scanner.finishResponse")

    // MARK: - Data Sync Events

    /// 数据同步开始
    static let dataSyncStarted = Notification.Name("notbad.sync.started")

    /// 数据同步完成
    static let dataSyncCompleted = Notification.Name("notbad.sync.completed")

    /// 数据同步失败
    ///
    /// `userInfo` 包含 `error` (Error)
    static let dataSyncFailed = Notification.Name("notbad.sync.failed")

    // MARK: - Settings Events

    /// 设置已更改
    ///
    /// `userInfo` 包含 `key` (String) 和 `value` (Any)
    static let settingsChanged = Notification.Name("notbad.settings.changed")

    /// 主题已更改
    static let themeChanged = Notification.Name("notbad.settings.themeChanged")
    
    // MARK: - Navigation Events
    
    /// 切换到录入页面
    ///
    /// 从其他页面触发，导航到 Capture Tab
    static let switchToCapture = Notification.Name("notbad.navigation.switchToCapture")
    
    /// 切换到复习页面
    static let switchToReview = Notification.Name("notbad.navigation.switchToReview")
    
    /// 切换到题库页面
    static let switchToLibrary = Notification.Name("notbad.navigation.switchToLibrary")
}

// MARK: - Notification UserInfo Keys

/// 通知 userInfo 键定义
enum NotificationUserInfoKey {
    /// 数量
    static let count = "count"

    /// 错误
    static let error = "error"

    /// 设置键
    static let key = "key"

    /// 设置值
    static let value = "value"

    /// 统计数据
    static let statistics = "statistics"
}
