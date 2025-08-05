// MARK: - AppConfiguration.swift
/**
 * 应用环境配置管理器
 * 
 * 职责：
 * - 管理不同环境（开发、测试、生产）的配置参数
 * - 提供编译时和运行时的配置切换能力
 * - 集中管理 API 端点、服务密钥、功能开关等配置
 * - 支持配置的动态更新和远程配置
 * 
 * 设计原则：
 * - 环境隔离：不同环境使用不同的配置，避免配置污染
 * - 安全性：敏感信息通过安全方式管理，不硬编码在代码中
 * - 可扩展性：易于添加新的配置项和环境
 * - 类型安全：使用强类型确保配置的正确性
 * 
 * 架构位置：
 * ```
 * AppEnvironment
 *     ↓ 加载配置
 * AppConfiguration (这里) ← 配置管理
 *     ↓ 提供配置
 * 各种服务 ← 根据配置初始化
 * ```
 * 
 * 使用方式：
 * ```swift
 * let config = AppConfiguration.current
 * let apiURL = config.apiBaseURL
 * if config.enableAnalytics { ... }
 * ```
 * 
 * 环境配置：
 * - 通过编译标志（DEBUG、STAGING、RELEASE）自动选择环境
 * - 支持通过 Info.plist 覆盖默认配置
 * - 支持远程配置的动态更新
 * 
 * 安全注意事项：
 * - 生产环境的 API 密钥不应硬编码在源码中
 * - 敏感配置应通过 Keychain 或环境变量管理
 * - 日志和调试信息在生产环境中应被禁用
 * 
 * @author NotBad Team
 * @since 1.0.0
 * @updated 2025-08-01
 */

import Foundation

/**
 * 应用配置结构体
 * 
 * 包含应用运行所需的所有配置参数，支持不同环境的配置切换
 */
struct AppConfiguration {
    
    // MARK: - 环境定义
    
    /**
     * 应用运行环境枚举
     * 
     * 定义应用可能运行的不同环境，每个环境对应不同的配置参数
     */
    enum Environment: String, CaseIterable {
        case development = "development"  /// 开发环境：用于本地开发和调试
        case staging = "staging"         /// 测试环境：用于集成测试和预发布验证
        case production = "production"   /// 生产环境：用于正式发布的应用
        
        /**
         * 环境的显示名称
         */
        var displayName: String {
            switch self {
            case .development: return "开发环境"
            case .staging: return "测试环境"
            case .production: return "生产环境"
            }
        }
        
        /**
         * 是否为生产环境
         */
        var isProduction: Bool {
            return self == .production
        }
        
        /**
         * 是否为调试环境
         */
        var isDebug: Bool {
            return self == .development
        }
    }
    
    // MARK: - 服务提供商枚举
    
    /**
     * OCR 服务提供商
     */
    enum OCRProvider: String, CaseIterable {
        case apple = "apple"      /// Apple Vision Framework
        case google = "google"    /// Google Cloud Vision API
        case azure = "azure"      /// Azure Cognitive Services
        
        var displayName: String {
            switch self {
            case .apple: return "Apple Vision"
            case .google: return "Google Cloud Vision"
            case .azure: return "Azure Cognitive Services"
            }
        }
    }
    
    /**
     * 云服务提供商
     */
    enum CloudProvider: String, CaseIterable {
        case icloud = "icloud"        /// Apple iCloud
        case firebase = "firebase"    /// Google Firebase
        case aws = "aws"             /// Amazon Web Services
        
        var displayName: String {
            switch self {
            case .icloud: return "iCloud"
            case .firebase: return "Firebase"
            case .aws: return "AWS"
            }
        }
    }
    
    // MARK: - 基础配置
    
    /// 当前运行环境
    let environment: Environment
    
    /// 应用版本号，从 Bundle 中读取
    let appVersion: String
    
    /// 构建版本号，从 Bundle 中读取
    let buildNumber: String
    
    /// Bundle ID，用于标识应用
    let bundleId: String
    
    // MARK: - 网络配置
    
    /// API 基础 URL
    let apiBaseURL: String
    
    /// WebSocket 基础 URL
    let websocketBaseURL: String
    
    /// API 请求超时时间（秒）
    let apiTimeout: TimeInterval
    
    /// 最大重试次数
    let maxRetryCount: Int
    
