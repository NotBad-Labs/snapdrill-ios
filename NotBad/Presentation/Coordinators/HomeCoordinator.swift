//
//  HomeCoordinator.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import SwiftUI

/// 首页协调器
/// 管理首页模块的导航逻辑
@MainActor
class HomeCoordinator: BaseCoordinator {
    enum HomeRoute: Hashable {
        case detail(id: String)
    }
    override func coordinate(to route: Route) {
        switch route {
        case .home:
            // 回到首页根视图
            navigationPath = NavigationPath()
        case .detail(let module, let id) where module == "home":
            navigationPath.append(HomeRoute.detail(id: id))
        case .navigateToLibraryFromHome:
            // 委托给父协调器处理跨 Tab 导航
            delegate(route: route)
        default:
            // 无法处理的路由委托给父协调器
            delegate(route: route)
        }
    }
}
