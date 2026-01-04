//
//  NetworkMonitor.swift
//  NotBadCore
//
//  Created by NotBad Architect on 2026/01/02.
//  Copyright © 2026 NotBad Team. All rights reserved.
//
//  网络状态监控服务
//

import Foundation
import Network

/// 网络状态监控
///
/// 使用 Network framework 监控网络连接状态。
@MainActor
@Observable
public final class NetworkMonitor {
    /// 共享实例
    /// 共享实例 - 建议使用 Environment 注入
    @available(*, deprecated, message: "Use Environment injection instead")
    public static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.LIAOYIMING.NotBad.NetworkMonitor")
    
    /// 当前网络状态
    public private(set) var isConnected: Bool = true
    
    /// 网络类型
    public private(set) var connectionType: ConnectionType = .unknown
    
    /// 网络类型枚举
    public enum ConnectionType {
        case wifi
        case cellular
        case wired
        case unknown
    }
    
    public init() {
        startMonitoring()
    }
    
    /// 开始监控网络状态
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(from: path) ?? .unknown
            }
        }
        monitor.start(queue: queue)
    }
    
    /// 获取连接类型
    private func getConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wired
        } else {
            return .unknown
        }
    }
    
    /// 停止监控
    deinit {
        monitor.cancel()
    }
}
