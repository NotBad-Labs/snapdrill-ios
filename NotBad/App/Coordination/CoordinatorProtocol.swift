//
//  CoordinatorProtocol.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/7/29.
//


import SwiftUI
import Foundation

// MARK: - 协调器基础协议
// 位置: App/Navigation/CoordinatorProtocol.swift

/// 协调器基础协议
/// 所有协调器都应该遵循此协议
@MainActor
protocol CoordinatorProtocol: ObservableObject {
    /// 协调器的唯一标识
    var id: UUID { get }
    
    /// 父协调器的弱引用（避免循环引用）
    var parent: (any CoordinatorProtocol)? { get set }
    
    /// 子协调器数组
    var children: [any CoordinatorProtocol] { get set }
    
    /// 启动协调器
    func start()
    
    /// 停止协调器并清理资源
    func stop()
    
    /// 添加子协调器
    func addChild(_ coordinator: any CoordinatorProtocol)
    
    /// 移除子协调器
    func removeChild(_ coordinator: any CoordinatorProtocol)
    
    /// 获取根视图
    func getRootView() -> AnyView
}

// MARK: - 协调器基础实现

/// 协调器基础类，提供默认实现
@MainActor
class BaseCoordinator: CoordinatorProtocol {
    let id = UUID()
    weak var parent: (any CoordinatorProtocol)?
    var children: [any CoordinatorProtocol] = []
    
    init() {}
    
    func start() {
        // 子类重写此方法
    }
    
    func stop() {
        children.forEach { $0.stop() }
        children.removeAll()
        parent?.removeChild(self)
    }
    
    func addChild(_ coordinator: any CoordinatorProtocol) {
        children.append(coordinator)
        coordinator.parent = self
    }
    
    func removeChild(_ coordinator: any CoordinatorProtocol) {
        children.removeAll { $0.id == coordinator.id }
    }
    
    func getRootView() -> AnyView {
        // 子类必须重写此方法
        fatalError("getRootView() must be implemented by subclass")
    }
}