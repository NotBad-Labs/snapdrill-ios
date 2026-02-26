//
//  KeychainService.swift
//  SnapDrillCore
//
//  Created by SnapDrill Labs on 2026/02/25.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//

import Foundation
import Security
import OSLog

/// Keychain 安全存储服务
///
/// 用于持久化存储敏感信息（如用户 ID、Token 等），这些信息不应存放在 UserDefaults 或文件中。
/// 符合 Swift 6 并发安全要求。
public actor KeychainService {
    
    // MARK: - Properties
    
    public static let shared = KeychainService()
    
    private let logger = Logger(subsystem: "com.snapdrill.app", category: "Keychain")
    private let serviceName = "com.snapdrill.app.secure-storage"
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public API
    
    /// 保存字符串到 Keychain
    public func save(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // 先尝试删除旧值
        SecItemDelete(query as CFDictionary)
        
        // 插入新值
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            logger.error("❌ Failed to save to Keychain: \(status)")
        }
    }
    
    /// 从 Keychain 读取字符串
    public func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        
        if status != errSecItemNotFound {
            logger.error("❌ Error reading from Keychain: \(status)")
        }
        
        return nil
    }
    
    /// 从 Keychain 删除某项
    public func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            logger.error("❌ Error deleting from Keychain: \(status)")
        }
    }
}
