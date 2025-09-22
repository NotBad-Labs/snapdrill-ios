//
//  LibraryCoordinator.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import SwiftUI

/// 题库协调器
/// 管理题库模块的导航逻辑
@MainActor
class LibraryCoordinator: BaseCoordinator {
    override func coordinate(to route: Route) {
        switch route {
        case .library:
            // 回到题库根视图
            navigationPath = NavigationPath()
        case .detail(let module, let id) where module == "library":
            navigationPath.append("detail-\(id)")
        case .practiceMode:
            navigationPath.append("practice")
        case .navigateToPracticeFromLibrary:
            // 处理从其他模块触发的练习导航
            coordinate(to: .practiceMode)
        default:
            // 无法处理的路由委托给父协调器
            delegate(route: route)
        }
    }
}
