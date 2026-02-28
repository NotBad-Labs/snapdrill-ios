//
//  Routable.swift
//  SnapDrillUI
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  路由协议，定义 Feature 模块的页面导航接口。
//

import SwiftUI

/// 所有 Feature Router 必须遵循的协议
public protocol Routable: AnyObject, Observable {
    
    // MARK: - Requirements
    
    associatedtype Destination: Hashable
    
    var path: NavigationPath { get set }
    
    func push(_ destination: Destination)
    func pop()
    func popToRoot()
}

/// 提供默认实现
public extension Routable {
    
    // MARK: - Default Implementation
    
    func push(_ destination: Destination) {
        path.append(destination)
    }
    
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    func popToRoot() {
        path = NavigationPath()
    }
}
