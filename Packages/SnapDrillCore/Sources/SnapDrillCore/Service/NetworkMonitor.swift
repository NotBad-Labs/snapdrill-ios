//
//  NetworkMonitor.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/01/02.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
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
    
    // MARK: - Properties
    
    /// 共享实例 - 建议使用 ServiceContainer 注入
    public static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.snapdrill.app.NetworkMonitor")
    
    // MARK: - Status
    
    /// 当前网络是否已连接
    public private(set) var isConnected: Bool = true
    
    /// 具体连接类型（WiFi, 蜂窝等）
    public private(set) var connectionType: ConnectionType = .unknown
    
    // MARK: - Types
    
    public enum ConnectionType {
        case wifi
        case cellular
        case wired
        case unknown
    }
    
    // MARK: - Initialization
    
    public init() {
        startMonitoring()
    }
    
    // MARK: - Private Helpers
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            // Task { @MainActor in } 替代 DispatchQueue.main.async，确保 Swift 6 严格 Actor 隔离边界。
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isConnected = path.status == .satisfied
                self.connectionType = self.getConnectionType(from: path)
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
