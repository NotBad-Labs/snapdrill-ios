//
//  DiscoveryCoordinator.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import SwiftUI

/// 发现协调器
/// 管理发现模块的导航逻辑
@MainActor
class DiscoveryCoordinator: BaseCoordinator {
    override func coordinate(to route: Route) {
        switch route {
        case .discovery:
            // 回到发现根视图
            navigationPath = NavigationPath()
        case .detail(let module, let id) where module == "discovery":
            navigationPath.append("detail-\(id)")
        default:
            break
        }
    }
}
