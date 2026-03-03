//
//  ReviewDataNotification.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/02/28.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  定义题目数据变更的应用级通知名，避免业务层直接依赖 SwiftData 底层通知。
//

import Foundation

public extension Notification.Name {
    /// 题目数据发生写操作后（新增、更新、删除）由业务层主动 post 的通知
    static let reviewDataDidChange = Notification.Name("com.snapdrill.reviewDataDidChange")
}
