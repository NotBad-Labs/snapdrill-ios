import Foundation
import CloudKit
import OSLog

// M        logger.info("获取SimpleReviewItem更新，上次同步时间: \(lastSyncDate?.description ?? "首次")")RK: - CloudKit Sync Service Implementation
public class CloudKitSyncService: CloudSyncServiceProtocol {
    
    // MARK: - Properties
    private var container: CKContainer
    private var database: CKDatabase
    private let configuration: CloudSyncConfiguration
    private let logger = Logger(subsystem: "NotBad", category: "CloudKitSync")
    
    // Record type constants
    private static let reviewItemRecordType = "ReviewItem"
    private static let syncMetadataRecordType = "SyncMetadata"
    
    // MARK: - Initialization
    public init(configuration: CloudSyncConfiguration = CloudSyncConfiguration()) {
        self.container = CKContainer.default()
        self.database = container.privateCloudDatabase
        self.configuration = configuration
    }
    
    // MARK: - CloudSyncServiceProtocol Implementation
    public func initialize(container: CKContainer, database: CKDatabase) async throws {
        self.container = container
        self.database = database
        
        // 检查CloudKit可用性
        let isAvailable = try await checkCloudKitAvailability()
        guard isAvailable else {
            throw CloudSyncError.cloudKitUnavailable
        }
        
        logger.info("CloudKit同步服务初始化成功")
    }
    
    public func syncReviewItem(_ item: SimpleReviewItem) async throws -> CKRecord.ID {
        logger.info("开始同步SimpleReviewItem: \\(item.id)")
        
        // 创建或更新CloudKit记录
        let record = try await createOrUpdateRecord(from: item)
        
        // 保存到CloudKit
        let savedRecord = try await database.save(record)
        
        logger.info("SimpleReviewItem同步成功: \\(savedRecord.recordID)")
        return savedRecord.recordID
    }
    
    public func fetchReviewItemUpdates(since lastSyncDate: Date?) async throws -> [SimpleReviewItem] {
        logger.info("获取SimpleReviewItem更新，上次同步时间: \(lastSyncDate?.description ?? "首次")")
        
        let predicate: NSPredicate
        if let lastSyncDate = lastSyncDate {
            predicate = NSPredicate(format: "modificationDate > %@", lastSyncDate as CVarArg)
        } else {
            predicate = NSPredicate(value: true)
        }
        
        let query = CKQuery(recordType: Self.reviewItemRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: true)]
        
        let results = try await database.records(matching: query)
        var reviewItems: [SimpleReviewItem] = []
        
        for (recordID, result) in results.matchResults {
            switch result {
            case .success(let record):
                if let reviewItem = try await convertRecordToReviewItem(record) {
                    reviewItems.append(reviewItem)
                }
            case .failure(let error):
                logger.error("获取记录失败: \\(recordID), 错误: \\(error)")
            }
        }
        
        logger.info("获取到\\(reviewItems.count)个更新的SimpleReviewItem")
        return reviewItems
    }
    
    public func deleteReviewItem(recordID: CKRecord.ID) async throws {
        logger.info("删除ReviewItem: \\(recordID)")
        
        try await database.deleteRecord(withID: recordID)
        
        logger.info("ReviewItem删除成功: \\(recordID)")
    }
    
    public func resolveConflict(localItem: SimpleReviewItem, remoteRecord: CKRecord) async throws -> SimpleReviewItem {
        logger.info("解决冲突: 本地ID \\(localItem.id), 远程记录 \\(remoteRecord.recordID)")
        
        switch configuration.conflictResolutionStrategy {
        case .newestWins:
            return try await resolveConflictNewestWins(localItem: localItem, remoteRecord: remoteRecord)
        case .localWins:
            return localItem
        case .remoteWins:
            return try await convertRecordToReviewItem(remoteRecord) ?? localItem
        case .customMerge:
            return try await resolveConflictCustomMerge(localItem: localItem, remoteRecord: remoteRecord)
        }
    }
    
    public func checkCloudKitAvailability() async throws -> Bool {
        do {
            let accountStatus = try await container.accountStatus()
            switch accountStatus {
            case .available:
                return true
            case .noAccount:
                throw CloudSyncError.accountNotAuthenticated
            case .restricted:
                throw CloudSyncError.permissionDenied
            case .couldNotDetermine:
                throw CloudSyncError.unknownError
            case .temporarilyUnavailable:
                throw CloudSyncError.cloudKitUnavailable
            @unknown default:
                throw CloudSyncError.unknownError
            }
        } catch {
            if let cloudSyncError = error as? CloudSyncError {
                throw cloudSyncError
            } else {
                throw CloudSyncError.cloudKitUnavailable
            }
        }
    }
    
    public func getSyncStatus() async -> CloudSyncStatus {
        // 检查连接状态
        let isConnected = (try? await checkCloudKitAvailability()) ?? false
        
        // 获取上次同步时间 (从UserDefaults或本地存储获取)
        let lastSyncDate = UserDefaults.standard.object(forKey: "LastCloudKitSyncDate") as? Date
        
        // 这里应该从实际的同步队列获取pending计数
        // 简化实现，返回默认值
        return CloudSyncStatus(
            isConnected: isConnected,
            lastSyncDate: lastSyncDate,
            pendingUploads: 0,
            pendingDownloads: 0,
            syncErrors: []
        )
    }
}

