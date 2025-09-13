import Foundation
import CloudKit

// MARK: - Cloud Sync Service Protocol
public protocol CloudSyncServiceProtocol {
    /// 初始化CloudKit同步服务
    /// - Parameters:
    ///   - container: CloudKit容器
    ///   - database: CloudKit数据库类型
    func initialize(container: CKContainer, database: CKDatabase) async throws
    
    /// 同步SimpleReviewItem到云端
    /// - Parameter item: 需要同步的SimpleReviewItem
    /// - Returns: 同步后的CloudKit记录ID
    func syncReviewItem(_ item: SimpleReviewItem) async throws -> CKRecord.ID
    
    /// 从云端获取SimpleReviewItem更新
    /// - Parameter lastSyncDate: 上次同步时间戳
    /// - Returns: 更新的SimpleReviewItem数组
    func fetchReviewItemUpdates(since lastSyncDate: Date?) async throws -> [SimpleReviewItem]
    
    /// 删除云端SimpleReviewItem
    /// - Parameter recordID: CloudKit记录ID
    func deleteReviewItem(recordID: CKRecord.ID) async throws
    
    /// 解决同步冲突
    /// - Parameters:
    ///   - localItem: 本地SimpleReviewItem
    ///   - remoteRecord: 远程CloudKit记录
    /// - Returns: 解决冲突后的SimpleReviewItem
    func resolveConflict(localItem: SimpleReviewItem, remoteRecord: CKRecord) async throws -> SimpleReviewItem
    
    /// 检查CloudKit可用性
    /// - Returns: 是否可用
    func checkCloudKitAvailability() async throws -> Bool
    
    /// 获取同步状态
    /// - Returns: 同步状态信息
    func getSyncStatus() async -> CloudSyncStatus
}

// MARK: - Cloud Sync Status
public struct CloudSyncStatus {
    public let isConnected: Bool
    public let lastSyncDate: Date?
    public let pendingUploads: Int
    public let pendingDownloads: Int
    public let syncErrors: [CloudSyncError]
    
    public init(
        isConnected: Bool,
        lastSyncDate: Date? = nil,
        pendingUploads: Int = 0,
        pendingDownloads: Int = 0,
        syncErrors: [CloudSyncError] = []
    ) {
        self.isConnected = isConnected
        self.lastSyncDate = lastSyncDate
        self.pendingUploads = pendingUploads
        self.pendingDownloads = pendingDownloads
        self.syncErrors = syncErrors
    }
}

// MARK: - Cloud Sync Error Types
public enum CloudSyncError: Error, CaseIterable {
    case cloudKitUnavailable
    case accountNotAuthenticated
    case networkUnavailable
    case quotaExceeded
    case recordNotFound
    case conflictResolutionFailed
    case permissionDenied
    case serverRecordChanged
    case unknownError
    
    public var localizedDescription: String {
        switch self {
        case .cloudKitUnavailable:
            return "CloudKit服务不可用"
        case .accountNotAuthenticated:
            return "iCloud账户未登录"
        case .networkUnavailable:
            return "网络连接不可用"
        case .quotaExceeded:
            return "iCloud存储空间不足"
        case .recordNotFound:
            return "记录未找到"
        case .conflictResolutionFailed:
            return "冲突解决失败"
        case .permissionDenied:
            return "权限被拒绝"
        case .serverRecordChanged:
            return "服务器记录已更改"
        case .unknownError:
            return "未知错误"
        }
    }
}

// MARK: - Sync Configuration
public struct CloudSyncConfiguration {
    public let batchSize: Int
    public let conflictResolutionStrategy: ConflictResolutionStrategy
    public let autoSyncInterval: TimeInterval
    public let retryAttempts: Int
    
    public init(
        batchSize: Int = 50,
        conflictResolutionStrategy: ConflictResolutionStrategy = .newestWins,
        autoSyncInterval: TimeInterval = 300, // 5 minutes
        retryAttempts: Int = 3
    ) {
        self.batchSize = batchSize
        self.conflictResolutionStrategy = conflictResolutionStrategy
        self.autoSyncInterval = autoSyncInterval
        self.retryAttempts = retryAttempts
    }
}

// MARK: - Conflict Resolution Strategy
public enum ConflictResolutionStrategy: CaseIterable {
    case newestWins       // 最新时间戳获胜
    case localWins        // 本地数据优先
    case remoteWins       // 远程数据优先
    case customMerge      // 自定义合并规则
    
    public var description: String {
        switch self {
        case .newestWins:
            return "最新修改时间优先"
        case .localWins:
            return "本地数据优先"
        case .remoteWins:
            return "远程数据优先"
        case .customMerge:
            return "智能合并"
        }
    }
}
