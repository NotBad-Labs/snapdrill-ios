import XCTest
import CloudKit
@testable import NotBad

class CloudSyncServiceTests: XCTestCase {
    
    var mockContainer: MockCKContainer!
    var mockDatabase: MockCKDatabase!
    var syncService: CloudKitSyncService!
    var testReviewItem: ReviewItem!
    
    override func setUp() {
        super.setUp()
        
        mockContainer = MockCKContainer()
        mockDatabase = MockCKDatabase()
        syncService = CloudKitSyncService()
        
        // 创建测试用的ReviewItem
        testReviewItem = ReviewItem(
            title: "测试错题",
            questionText: "这是一道测试题目",
            answerText: "这是测试答案",
            subject: "数学",
            difficultyLevel: .medium,
            masteryLevel: .reviewing,
            tags: ["代数", "方程"],
            imageURLs: []
        )
    }
    
    override func tearDown() {
        syncService = nil
        testReviewItem = nil
        mockDatabase = nil
        mockContainer = nil
        super.tearDown()
    }
    
    // MARK: - CloudKit Availability Tests
    
    func testCheckCloudKitAvailability() async throws {
        // Given
        mockContainer.accountStatus = .available
        
        // When
        try await syncService.initialize(container: mockContainer, database: mockDatabase)
        let isAvailable = try await syncService.checkCloudKitAvailability()
        
        // Then
        XCTAssertTrue(isAvailable)
    }
    
    func testCloudKitUnavailable() async throws {
        // Given
        mockContainer.accountStatus = .noAccount
        
        // When & Then
        do {
            _ = try await syncService.checkCloudKitAvailability()
            XCTFail("应该抛出CloudSyncError.accountNotAuthenticated")
        } catch CloudSyncError.accountNotAuthenticated {
            // Expected
        } catch {
            XCTFail("抛出了意外的错误: \\(error)")
        }
    }
    
    // MARK: - Sync Tests
    
    func testSyncReviewItemSuccess() async throws {
        // Given
        mockContainer.accountStatus = .available
        try await syncService.initialize(container: mockContainer, database: mockDatabase)
        
        let expectedRecordID = CKRecord.ID(recordName: testReviewItem.id.uuidString)
        mockDatabase.saveResult = .success(CKRecord(recordType: "ReviewItem", recordID: expectedRecordID))
        
        // When
        let recordID = try await syncService.syncReviewItem(testReviewItem)
        
        // Then
        XCTAssertEqual(recordID.recordName, testReviewItem.id.uuidString)
        XCTAssertTrue(mockDatabase.saveWasCalled)
    }
    
    func testFetchReviewItemUpdates() async throws {
        // Given
        mockContainer.accountStatus = .available
        try await syncService.initialize(container: mockContainer, database: mockDatabase)
        
        // 模拟CloudKit返回的记录
        let record = CKRecord(recordType: "ReviewItem")
        record["title"] = "远程错题"
        record["questionText"] = "远程题目"
        record["answerText"] = "远程答案"
        record["subject"] = "物理"
        record["difficultyLevel"] = DifficultyLevel.hard.rawValue
        record["masteryLevel"] = MasteryLevel.learned.rawValue
        record["tags"] = ["力学"]
        record["createdAt"] = Date()
        record["updatedAt"] = Date()
        
        mockDatabase.queryResult = [record.recordID: .success(record)]
        
        // When
        let updates = try await syncService.fetchReviewItemUpdates(since: nil)
        
        // Then
        XCTAssertEqual(updates.count, 1)
        XCTAssertEqual(updates.first?.title, "远程错题")
        XCTAssertEqual(updates.first?.subject, "物理")
        XCTAssertTrue(mockDatabase.recordsWasCalled)
    }
    
    // MARK: - Conflict Resolution Tests
    
    func testResolveConflictNewestWins() async throws {
        // Given
        let olderDate = Date().addingTimeInterval(-3600) // 1小时前
        let newerDate = Date()
        
        let localItem = ReviewItem(
            title: "本地标题",
            questionText: "本地题目",
            answerText: "本地答案",
            subject: "数学",
            difficultyLevel: .easy,
            masteryLevel: .practicing,
            tags: ["本地标签"],
            imageURLs: [],
            createdAt: olderDate,
            updatedAt: olderDate
        )
        
        let remoteRecord = CKRecord(recordType: "ReviewItem")
        remoteRecord["title"] = "远程标题"
        remoteRecord["questionText"] = "远程题目"
        remoteRecord["answerText"] = "远程答案"
        remoteRecord["subject"] = "数学"
        remoteRecord["difficultyLevel"] = DifficultyLevel.medium.rawValue
        remoteRecord["masteryLevel"] = MasteryLevel.reviewing.rawValue
        remoteRecord["tags"] = ["远程标签"]
        remoteRecord["createdAt"] = olderDate
        remoteRecord["updatedAt"] = newerDate
        
        let config = CloudSyncConfiguration(conflictResolutionStrategy: .newestWins)
        syncService = CloudKitSyncService(configuration: config)
        
        // When
        let resolvedItem = try await syncService.resolveConflict(localItem: localItem, remoteRecord: remoteRecord)
        
        // Then
        XCTAssertEqual(resolvedItem.title, "远程标题") // 应该使用远程数据
        XCTAssertEqual(resolvedItem.updatedAt, newerDate)
    }
    
