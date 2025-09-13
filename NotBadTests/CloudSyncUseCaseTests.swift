import XCTest
@testable import NotBad

class CloudSyncUseCaseTests: XCTestCase {
    
    var mockCloudSyncService: MockCloudSyncService!
    var mockReviewItemService: MockReviewItemService!
    var syncUseCase: SyncReviewItemsUseCaseImpl!
    var fetchUseCase: FetchCloudUpdatesUseCaseImpl!
    var conflictUseCase: HandleSyncConflictsUseCaseImpl!
    
    override func setUp() {
        super.setUp()
        
        mockCloudSyncService = MockCloudSyncService()
        mockReviewItemService = MockReviewItemService()
        
        syncUseCase = SyncReviewItemsUseCaseImpl(
            cloudSyncService: mockCloudSyncService,
            reviewItemService: mockReviewItemService
        )
        
        fetchUseCase = FetchCloudUpdatesUseCaseImpl(
            cloudSyncService: mockCloudSyncService,
            reviewItemService: mockReviewItemService
        )
        
        conflictUseCase = HandleSyncConflictsUseCaseImpl(
            cloudSyncService: mockCloudSyncService,
            reviewItemService: mockReviewItemService
        )
    }
    
    override func tearDown() {
        syncUseCase = nil
        fetchUseCase = nil
        conflictUseCase = nil
        mockReviewItemService = nil
        mockCloudSyncService = nil
        super.tearDown()
    }
    
    // MARK: - Sync Pending Items Tests
    
    func testSyncPendingItemsSuccess() async throws {
        // Given
        let testItem1 = createTestReviewItem(title: "测试题目1")
        let testItem2 = createTestReviewItem(title: "测试题目2")
        
        mockReviewItemService.pendingSyncItems = [testItem1, testItem2]
        mockCloudSyncService.syncResults = [
            testItem1.id: .success("record1"),
            testItem2.id: .success("record2")
        ]
        
        // When
        let result = try await syncUseCase.syncPendingItems()
        
        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.successfulSyncs, 2)
        XCTAssertEqual(result.failedSyncs, 0)
        XCTAssertTrue(result.conflicts.isEmpty)
        XCTAssertTrue(result.errors.isEmpty)
        