    // MARK: - 服务配置
    
    /// OCR 服务提供商
    let ocrProvider: OCRProvider
    
    /// 云存储服务提供商
    let cloudProvider: CloudProvider
    
    /// 是否启用云同步
    let enableCloudSync: Bool
    
    /// 同步间隔（秒）
    let syncInterval: TimeInterval
    
    // MARK: - 功能开关
    
    /// 是否启用日志记录
    let enableLogging: Bool
    
    /// 是否启用数据分析
    let enableAnalytics: Bool
    
    /// 是否启用性能监控
    let enablePerformanceMonitoring: Bool
    
    /// 是否启用崩溃报告
    let enableCrashReporting: Bool
    
    /// 是否启用调试菜单
    let enableDebugMenu: Bool
    
    /// 是否启用 A/B 测试
    let enableABTesting: Bool
    
    // MARK: - UI 配置
    
    /// 默认主题模式
    let defaultTheme: ThemeMode
    
    /// 是否启用动画
    let enableAnimations: Bool
    
    /// 动画持续时间
    let animationDuration: TimeInterval
    
    // MARK: - 学习配置
    
    /// 默认每日学习目标（题目数量）
    let defaultDailyGoal: Int
    
    /// 学习提醒默认时间
    let defaultReminderTime: (hour: Int, minute: Int)
    
    /// 错题重复学习间隔（天）
    let wrongQuestionReviewInterval: Int
    
    // MARK: - 缓存配置
    
    /// 图片缓存大小限制（MB）
    let imageCacheLimit: Int
    
    /// 数据缓存大小限制（MB）
    let dataCacheLimit: Int
    
    /// 缓存过期时间（秒）
    let cacheExpirationTime: TimeInterval
    
    // MARK: - 安全配置
    
    /// 是否启用生物识别认证
    let enableBiometricAuth: Bool
    
    /// 应用锁定超时时间（秒）
    let appLockTimeout: TimeInterval
    
    /// 最大登录尝试次数
    let maxLoginAttempts: Int
    
    // MARK: - 外部服务密钥（仅用于非生产环境）
    
    /// Google API 密钥（开发/测试环境）
    let googleAPIKey: String?
    
    /// Azure 订阅密钥（开发/测试环境）
    let azureSubscriptionKey: String?
    
    /// Firebase 项目 ID
    let firebaseProjectId: String?
    
    // MARK: - 计算属性
    
    /**
     * 云服务配置
     * 
     * 根据云服务提供商返回对应的服务实例
     */
    var cloudService: CloudService {
        switch cloudProvider {
        case .icloud:
            return iCloudService()
        case .firebase:
            return FirebaseService(projectId: firebaseProjectId)
        case .aws:
            return AWSService()
        }
    }
    
    /**
     * 是否为开发构建
     * 
     * 用于判断是否显示调试信息和开发工具
     */
    var isDevelopmentBuild: Bool {
        return environment == .development || enableDebugMenu
    }
    
    /**
     * 完整的 API 端点 URL
     */
    func apiURL(for endpoint: String) -> URL? {
        return URL(string: "\(apiBaseURL)\(endpoint)")
    }
    
    // MARK: - 静态工厂方法
    
    /**
     * 当前应用配置
     * 
     * 根据编译标志自动选择对应环境的配置
     */
    static var current: AppConfiguration {
        #if DEBUG
        return developmentConfiguration
        #elseif STAGING
        return stagingConfiguration
        #else
        return productionConfiguration
        #endif
    }
    
