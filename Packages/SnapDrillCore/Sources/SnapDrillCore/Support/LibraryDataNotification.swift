//
//  LibraryDataNotification.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  定义资料数据变更的应用级通知名，避免业务层直接依赖 SwiftData 底层通知。
//

import Foundation

public extension Notification.Name {
    /// 资料数据发生写操作后（新增、更新、删除）由业务层主动 post 的通知
    ///
    /// **使用边界**：
    /// - 允许：跨模块大规模数据变更（Settings 清空、DataSeeder 重置）
    /// - 允许：CaptureResultViewModel / LibraryEditViewModel 保存后（临时保留，待 @Query 覆盖后移除）
    /// - 禁止：单体微操作滥用此通知（如仅改一个字段就广播）
    static let libraryDataDidChange = Notification.Name("com.snapdrill.libraryDataDidChange")

    /// 切换到「采集」Tab
    static let switchToCaptureTab  = Notification.Name("com.snapdrill.switchToCaptureTab")
    /// 切换到「资料库」Tab
    static let switchToLibraryTab  = Notification.Name("com.snapdrill.switchToLibraryTab")
    /// 切换到「设置」Tab
    static let switchToSettingsTab = Notification.Name("com.snapdrill.switchToSettingsTab")
}