        XCTAssertEqual(mockReviewItemService.markedAsSyncedItems.count, 2)
        XCTAssertTrue(mockReviewItemService.markedAsSyncedItems.contains(testItem1.id))
        XCTAssertTrue(mockReviewItemService.markedAsSyncedItems.contains(testItem2.id))
    }
    
    func testSyncPendingItemsWithFailures() async throws {
        // Given
        let testItem1 = createTestReviewItem(title: "成功题目")
        let testItem2 = createTestReviewItem(title: "失败题目")
        
        mockReviewItemService.pendingSyncItems = [testItem1, testItem2]
        mockCloudSyncService.syncResults = [
            testItem1.id: .success("record1"),
            testItem2.id: .failure(CloudSyncError.networkUnavailable)
        ]
        
        // When
        let result = try await syncUseCase.syncPendingItems()
        
        // Then
        XCTAssertFalse(result.isSuccess)
        XCTAssertEqual(result.successfulSyncs, 1)
        XCTAssertEqual(result.failedSyncs, 1)
        XCTAssertEqual(result.errors.count, 1)
        XCTAssertEqual(result.errors.first, .networkUnavailable)
        
        XCTAssertEqual(mockReviewItemService.markedAsSyncedItems.count, 1)
        XCTAssertTrue(mockReviewItemService.markedAsSyncedItems.contains(testItem1.id))
    }
    
    // MARK: - Fetch Cloud Updates Tests
    
    func testFetchAndApplyUpdatesNewItems() async throws {
        // Given
        let remoteItem1 = createTestReviewItem(title: "远程题目1")
        let remoteItem2 = createTestReviewItem(title: "远程题目2")
        
        mockCloudSyncService.cloudUpdates = [remoteItem1, remoteItem2]
        mockReviewItemService.existingItems = [:] // 本地不存在这些项目
        
        // When
        let updateCount = try await fetchUseCase.fetchAndApplyUpdates()
        
        // Then
        XCTAssertEqual(updateCount, 2)
        XCTAssertEqual(mockReviewItemService.createdItems.count, 2)
        XCTAssertTrue(mockReviewItemService.createdItems.contains { $0.title == "远程题目1" })
        XCTAssertTrue(mockReviewItemService.createdItems.contains { $0.title == "远程题目2" })
    }
    
    func testFetchAndApplyUpdatesExistingItems() async throws {
        // Given
        let baseDate = Date()
        let localItem = createTestReviewItem(
            title: "本地题目",
            updatedAt: baseDate
        )
        let remoteItem = createTestReviewItem(
            title: "更新的题目",
            id: localItem.id,
            updatedAt: baseDate.addingTimeInterval(3600) // 1小时后更新
        )
        
        mockCloudSyncService.cloudUpdates = [remoteItem]
        mockReviewItemService.existingItems = [localItem.id: localItem]
        
        // When
        let updateCount = try await fetchUseCase.fetchAndApplyUpdates()
        
        // Then
        XCTAssertEqual(updateCount, 1)
        XCTAssertEqual(mockReviewItemService.updatedItems.count, 1)
        XCTAssertEqual(mockReviewItemService.updatedItems.first?.title, "更新的题目")
    }
    
    func testFetchAndApplyUpdatesConflictResolution() async throws {
        // Given
        let baseDate = Date()
        let localItem = createTestReviewItem(
            title: "本地题目",
            masteryLevel: .learned,
            tags: ["本地标签", "共同标签"],
            updatedAt: baseDate.addingTimeInterval(1800) // 30分钟后
        )
        let remoteItem = createTestReviewItem(
            title: "远程题目",
            id: localItem.id,
            masteryLevel: .practicing,
            tags: ["远程标签", "共同标签"],
            updatedAt: baseDate.addingTimeInterval(3600) // 1小时后
        )
        
        mockCloudSyncService.cloudUpdates = [remoteItem]
        mockReviewItemService.existingItems = [localItem.id: localItem]
        
        // When
        let updateCount = try await fetchUseCase.fetchAndApplyUpdates()
        
        // Then
        XCTAssertEqual(updateCount, 1)
        XCTAssertEqual(mockReviewItemService.updatedItems.count, 1)
        
        let mergedItem = mockReviewItemService.updatedItems.first!
        XCTAssertEqual(mergedItem.title, "远程题目") // 远程更新时间更晚
        XCTAssertEqual(mergedItem.masteryLevel, .learned) // 保留更高掌握度
        XCTAssertTrue(mergedItem.tags.contains("本地标签"))
        XCTAssertTrue(mergedItem.tags.contains("远程标签"))
        XCTAssertTrue(mergedItem.tags.contains("共同标签"))
    }
    
    // MARK: - Handle Sync Conflicts Tests
    
    func testResolveConflicts() async throws {
        // Given
        let conflictItem1 = createTestReviewItem(title: "冲突题目1")
        let conflictItem2 = createTestReviewItem(title: "冲突题目2")
        
        let conflicts = [
            SyncConflict(
                localItem: conflictItem1,
                remoteRecordID: "remote1",
                conflictType: .updateConflict
            ),
            SyncConflict(
                localItem: conflictItem2,
                remoteRecordID: "remote2",
                conflictType: .updateConflict
            )
        ]
        
        mockCloudSyncService.syncResults = [
            conflictItem1.id: .success("resolved1"),
            conflictItem2.id: .success("resolved2")
        ]
        
        // When
        let resolvedCount = try await conflictUseCase.resolveConflicts(conflicts)
        
        // Then
        XCTAssertEqual(resolvedCount, 2)
        XCTAssertEqual(mockReviewItemService.updatedItems.count, 2)
        XCTAssertEqual(mockCloudSyncService.syncCallCount, 2)
    }
    
    func testResolveConflictsWithFailures() async throws {
        // Given
        let conflictItem1 = createTestReviewItem(title: "成功冲突")
        let conflictItem2 = createTestReviewItem(title: "失败冲突")
        
        let conflicts = [
            SyncConflict(
                localItem: conflictItem1,
                remoteRecordID: "remote1",
                conflictType: .updateConflict
            ),
            SyncConflict(
                localItem: conflictItem2,
                remoteRecordID: "remote2",
                conflictType: .updateConflict
            )
        ]
        
        mockCloudSyncService.syncResults = [
            conflictItem1.id: .success("resolved1"),
            conflictItem2.id: .failure(CloudSyncError.conflictResolutionFailed)
        ]
        
        // When
        let resolvedCount = try await conflictUseCase.resolveConflicts(conflicts)
        
        // Then
        XCTAssertEqual(resolvedCount, 1) // 只有一个成功解决
        XCTAssertEqual(mockReviewItemService.updatedItems.count, 2) // 但两个都尝试更新了
    }
    
    // MARK: - Helper Methods
    
    private func createTestReviewItem(
        title: String,
        id: UUID = UUID(),
        masteryLevel: MasteryLevel = .reviewing,
        tags: [String] = [],
        updatedAt: Date = Date()
    ) -> ReviewItem {
        return ReviewItem(
            id: id,
            title: title,
            questionText: "测试题目内容",
            answerText: "测试答案内容",
            subject: "数学",
            difficultyLevel: .medium,
            masteryLevel: masteryLevel,
            tags: tags,
            imageURLs: [],
            createdAt: Date(),
            updatedAt: updatedAt
        )
    }
}

