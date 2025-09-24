//
//  AppConfiguration.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import Foundation
import SwiftUI

/// 应用配置中心
/// 集中管理所有应用级别的配置参数和常量
struct AppConfiguration {
    
    // MARK: - Singleton
    static let current = AppConfiguration()
    
    // MARK: - UI Configuration
    struct UI {
        /// 主要动画配置
        struct Animation {
            static let defaultDuration: TimeInterval = 0.3
            static let fastDuration: TimeInterval = 0.15
            static let slowDuration: TimeInterval = 0.5
            static let defaultEasing: SwiftUI.Animation = .easeOut(duration: defaultDuration)
            static let fastEasing: SwiftUI.Animation = .easeInOut(duration: fastDuration)
            static let slowEasing: SwiftUI.Animation = .easeInOut(duration: slowDuration)
        }
        
        /// 布局配置
        struct Layout {
            static let cornerRadius: CGFloat = 12
            static let shadowRadius: CGFloat = 4
            static let defaultPadding: CGFloat = 16
            static let smallPadding: CGFloat = 8
            static let largePadding: CGFloat = 24
        }
        
        /// 字体配置
        struct Typography {
            static let primaryFont: Font = .system(.body, design: .default)
            static let titleFont: Font = .system(.title, design: .default, weight: .semibold)
            static let captionFont: Font = .system(.caption, design: .default)
        }
    }
    
    // MARK: - App Lifecycle Configuration
    struct Lifecycle {
        /// 启动配置
        struct Launch {
            static let minimumDisplayTime: TimeInterval = 0.5
            static let initializationTimeout: TimeInterval = 10.0
            static let gracefulShutdownTime: TimeInterval = 2.0
        }
        
        /// 性能配置
        struct Performance {
            static let maxConcurrentOperations: Int = 3
            static let cacheLimit: Int = 100
            static let networkTimeout: TimeInterval = 30.0
        }
    }
    
    // MARK: - Feature Flags
    struct Features {
        /// 功能开关
        static let enableAdvancedLogging: Bool = {
            #if DEBUG
            return true
            #else
            return false
            #endif
        }()
        
        static let enablePerformanceMonitoring: Bool = true
        static let enableCrashReporting: Bool = {
            #if DEBUG
            return false
            #else
            return true
            #endif
        }()
        
        static let enableAnalytics: Bool = true
    }
    
    // MARK: - Environment Configuration
    struct Environment {
        static let current: EnvironmentType = {
            #if DEBUG
            return .development
            #elseif STAGING
            return .staging
            #else
            return .production
            #endif
        }()
        
        enum EnvironmentType: String, CaseIterable {
            case development = "Development"
            case staging = "Staging"
            case production = "Production"
            
            var isProduction: Bool {
                self == .production
            }
            
            var isDevelopment: Bool {
                self == .development
            }
            
            var displayName: String {
                rawValue
            }
        }
    }
    
    // MARK: - Validation
    
    /// 验证配置的有效性
    static func validateConfiguration() -> ConfigurationValidationResult {
        var issues: [String] = []
        
        // 验证时间配置
        if Lifecycle.Launch.minimumDisplayTime < 0 {
            issues.append("最小显示时间不能为负数")
        }
        
        if Lifecycle.Launch.initializationTimeout < Lifecycle.Launch.minimumDisplayTime {
            issues.append("初始化超时时间应该大于最小显示时间")
        }
        
        // 验证性能配置
        if Lifecycle.Performance.maxConcurrentOperations < 1 {
            issues.append("最大并发操作数不能小于1")
        }
        
        if Lifecycle.Performance.cacheLimit < 0 {
            issues.append("缓存限制不能为负数")
        }
        
        return ConfigurationValidationResult(
            isValid: issues.isEmpty,
            issues: issues
        )
    }
}

// MARK: - Supporting Types

/// 配置验证结果
struct ConfigurationValidationResult {
    let isValid: Bool
    let issues: [String]
    
    var description: String {
        if isValid {
            return "✅ 配置验证通过"
        } else {
            return "❌ 配置验证失败:\n" + issues.map { "  • \($0)" }.joined(separator: "\n")
        }
    }
}

// MARK: - Development Helper

#if DEBUG
extension AppConfiguration {
    /// 开发环境下的配置调试信息
    static func debugDescription() -> String {
        """
        📱 NotBad App Configuration Debug Info
        
        🎨 UI Configuration:
          • Animation Duration: \(UI.Animation.defaultDuration)s
          • Corner Radius: \(UI.Layout.cornerRadius)pt
          • Default Padding: \(UI.Layout.defaultPadding)pt
        
        🚀 Lifecycle Configuration:
          • Launch Display Time: \(Lifecycle.Launch.minimumDisplayTime)s
          • Initialization Timeout: \(Lifecycle.Launch.initializationTimeout)s
          • Max Concurrent Ops: \(Lifecycle.Performance.maxConcurrentOperations)
        
        🔧 Feature Flags:
          • Advanced Logging: \(Features.enableAdvancedLogging ? "✅" : "❌")
          • Performance Monitoring: \(Features.enablePerformanceMonitoring ? "✅" : "❌")
          • Crash Reporting: \(Features.enableCrashReporting ? "✅" : "❌")
          • Analytics: \(Features.enableAnalytics ? "✅" : "❌")
        
        🌍 Environment: \(Environment.current.displayName)
        """
    }
}
#endif