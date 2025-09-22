//
//  ProfileCoordinator.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import SwiftUI

/// 个人中心协调器
/// 管理个人中心模块的导航逻辑
@MainActor
class ProfileCoordinator: BaseCoordinator {
    override func coordinate(to route: Route) {
        switch route {
        case .profile:
            // 回到个人中心根视图
            navigationPath = NavigationPath()
        case .settings:
            navigationPath.append("settings")
        case .about:
            navigationPath.append("about")
        default:
            break
        }
    }
}
