//
//  Coordinator.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import SwiftUI

/// 导航协调器协议
/// 定义了所有协调器必须实现的基本导航能力
@MainActor
protocol Coordinator: ObservableObject {
    /// 启动协调器，设置初始导航状态
    func start()

    /// 协调到指定路由
    /// - Parameter route: 目标路由
    func coordinate(to route: Route)

    /// 返回上一级
    func goBack()
    
    /// 父协调器引用（用于向上委托）
    var parent: (any Coordinator)? { get set }
    
    /// 处理无法在当前协调器处理的路由
    /// - Parameter route: 需要委托的路由
    func delegate(route: Route)
}

/// 路由定义
/// 定义应用中所有可能的导航路由
enum Route: Hashable {
    // MARK: - Tab Routes
    case home
    case capture
    case library
    case discovery
    case profile

    // MARK: - Content Routes (参数化路由，减少枚举膨胀)
    case detail(module: String, id: String)
    case camera
    case photoLibrary
    case ocrResult(image: String)
    case ocrEdit(result: String)
    case saveReviewItem(content: String)
    case practiceMode
    case settings
    case about
    
    // MARK: - Cross-Module Routes (跨模块导航)
    case navigateToLibraryAfterCapture    // 拍照完成后前往题库
    case navigateToLibraryFromHome       // 从首页前往题库
    case navigateToPracticeFromLibrary   // 从题库开始练习
}

/// 基础协调器实现
/// 提供所有协调器的通用功能
@MainActor
class BaseCoordinator: Coordinator {
    /// 导航路径
    @Published var navigationPath = NavigationPath()
    
    /// 父协调器引用
    weak var parent: (any Coordinator)?

    func start() {
        navigationPath = NavigationPath()
    }

    func coordinate(to route: Route) {
        // 基础实现，子类应重写
        // 如果子类无法处理，则委托给父协调器
        delegate(route: route)
    }

    func goBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func delegate(route: Route) {
        // 向上委托给父协调器
        parent?.coordinate(to: route)
    }
}