// MARK: - Private Helper Methods
private extension CloudKitSyncService {
    
    func createOrUpdateRecord(from item: SimpleReviewItem) async throws -> CKRecord {
        // 尝试获取现有记录
        let recordID = CKRecord.ID(recordName: item.id.uuidString)
        
        let record: CKRecord
        do {
            record = try await database.record(for: recordID)
        } catch {
            // 记录不存在，创建新记录
            record = CKRecord(recordType: Self.reviewItemRecordType, recordID: recordID)
        }
        
        // 设置记录字段
        record["title"] = item.title
        record["questionText"] = item.questionText
        record["answerText"] = item.answerText
        record["subject"] = item.subject
        record["difficultyLevel"] = item.difficultyLevel.rawValue
        record["masteryLevel"] = item.masteryLevel.rawValue
        record["tags"] = item.tags
        record["createdAt"] = item.createdAt
        record["updatedAt"] = item.updatedAt
        record["lastReviewedAt"] = item.lastReviewedAt
        
        // 处理图片数据 (如果有)
        if !item.imageURLs.isEmpty {
            // 这里需要实现图片上传到CloudKit Assets
            // 简化实现，先存储URL字符串
            record["imageURLs"] = item.imageURLs
        }
        
        return record
    }
    
    func convertRecordToReviewItem(_ record: CKRecord) async throws -> SimpleReviewItem? {
        guard let title = record["title"] as? String,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            logger.error("记录格式无效: \\(record.recordID)")
            return nil
        }
        
        let reviewItem = SimpleReviewItem(
            id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
            title: title,
            questionText: record["questionText"] as? String ?? "",
            answerText: record["answerText"] as? String ?? "",
            subject: record["subject"] as? String ?? "",
            difficultyLevel: DifficultyLevel(rawValue: record["difficultyLevel"] as? String ?? "") ?? .medium,
            masteryLevel: MasteryLevel(rawValue: record["masteryLevel"] as? String ?? "") ?? .notMastered,
            tags: record["tags"] as? [String] ?? [],
            imageURLs: record["imageURLs"] as? [String] ?? [],
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastReviewedAt: record["lastReviewedAt"] as? Date
        )
        
        return reviewItem
    }
    
    func convertStringArrayToURLs(_ strings: [String]) -> [URL] {
        return strings.compactMap { URL(string: $0) }
    }
    
    func resolveConflictNewestWins(localItem: SimpleReviewItem, remoteRecord: CKRecord) async throws -> SimpleReviewItem {
        guard let remoteUpdatedAt = remoteRecord["updatedAt"] as? Date else {
            return localItem
        }
        
        if remoteUpdatedAt > localItem.updatedAt {
            return try await convertRecordToReviewItem(remoteRecord) ?? localItem
        } else {
            return localItem
        }
    }
    
    func resolveConflictCustomMerge(localItem: SimpleReviewItem, remoteRecord: CKRecord) async throws -> SimpleReviewItem {
        // 实现自定义合并逻辑
        // 根据ADR-002的策略：
        // - 取最新的updatedAt
        // - 合并tags去重
        // - 取最大掌握度等级
        
        guard let remoteItem = try await convertRecordToReviewItem(remoteRecord) else {
            return localItem
        }
        
        let newerUpdatedAt = max(localItem.updatedAt, remoteItem.updatedAt)
        let mergedTags = Array(Set(localItem.tags + remoteItem.tags))
        let higherMasteryLevel = localItem.masteryLevel.rawValue > remoteItem.masteryLevel.rawValue ? localItem.masteryLevel : remoteItem.masteryLevel
        let latestReviewDate = [localItem.lastReviewedAt, remoteItem.lastReviewedAt].compactMap { $0 }.max()
        
        // 选择最新修改的内容作为主要内容
        let baseItem = newerUpdatedAt == localItem.updatedAt ? localItem : remoteItem
        
        return SimpleReviewItem(
            id: baseItem.id,
            title: baseItem.title,
            questionText: baseItem.questionText,
            answerText: baseItem.answerText,
            subject: baseItem.subject,
            difficultyLevel: baseItem.difficultyLevel,
            masteryLevel: higherMasteryLevel,
            tags: mergedTags,
            imageURLs: baseItem.imageURLs,
            createdAt: min(localItem.createdAt, remoteItem.createdAt),
            updatedAt: newerUpdatedAt,
            lastReviewedAt: latestReviewDate
        )
    }
}
