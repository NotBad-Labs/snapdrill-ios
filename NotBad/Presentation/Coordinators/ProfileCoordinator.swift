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
    enum ProfileRoute: Hashable {
        case settings
        case about
        case detail(id: String)
    }
    override func coordinate(to route: Route) {
        switch route {
        case .profile:
            // 回到个人中心根视图
            navigationPath = NavigationPath()
        case .settings:
            navigationPath.append(ProfileRoute.settings)
        case .about:
            navigationPath.append(ProfileRoute.about)
        case .detail(let module, let id) where module == "profile":
            navigationPath.append(ProfileRoute.detail(id: id))
        default:
            break
        }
    }
}
