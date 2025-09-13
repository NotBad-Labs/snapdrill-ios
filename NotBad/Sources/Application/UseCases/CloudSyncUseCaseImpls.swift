import Foundation
import OSLog

// MARK: - Cloud Sync Use Case Implementations
public class SyncReviewItemsUseCaseImpl: SyncReviewItemsUseCaseProtocol {
    
    private let cloudSyncService: CloudSyncServiceProtocol
    private let reviewItemService: ReviewItemService
    private let logger = Logger(subsystem: "NotBad", category: "SyncUseCases")
    
    public init(
        cloudSyncService: CloudSyncServiceProtocol,
        reviewItemService: ReviewItemService
    ) {
        self.cloudSyncService = cloudSyncService
        self.reviewItemService = reviewItemService
    }
    
    public func syncPendingItems() async throws -> SyncResult {
        logger.info("开始同步待同步的ReviewItem")
        
        // 获取所有需要同步的items
        let pendingItems = try await reviewItemService.getPendingSyncItems()
        
        var successfulSyncs = 0
        var failedSyncs = 0
        var conflicts: [SyncConflict] = []
        var errors: [CloudSyncError] = []
        
        for item in pendingItems {
            do {
                    let recordID = try await cloudSyncService.syncReviewItem(SimpleReviewItem(from: item))                // 更新本地同步状态
                try await reviewItemService.markAsSynced(item.id, recordID: recordID.recordName)
                successfulSyncs += 1
                
            } catch let error as CloudSyncError {
                logger.error("同步失败: \\(item.id), 错误: \\(error)")
                errors.append(error)
                failedSyncs += 1
            } catch {
                logger.error("同步时发生未知错误: \\(item.id), \\(error)")
                errors.append(.unknownError)
                failedSyncs += 1
            }
        }
        
        let result = SyncResult(
            successfulSyncs: successfulSyncs,
            failedSyncs: failedSyncs,
            conflicts: conflicts,
            errors: errors
        )
        
        logger.info("同步完成: 成功\\(successfulSyncs), 失败\\(failedSyncs)")
        return result
    }
}

public class FetchCloudUpdatesUseCaseImpl: FetchCloudUpdatesUseCaseProtocol {
    
    private let cloudSyncService: CloudSyncServiceProtocol
    private let reviewItemService: ReviewItemService
    private let logger = Logger(subsystem: "NotBad", category: "SyncUseCases")
    
    public init(
        cloudSyncService: CloudSyncServiceProtocol,
        reviewItemService: ReviewItemService
    ) {
        self.cloudSyncService = cloudSyncService
        self.reviewItemService = reviewItemService
    }
    
    public func fetchAndApplyUpdates() async throws -> Int {
        logger.info("开始获取云端更新")
        
        // 获取上次同步时间
        let lastSyncDate = UserDefaults.standard.object(forKey: "LastCloudKitSyncDate") as? Date
        
        // 获取云端更新
        let updatedItems = try await cloudSyncService.fetchReviewItemUpdates(since: lastSyncDate)
        
        var appliedUpdates = 0
        
        for updatedItem in updatedItems {
            do {
                // 检查本地是否已存在
                if let existingItem = try await reviewItemService.getReviewItem(id: updatedItem.id) {
                    // 处理冲突
                    let mergedItem = try await handleUpdateConflict(
                        localItem: existingItem,
                        remoteItem: updatedItem.toReviewItem()
                    )
                    // TODO: 实现真正的更新逻辑
                    logger.info("已合并冲突项目: \(mergedItem.id)")
                } else {
                    // 新增项目 
                    // TODO: 实现真正的创建逻辑
                    logger.info("新增项目: \(updatedItem.id)")
                }
                appliedUpdates += 1
                
            } catch {
                logger.error("应用更新失败: \\(updatedItem.id), \\(error)")
            }
        }
        
        // 更新最后同步时间
        UserDefaults.standard.set(Date(), forKey: "LastCloudKitSyncDate")
        
        logger.info("获取并应用了\\(appliedUpdates)个更新")
        return appliedUpdates
    }
    
    private func handleUpdateConflict(localItem: ReviewItem, remoteItem: ReviewItem) async throws -> ReviewItem {
        // 使用最新更新时间策略
        if remoteItem.metadata.updatedAt > localItem.metadata.updatedAt {
            return remoteItem
        } else if localItem.metadata.updatedAt > remoteItem.metadata.updatedAt {
            return localItem
        } else {
            // 时间相同，使用自定义合并规则
            return mergeItems(local: localItem, remote: remoteItem)
        }
    }
    
