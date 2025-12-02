//
//  UserProfileManager.swift
//  NotBad
//
//  用户个人资料管理器
//

import Foundation
import SwiftUI

// MARK: - UserProfileManager

/// 用户个人资料管理器
///
/// 管理用户的昵称、头像等个人设置，支持本地存储和 iCloud 同步。
@MainActor
final class UserProfileManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = UserProfileManager()
    
    // MARK: - Keys
    
    private enum Keys {
        static let nickname = "user_nickname"
        static let avatar = "user_avatar"
        static let gradientIndex = "user_gradient_index"
    }
    
    // MARK: - Published Properties
    
    @Published var nickname: String {
        didSet {
            saveToLocal(nickname, forKey: Keys.nickname)
            syncToCloud(nickname, forKey: Keys.nickname)
        }
    }
    
    @Published var avatar: String {
        didSet {
            saveToLocal(avatar, forKey: Keys.avatar)
            syncToCloud(avatar, forKey: Keys.avatar)
        }
    }
    
    @Published var gradientIndex: Int {
        didSet {
            saveToLocal(gradientIndex, forKey: Keys.gradientIndex)
            syncToCloud(gradientIndex, forKey: Keys.gradientIndex)
        }
    }
    
    // MARK: - Gradient Colors
    
    /// 头像背景渐变色选项
    var gradientColors: [Color] {
        let options: [[Color]] = [
            [Color.brand.primary, Color.brand.secondary],
            [.purple, .pink],
            [.orange, .red],
            [.green, .mint],
            [.blue, .cyan],
            [.indigo, .purple]
        ]
        let index = min(gradientIndex, options.count - 1)
        return options[max(0, index)]
    }
    
    // MARK: - Initialization
    
    private init() {
        // 优先从 iCloud 加载，否则从本地加载
        self.nickname = Self.loadFromCloud(forKey: Keys.nickname) 
            ?? Self.loadFromLocal(forKey: Keys.nickname) 
            ?? String(localized: "profile_nickname")
        
        self.avatar = Self.loadFromCloud(forKey: Keys.avatar) 
            ?? Self.loadFromLocal(forKey: Keys.avatar) 
            ?? "person.fill"
        
        self.gradientIndex = Self.loadFromCloud(forKey: Keys.gradientIndex) 
            ?? Self.loadFromLocal(forKey: Keys.gradientIndex) 
            ?? 0
        
        // 监听 iCloud 变更
        setupCloudObserver()
    }
    
    // MARK: - Local Storage
    
    private func saveToLocal<T>(_ value: T, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    private static func loadFromLocal<T>(forKey key: String) -> T? {
        UserDefaults.standard.object(forKey: key) as? T
    }
    
    // MARK: - iCloud Storage
    
    private func syncToCloud<T>(_ value: T, forKey key: String) {
        NSUbiquitousKeyValueStore.default.set(value, forKey: key)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    private static func loadFromCloud<T>(forKey key: String) -> T? {
        NSUbiquitousKeyValueStore.default.object(forKey: key) as? T
    }
    
    private func setupCloudObserver() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            // 直接从 iCloud 重新读取数据，避免 Sendable 问题
            Task { @MainActor in
                self?.reloadFromCloud()
            }
        }
        
        // 初始同步
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    private func reloadFromCloud() {
        if let value: String = Self.loadFromCloud(forKey: Keys.nickname) {
            self.nickname = value
        }
        if let value: String = Self.loadFromCloud(forKey: Keys.avatar) {
            self.avatar = value
        }
        if let value: Int = Self.loadFromCloud(forKey: Keys.gradientIndex) {
            self.gradientIndex = value
        }
    }
}