// MARK: - Mock Services

class MockCloudSyncService: CloudSyncServiceProtocol {
    var syncResults: [UUID: Result<String, CloudSyncError>] = [:]
    var cloudUpdates: [ReviewItem] = []
    var syncCallCount = 0
    
    func initialize(container: CKContainer, database: CKDatabase) async throws {
        // Mock implementation
    }
    
    func syncReviewItem(_ item: ReviewItem) async throws -> CKRecord.ID {
        syncCallCount += 1
        
        if let result = syncResults[item.id] {
            switch result {
            case .success(let recordName):
                return CKRecord.ID(recordName: recordName)
            case .failure(let error):
                throw error
            }
        }
        
        return CKRecord.ID(recordName: "default-record")
    }
    
    func fetchReviewItemUpdates(since lastSyncDate: Date?) async throws -> [ReviewItem] {
        return cloudUpdates
    }
    
    func deleteReviewItem(recordID: CKRecord.ID) async throws {
        // Mock implementation
    }
    
    func resolveConflict(localItem: ReviewItem, remoteRecord: CKRecord) async throws -> ReviewItem {
        return localItem
    }
    
    func checkCloudKitAvailability() async throws -> Bool {
        return true
    }
    
    func getSyncStatus() async -> CloudSyncStatus {
        return CloudSyncStatus(isConnected: true)
    }
}

class MockReviewItemService: ReviewItemServiceProtocol {
    var pendingSyncItems: [ReviewItem] = []
    var existingItems: [UUID: ReviewItem] = [:]
    var createdItems: [ReviewItem] = []
    var updatedItems: [ReviewItem] = []
    var markedAsSyncedItems: Set<UUID> = []
    
    func createReviewItem(_ item: ReviewItem) async throws -> ReviewItem {
        createdItems.append(item)
        return item
    }
    
    func getReviewItem(id: UUID) async throws -> ReviewItem? {
        return existingItems[id]
    }
    
    func getAllReviewItems() async throws -> [ReviewItem] {
        return Array(existingItems.values) + pendingSyncItems
    }
    
    func updateReviewItem(_ item: ReviewItem) async throws -> ReviewItem {
        updatedItems.append(item)
        existingItems[item.id] = item
        return item
    }
    
    func deleteReviewItem(id: UUID) async throws {
        existingItems.removeValue(forKey: id)
    }
    
    func searchReviewItems(query: String, filters: [ReviewItemFilter]) async throws -> [ReviewItem] {
        return []
    }
    
    func getReviewItemsBySubject(_ subject: String) async throws -> [ReviewItem] {
        return []
    }
    
    func getReviewItemsByMasteryLevel(_ level: MasteryLevel) async throws -> [ReviewItem] {
        return []
    }
    
    func markAsSynced(_ itemID: UUID, recordID: String) async throws {
        markedAsSyncedItems.insert(itemID)
    }
    
    func getPendingSyncItems() async throws -> [ReviewItem] {
        return pendingSyncItems
    }
}
