//
//  Notification+Names.swift
//  NotBad
//
//  应用通知名称定义
//

import Foundation

extension Notification.Name {
    // MARK: - App 生命周期
    
    /// 应用进入后台通知
    static let appDidEnterBackground = Notification.Name("appDidEnterBackground")
    
    /// 应用进入前台通知
    static let appDidBecomeActive = Notification.Name("appDidBecomeActive")
    
    // MARK: - 实时扫描
    
    /// 实时扫描完成请求
    static let liveScannerFinishRequest = Notification.Name("liveScannerFinishRequest")
    
    /// 实时扫描完成响应
    static let liveScannerFinishResponse = Notification.Name("liveScannerFinishResponse")
}

