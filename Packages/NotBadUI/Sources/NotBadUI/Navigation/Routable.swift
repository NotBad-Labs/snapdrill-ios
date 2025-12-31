import SwiftUI

/// 所有 Feature Router 必须遵循的协议
public protocol Routable: AnyObject, Observable {
    associatedtype Destination: Hashable
    
    var path: NavigationPath { get set }
    
    func push(_ destination: Destination)
    func pop()
    func popToRoot()
}

/// 提供默认实现
public extension Routable {
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
