//
//  ModuleProtocols.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//

import Foundation

// MARK: - 模块间通信协议
/// 定义所有模块间的通信协议，实现高度解耦的架构设计
/// 遵循Clean Architecture的接口驱动设计原则

// MARK: - 核心实体协议
/// 所有领域实体的基础协议
protocol DomainEntity: Identifiable, Equatable, Hashable {
    associatedtype ID: Hashable
    var id: ID { get }
}

// MARK: - 仓储协议
/// 数据访问层的基础协议
protocol Repository {
    associatedtype Entity: DomainEntity
    associatedtype ID = Entity.ID
    associatedtype Error: RepositoryError
}

/// 仓储错误协议
protocol RepositoryError: Error, LocalizedError {
    static func notFound(id: Any) -> Self
    static func invalidData(_ message: String) -> Self
    static func storageError(_ message: String) -> Self
    static func networkError(_ message: String) -> Self
    static func permissionDenied(_ message: String) -> Self
}

// MARK: - 用例协议
/// 业务用例的基础协议
protocol UseCase {
    associatedtype Request
    associatedtype Response
    associatedtype Error: UseCaseError
    
    func execute(_ request: Request) async throws -> Response
}

/// 用例错误协议
protocol UseCaseError: Error, LocalizedError {
    static func validationFailed(_ message: String) -> Self
    static func businessRuleViolation(_ message: String) -> Self
    static func repositoryError(_ message: String) -> Self
}

// MARK: - 服务协议
/// 业务服务的基础协议
protocol Service {
    associatedtype Error: ServiceError
}

/// 服务错误协议
protocol ServiceError: Error, LocalizedError {
    static func serviceUnavailable(_ message: String) -> Self
    static func configurationError(_ message: String) -> Self
    static func externalServiceError(_ message: String) -> Self
}

// MARK: - 事件协议
/// 模块间事件通信协议
protocol DomainEvent {
    var eventId: UUID { get }
    var timestamp: Date { get }
    var eventType: String { get }
}

/// 事件发布者协议
protocol EventPublisher {
    func publish<T: DomainEvent>(_ event: T) async
}

/// 事件订阅者协议
protocol EventSubscriber {
    associatedtype Event: DomainEvent
    func handle(_ event: Event) async
}

// MARK: - 依赖注入协议
/// 依赖注入容器协议
protocol DependencyContainer {
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    func resolve<T>(_ type: T.Type) -> T?
}

// MARK: - 配置协议
/// 应用配置协议
protocol AppConfiguration {
    var environment: Environment { get }
    var apiBaseURL: String { get }
    var encryptionKey: String { get }
    var cloudKitContainer: String { get }
}

/// 环境枚举
enum Environment: String, CaseIterable {
    case development = "development"
    case staging = "staging"
    case production = "production"
    
    var displayName: String {
        switch self {
        case .development:
            return "开发环境"
        case .staging:
            return "测试环境"
        case .production:
            return "生产环境"
        }
    }
}

// MARK: - 日志协议
/// 日志记录协议
protocol Logger {
    func debug(_ message: String, file: String, function: String, line: Int)
    func info(_ message: String, file: String, function: String, line: Int)
    func warning(_ message: String, file: String, function: String, line: Int)
    func error(_ message: String, file: String, function: String, line: Int)
    func fatal(_ message: String, file: String, function: String, line: Int)
}

// MARK: - 监控协议
/// 性能监控协议
protocol PerformanceMonitor {
    func startTimer(_ name: String) -> TimerHandle
    func stopTimer(_ handle: TimerHandle)
    func recordMetric(_ name: String, value: Double)
    func recordEvent(_ name: String, properties: [String: Any]?)
}

/// 计时器句柄
protocol TimerHandle {
    var name: String { get }
    var startTime: Date { get }
}

// MARK: - 缓存协议
/// 缓存服务协议
protocol CacheService {
    associatedtype Key: Hashable
    associatedtype Value
    
    func get<T>(_ key: Key, as type: T.Type) async -> T?
    func set<T>(_ key: Key, value: T, expiration: TimeInterval?) async
    func remove(_ key: Key) async
    func clear() async
}

// MARK: - 网络协议
/// 网络服务协议
protocol NetworkService {
    func request<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T
    func upload<T: Codable>(_ endpoint: APIEndpoint, data: Data, responseType: T.Type) async throws -> T
    func download(_ endpoint: APIEndpoint) async throws -> Data
}

/// API端点协议
protocol APIEndpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var parameters: [String: Any]? { get }
}

/// HTTP方法枚举
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - 加密协议
/// 加密服务协议
protocol EncryptionService {
    func encrypt(_ data: Data) throws -> Data
    func decrypt(_ encryptedData: Data) throws -> Data
    func encrypt(_ string: String) throws -> String
    func decrypt(_ encryptedString: String) throws -> String
}

// MARK: - 文件管理协议
/// 文件管理服务协议
protocol FileManagerService {
    func save(_ data: Data, to path: String) throws
    func load(from path: String) throws -> Data
    func delete(at path: String) throws
    func exists(at path: String) -> Bool
    func createDirectory(at path: String) throws
}

// MARK: - 通知协议
/// 通知服务协议
protocol NotificationService {
    func schedule(_ notification: LocalNotification) async throws
    func cancel(_ notificationId: String) async
    func requestPermission() async -> Bool
}

/// 本地通知结构
struct LocalNotification {
    let id: String
    let title: String
    let body: String
    let triggerDate: Date
    let userInfo: [String: Any]?
}