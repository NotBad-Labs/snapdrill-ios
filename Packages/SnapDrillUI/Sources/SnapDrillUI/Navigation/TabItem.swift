//
//  TabItem.swift
//  SnapDrillUI
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  定义 TabBar 的枚举项及其相关属性。
//

import SwiftUI
import Foundation
import SnapDrillCore

/// 定义应用中所有的 Tab 项
public enum TabItem: Hashable, CaseIterable {

    // MARK: - Cases

    case dashboard
    case library
    case capture
    case review
    case settings

    // MARK: - Properties

    /// Tab 的显示名称（本地化文本）
    public var title: String {
        switch self {
        case .dashboard: return L10n.Tab.dashboard
        case .library: return L10n.Tab.library
        case .capture: return L10n.Tab.capture
        case .review: return L10n.Tab.review
        case .settings: return L10n.Tab.settings
        }
    }
    
    /// Tab 对应的 SF Symbol 图标名称
    public var iconName: String {
        switch self {
        case .dashboard: return "house"
        case .library: return "books.vertical"
        case .capture: return "camera"
        case .review: return "clock.arrow.circlepath"
        case .settings: return "gear"
        }
    }
}
