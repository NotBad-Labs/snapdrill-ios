import Foundation

/// ReviewKit 配置
public struct ReviewKitConfiguration: Sendable {
    @MainActor
    /// 全局共享配置
    public static var shared = ReviewKitConfiguration()
    @MainActor
    /// 设置全局配置
    public static func configure(_ configuration: ReviewKitConfiguration) {
        Self.shared = configuration
    }
    
    /// App Group 标识符
    public let appGroupIdentifier: String
    /// 数据库文件名
    public let databaseFileName: String
    /// 图片目录名
    public let imagesDirectoryName: String
    /// 自定义容器地址（可选）
    public let customContainerURL: URL?

    /// 共享容器 URL，在初始化时计算一次避免重复 I/O
    public let sharedContainerURL: URL?
    /// 数据库文件 URL，在初始化时计算一次避免重复 I/O
    public let databaseURL: URL?
    /// 图片目录 URL，在初始化时计算一次避免重复 I/O
    public let imagesDirectoryURL: URL?
    
    public init(
        appGroupIdentifier: String = "group.com.notbad.shared",
        databaseFileName: String = "NotBad.sqlite",
        imagesDirectoryName: String = "Images",
        customContainerURL: URL? = nil
    ) {
        self.appGroupIdentifier = appGroupIdentifier
        self.databaseFileName = databaseFileName
        self.imagesDirectoryName = imagesDirectoryName
        self.customContainerURL = customContainerURL

        let container = customContainerURL ?? FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        self.sharedContainerURL = container
        self.databaseURL = container?.appendingPathComponent(databaseFileName)
        self.imagesDirectoryURL = container?.appendingPathComponent(imagesDirectoryName)
    }

    /// 校验 App Group 配置是否可写
    public func validate() -> ConfigurationValidationResult {
        guard let containerURL = sharedContainerURL else {
            return .failure(.appGroupNotConfigured(identifier: appGroupIdentifier))
        }
        let testFile = containerURL.appendingPathComponent(".reviewkit_test")
        do {
            try "test".write(to: testFile, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(at: testFile)
        } catch {
            return .failure(.directoryNotWritable(url: containerURL, error: error))
        }
        return .success
    }
}

/// 配置校验结果
public enum ConfigurationValidationResult {
    /// 配置校验通过
    case success
    /// 配置校验失败及原因
    case failure(ConfigurationError)
}

/// 配置校验错误
public enum ConfigurationError: Error, LocalizedError {
    case appGroupNotConfigured(identifier: String)
    case directoryNotWritable(url: URL, error: Error)
    
    /// 人类可读错误描述
    public var errorDescription: String? {
        switch self {
        case .appGroupNotConfigured(let identifier):
            return "App Group '\(identifier)' 未配置。请启用并保持一致。"
        case .directoryNotWritable(let url, let error):
            return "无法写入目录 \(url.path): \(error.localizedDescription)"
        }
    }
}

@available(*, deprecated, message: "Use ReviewKitConfiguration.shared.appGroupIdentifier instead")
@MainActor
/// 兼容旧代码的全局 appGroup 标识符
public var appGroupIdentifier: String {
    ReviewKitConfiguration.shared.appGroupIdentifier
}