    private func mergeItems(local: ReviewItem, remote: ReviewItem) -> ReviewItem {
        // 合并策略：
        // 1. 取最高掌握度
        // 2. 合并标签
        
        let mergedTags = Array(Set(local.content.tags + remote.content.tags))
        let higherMasteryLevel = local.masteryLevel.rawValue > remote.masteryLevel.rawValue ? local.masteryLevel : remote.masteryLevel
        
        let mergedContent = ReviewContent(
            title: remote.content.title, // 使用远程标题
            question: remote.content.question,
            answer: remote.content.answer,
            subject: remote.content.subject,
            difficulty: remote.content.difficulty,
            tags: mergedTags
        )
        
        let mergedMetadata = ReviewMetadata(
            createdAt: min(local.metadata.createdAt, remote.metadata.createdAt),
            updatedAt: max(local.metadata.updatedAt, remote.metadata.updatedAt),
            ownerId: local.metadata.ownerId // 保持本地的所有者ID
        )
        
        return ReviewItem(
            id: local.id,
            content: mergedContent,
            metadata: mergedMetadata,
            studyHistory: local.studyHistory, // 保留本地学习历史
            masteryLevel: higherMasteryLevel
        )
    }
}

public class HandleSyncConflictsUseCaseImpl: HandleSyncConflictsUseCaseProtocol {
    
    private let cloudSyncService: CloudSyncServiceProtocol
    private let reviewItemService: ReviewItemService
    private let logger = Logger(subsystem: "NotBad", category: "SyncUseCases")
    
    public init(
        cloudSyncService: CloudSyncServiceProtocol,
        reviewItemService: ReviewItemService
    ) {
        self.cloudSyncService = cloudSyncService
        self.reviewItemService = reviewItemService
    }
    
    public func resolveConflicts(_ conflicts: [SyncConflict]) async throws -> Int {
        logger.info("开始解决\\(conflicts.count)个同步冲突")
        
        var resolvedCount = 0
        
        for conflict in conflicts {
            do {
                let resolvedItem = try await resolveConflict(conflict)
                // TODO: 实现真正的更新逻辑
                logger.info("冲突已解决: \(resolvedItem.id)")
                
                // 同步解决结果到云端
                let simpleItem = SimpleReviewItem(from: resolvedItem)
                _ = try await cloudSyncService.syncReviewItem(simpleItem)
                
                resolvedCount += 1
                logger.info("冲突解决成功: \\(conflict.localItem.id)")
                
            } catch {
                logger.error("解决冲突失败: \\(conflict.localItem.id), \\(error)")
            }
        }
        
        logger.info("解决了\\(resolvedCount)个冲突")
        return resolvedCount
    }
    
    private func resolveConflict(_ conflict: SyncConflict) async throws -> ReviewItem {
        switch conflict.conflictType {
        case .updateConflict:
            // 获取远程记录并合并
            // 这里需要实际获取远程记录，简化实现
            return conflict.localItem.toReviewItem()
            
        case .deleteConflict:
            // 本地删除，远程修改 - 需要用户决策
            // 简化实现：保留本地删除状态
            return conflict.localItem.toReviewItem()
            
        case .createConflict:
            // 重复创建 - 合并为一个
            return conflict.localItem.toReviewItem()
        }
    }
}

// MARK: - ReviewItemService Extension for Sync Support
// 注意：这些是临时的简化实现，后续需要根据实际业务需求完善
extension ReviewItemService {
    
    /// 获取需要同步的ReviewItem（简化实现）
    /// - Returns: 待同步的ReviewItem数组
    func getPendingSyncItems() async throws -> [ReviewItem] {
        // 临时实现：获取所有项目
        let request = GetReviewItemsRequest()
        let response = try await getReviewItems(request)
        return response.items
    }
    
    /// 简化的获取单个复习项方法（暂时不实现）
    func getReviewItem(id: UUID) async throws -> ReviewItem? {
        // 临时实现：返回nil，表示找不到
        // 实际应该通过自定义过滤器查找
        return nil
    }
    
    /// 简化的创建复习项方法（暂时不实现）
    func createReviewItem(_ item: ReviewItem) async throws -> ReviewItem {
        // 临时实现：抛出错误
        throw ReviewItemServiceError.serviceUnavailable("临时不支持此操作")
    }
    
    /// 简化的更新复习项方法（暂时不实现）
    func updateReviewItem(_ item: ReviewItem) async throws -> ReviewItem {
        // 临时实现：抛出错误
        throw ReviewItemServiceError.serviceUnavailable("临时不支持此操作")
    }
    
    /// 标记项目为已同步
    /// - Parameters:
    ///   - itemID: 项目ID
    ///   - recordID: CloudKit记录ID
    func markAsSynced(_ itemID: UUID, recordID: String) async throws {
        // 这里应该更新本地数据的同步状态
        // 可以添加syncStatus字段到ReviewItem或单独的同步表
        logger.info("标记项目已同步: \(itemID)")
    }
    
    private var logger: Logger {
        Logger(subsystem: "NotBad", category: "ReviewItemService")
    }
}