    /**
     * 开发环境配置
     */
    static var developmentConfiguration: AppConfiguration {
        return AppConfiguration(
            environment: .development,
            appVersion: Bundle.main.appVersion,
            buildNumber: Bundle.main.buildNumber,
            bundleId: Bundle.main.bundleIdentifier ?? "com.notbad.app",
            
            // 网络配置
            apiBaseURL: "https://dev-api.notbad.com/v1",
            websocketBaseURL: "wss://dev-ws.notbad.com",
            apiTimeout: 30.0,
            maxRetryCount: 3,
            
            // 服务配置
            ocrProvider: .apple,
            cloudProvider: .icloud,
            enableCloudSync: false, // 开发环境关闭同步
            syncInterval: 300, // 5分钟
            
            // 功能开关
            enableLogging: true,
            enableAnalytics: false, // 开发环境关闭分析
            enablePerformanceMonitoring: false,
            enableCrashReporting: false,
            enableDebugMenu: true,
            enableABTesting: false,
            
            // UI 配置
            defaultTheme: .system,
            enableAnimations: true,
            animationDuration: 0.3,
            
            // 学习配置
            defaultDailyGoal: 20,
            defaultReminderTime: (hour: 20, minute: 0),
            wrongQuestionReviewInterval: 1, // 开发环境设为1天便于测试
            
            // 缓存配置
            imageCacheLimit: 50, // 50MB
            dataCacheLimit: 20,  // 20MB
            cacheExpirationTime: 3600, // 1小时
            
            // 安全配置
            enableBiometricAuth: false, // 开发环境关闭以便调试
            appLockTimeout: 300, // 5分钟
            maxLoginAttempts: 5,
            
            // 外部服务密钥（开发环境可以硬编码）
            googleAPIKey: "dev-google-api-key",
            azureSubscriptionKey: "dev-azure-key",
            firebaseProjectId: "notbad-dev"
        )
    }
    
    /**
     * 测试环境配置
     */
    static var stagingConfiguration: AppConfiguration {
        return AppConfiguration(
            environment: .staging,
            appVersion: Bundle.main.appVersion,
            buildNumber: Bundle.main.buildNumber,
            bundleId: Bundle.main.bundleIdentifier ?? "com.notbad.app.staging",
            
            // 网络配置
            apiBaseURL: "https://staging-api.notbad.com/v1",
            websocketBaseURL: "wss://staging-ws.notbad.com",
            apiTimeout: 30.0,
            maxRetryCount: 3,
            
            // 服务配置
            ocrProvider: .google,
            cloudProvider: .firebase,
            enableCloudSync: true,
            syncInterval: 180, // 3分钟
            
            // 功能开关
            enableLogging: true,
            enableAnalytics: true,
            enablePerformanceMonitoring: true,
            enableCrashReporting: true,
            enableDebugMenu: true,
            enableABTesting: true,
            
            // UI 配置
            defaultTheme: .system,
            enableAnimations: true,
            animationDuration: 0.3,
            
            // 学习配置
            defaultDailyGoal: 20,
            defaultReminderTime: (hour: 20, minute: 0),
            wrongQuestionReviewInterval: 3, // 3天
            
            // 缓存配置
            imageCacheLimit: 100, // 100MB
            dataCacheLimit: 50,   // 50MB
            cacheExpirationTime: 7200, // 2小时
            
            // 安全配置
            enableBiometricAuth: true,
            appLockTimeout: 300, // 5分钟
            maxLoginAttempts: 3,
            
            // 外部服务密钥（测试环境从环境变量读取）
            googleAPIKey: ProcessInfo.processInfo.environment["GOOGLE_API_KEY"],
            azureSubscriptionKey: ProcessInfo.processInfo.environment["AZURE_SUBSCRIPTION_KEY"],
            firebaseProjectId: "notbad-staging"
        )
    }
    
    /**
     * 生产环境配置
     */
    static var productionConfiguration: AppConfiguration {
        return AppConfiguration(
            environment: .production,
            appVersion: Bundle.main.appVersion,
            buildNumber: Bundle.main.buildNumber,
            bundleId: Bundle.main.bundleIdentifier ?? "com.notbad.app",
            
            // 网络配置
            apiBaseURL: "https://api.notbad.com/v1",
            websocketBaseURL: "wss://ws.notbad.com",
            apiTimeout: 15.0, // 生产环境更短的超时时间
            maxRetryCount: 2,
            
            // 服务配置
            ocrProvider: .azure, // 生产环境使用 Azure
            cloudProvider: .firebase,
            enableCloudSync: true,
            syncInterval: 600, // 10分钟
            
            // 功能开关
            enableLogging: false, // 生产环境关闭详细日志
            enableAnalytics: true,
            enablePerformanceMonitoring: true,
            enableCrashReporting: true,
            enableDebugMenu: false, // 生产环境关闭调试菜单
            enableABTesting: true,
            
            // UI 配置
            defaultTheme: .system,
            enableAnimations: true,
            animationDuration: 0.25, // 生产环境稍快的动画
            
            // 学习配置
            defaultDailyGoal: 15,
            defaultReminderTime: (hour: 19, minute: 30),
            wrongQuestionReviewInterval: 7, // 7天
            
            // 缓存配置
            imageCacheLimit: 200, // 200MB
            dataCacheLimit: 100,  // 100MB
            cacheExpirationTime: 86400, // 24小时
            
            // 安全配置
            enableBiometricAuth: true,
            appLockTimeout: 180, // 3分钟
            maxLoginAttempts: 3,
            
            // 外部服务密钥（生产环境从 Keychain 读取）
            googleAPIKey: KeychainService.shared.getValue(for: "google_api_key"),
            azureSubscriptionKey: KeychainService.shared.getValue(for: "azure_subscription_key"),
            firebaseProjectId: "notbad-prod"
        )
    }
    