    func testResolveConflictCustomMerge() async throws {
        // Given
        let baseDate = Date()
        
        let localItem = ReviewItem(
            title: "本地标题",
            questionText: "本地题目",
            answerText: "本地答案",
            subject: "数学",
            difficultyLevel: .easy,
            masteryLevel: .learned, // 更高掌握度
            tags: ["本地标签", "共同标签"],
            imageURLs: [],
            createdAt: baseDate,
            updatedAt: baseDate.addingTimeInterval(100)
        )
        
        let remoteRecord = CKRecord(recordType: "ReviewItem")
        remoteRecord["title"] = "远程标题"
        remoteRecord["questionText"] = "远程题目"
        remoteRecord["answerText"] = "远程答案"
        remoteRecord["subject"] = "数学"
        remoteRecord["difficultyLevel"] = DifficultyLevel.medium.rawValue
        remoteRecord["masteryLevel"] = MasteryLevel.practicing.rawValue // 较低掌握度
        remoteRecord["tags"] = ["远程标签", "共同标签"]
        remoteRecord["createdAt"] = baseDate
        remoteRecord["updatedAt"] = baseDate.addingTimeInterval(200) // 更晚更新
        
        let config = CloudSyncConfiguration(conflictResolutionStrategy: .customMerge)
        syncService = CloudKitSyncService(configuration: config)
        
        // When
        let resolvedItem = try await syncService.resolveConflict(localItem: localItem, remoteRecord: remoteRecord)
        
        // Then
        XCTAssertEqual(resolvedItem.title, "远程标题") // 使用最新更新的内容
        XCTAssertEqual(resolvedItem.masteryLevel, .learned) // 保留更高掌握度
        XCTAssertTrue(resolvedItem.tags.contains("本地标签"))
        XCTAssertTrue(resolvedItem.tags.contains("远程标签"))
        XCTAssertTrue(resolvedItem.tags.contains("共同标签"))
        XCTAssertEqual(resolvedItem.tags.count, 3) // 去重后应该有3个标签
    }
    
    // MARK: - Error Handling Tests
    
    func testSyncServiceErrorHandling() async throws {
        // Given
        mockContainer.accountStatus = .available
        try await syncService.initialize(container: mockContainer, database: mockDatabase)
        
        mockDatabase.saveResult = .failure(CKError(.networkUnavailable))
        
        // When & Then
        do {
            _ = try await syncService.syncReviewItem(testReviewItem)
            XCTFail("应该抛出错误")
        } catch {
            // Expected error
        }
    }
    
    func testGetSyncStatus() async throws {
        // Given
        mockContainer.accountStatus = .available
        
        // When
        let status = await syncService.getSyncStatus()
        
        // Then
        XCTAssertTrue(status.isConnected)
        XCTAssertEqual(status.pendingUploads, 0)
        XCTAssertEqual(status.pendingDownloads, 0)
        XCTAssertTrue(status.syncErrors.isEmpty)
    }
}

// MARK: - Mock Classes

class MockCKContainer: CKContainer {
    var accountStatus: CKAccountStatus = .available
    
    override func accountStatus() async throws -> CKAccountStatus {
        return accountStatus
    }
}

class MockCKDatabase: CKDatabase {
    var saveResult: Result<CKRecord, Error>?
    var queryResult: [CKRecord.ID: Result<CKRecord, Error>] = [:]
    var recordResult: Result<CKRecord, Error>?
    
    var saveWasCalled = false
    var recordsWasCalled = false
    var recordWasCalled = false
    
    override func save(_ record: CKRecord) async throws -> CKRecord {
        saveWasCalled = true
        
        if let result = saveResult {
            switch result {
            case .success(let savedRecord):
                return savedRecord
            case .failure(let error):
                throw error
            }
        }
        
        return record
    }
    
    override func records(matching query: CKQuery) async throws -> (matchResults: [CKRecord.ID : Result<CKRecord, Error>], queryCursor: CKQueryOperation.Cursor?) {
        recordsWasCalled = true
        return (matchResults: queryResult, queryCursor: nil)
    }
    
    override func record(for recordID: CKRecord.ID) async throws -> CKRecord {
        recordWasCalled = true
        
        if let result = recordResult {
            switch result {
            case .success(let record):
                return record
            case .failure(let error):
                throw error
            }
        }
        
        throw CKError(.unknownItem)
    }
    
    override func deleteRecord(withID recordID: CKRecord.ID) async throws -> CKRecord.ID {
        return recordID
    }
}
