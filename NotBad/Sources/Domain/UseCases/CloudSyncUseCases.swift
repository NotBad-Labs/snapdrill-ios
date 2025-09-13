import Foundation

// MARK: - Cloud Sync Use Cases
public protocol SyncReviewItemsUseCaseProtocol {
    /// 同步所有待同步的ReviewItem到云端
    /// - Returns: 同步结果统计
    func syncPendingItems() async throws -> SyncResult
}

public protocol FetchCloudUpdatesUseCaseProtocol {
    /// 从云端获取更新并应用到本地
    /// - Returns: 获取到的更新数量
    func fetchAndApplyUpdates() async throws -> Int
}

public protocol HandleSyncConflictsUseCaseProtocol {
    /// 处理同步冲突
    /// - Parameter conflicts: 冲突列表
    /// - Returns: 解决的冲突数量
    func resolveConflicts(_ conflicts: [SyncConflict]) async throws -> Int
}

// MARK: - Sync Models
public struct SyncResult {
    public let successfulSyncs: Int
    public let failedSyncs: Int
    public let conflicts: [SyncConflict]
    public let errors: [CloudSyncError]
    
    public init(
        successfulSyncs: Int = 0,
        failedSyncs: Int = 0,
        conflicts: [SyncConflict] = [],
        errors: [CloudSyncError] = []
    ) {
        self.successfulSyncs = successfulSyncs
        self.failedSyncs = failedSyncs
        self.conflicts = conflicts
        self.errors = errors
    }
    
    public var isSuccess: Bool {
        return failedSyncs == 0 && conflicts.isEmpty && errors.isEmpty
    }
}

public struct SyncConflict {
    public let localItem: SimpleReviewItem
    public let remoteRecordID: String
    public let conflictType: ConflictType
    public let timestamp: Date
    
    public init(
        localItem: SimpleReviewItem,
        remoteRecordID: String,
        conflictType: ConflictType,
        timestamp: Date = Date()
    ) {
        self.localItem = localItem
        self.remoteRecordID = remoteRecordID
        self.conflictType = conflictType
        self.timestamp = timestamp
    }
}

public enum ConflictType: CaseIterable {
    case updateConflict     // 同时修改
    case deleteConflict     // 本地删除，远程修改
    case createConflict     // 重复创建
    
    public var description: String {
        switch self {
        case .updateConflict:
            return "同时修改冲突"
        case .deleteConflict:
            return "删除冲突"
        case .createConflict:
            return "创建冲突"
        }
    }
}