    // MARK: - 动态配置更新
    
    /**
     * 从远程配置更新本地配置
     * 
     * 支持在不发版的情况下动态更新某些配置参数
     * 
     * @param remoteConfig 从服务器获取的远程配置
     */
    mutating func updateFromRemoteConfig(_ remoteConfig: [String: Any]) {
        // 这里可以根据远程配置更新本地配置
        // 注意：只有非关键配置才应该支持远程更新
        
        if let syncInterval = remoteConfig["sync_interval"] as? TimeInterval {
            // self.syncInterval = syncInterval
            print("📱 更新同步间隔: \(syncInterval)")
        }
        
        if let dailyGoal = remoteConfig["default_daily_goal"] as? Int {
            // self.defaultDailyGoal = dailyGoal
            print("📱 更新默认学习目标: \(dailyGoal)")
        }
        
        // 更多配置项...
    }
}

// MARK: - 支持类型

/**
 * 主题模式枚举
 */
enum ThemeMode: String, CaseIterable {
    case light = "light"     /// 浅色主题
    case dark = "dark"       /// 深色主题
    case system = "system"   /// 跟随系统
    
    var displayName: String {
        switch self {
        case .light: return "浅色"
        case .dark: return "深色"
        case .system: return "跟随系统"
        }
    }
}

/**
 * 云服务协议
 */
protocol CloudService {
    func sync() async throws
    func upload(_ data: Data, to path: String) async throws
    func download(from path: String) async throws -> Data
}

/**
 * 云服务实现示例
 */
struct iCloudService: CloudService {
    func sync() async throws {
        // iCloud 同步实现
    }
    
    func upload(_ data: Data, to path: String) async throws {
        // iCloud 上传实现
    }
    
    func download(from path: String) async throws -> Data {
        // iCloud 下载实现
        return Data()
    }
}

struct FirebaseService: CloudService {
    let projectId: String?
    
    func sync() async throws {
        // Firebase 同步实现
    }
    
    func upload(_ data: Data, to path: String) async throws {
        // Firebase 上传实现
    }
    
    func download(from path: String) async throws -> Data {
        // Firebase 下载实现
        return Data()
    }
}

struct AWSService: CloudService {
    func sync() async throws {
        // AWS 同步实现
    }
    
    func upload(_ data: Data, to path: String) async throws {
        // AWS 上传实现
    }
    
    func download(from path: String) async throws -> Data {
        // AWS 下载实现
        return Data()
    }
}

// MARK: - Bundle 扩展

/**
 * Bundle 扩展，提供便捷的版本信息访问
 */
extension Bundle {
    
    /// 应用版本号
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    /// 构建版本号
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// 应用名称
    var appName: String {
        return infoDictionary?["CFBundleDisplayName"] as? String ?? 
               infoDictionary?["CFBundleName"] as? String ?? "NotBad"
    }
}

// MARK: - Keychain 服务

/**
 * Keychain 服务，用于安全存储敏感配置
 * 
 * 注意：这是一个简化的示例实现，生产环境应使用更完善的 Keychain 封装
 */
class KeychainService {
    static let shared = KeychainService()
    
    private init() {}
    
    func getValue(for key: String) -> String? {
        // 简化的 Keychain 读取实现
        // 实际应用中应该使用 Security framework 的完整实现
        return nil
    }
    
    func setValue(_ value: String, for key: String) -> Bool {
        // 简化的 Keychain 写入实现
        return false
    }
    
    func removeValue(for key: String) -> Bool {
        // 简化的 Keychain 删除实现
        return false
    }
}