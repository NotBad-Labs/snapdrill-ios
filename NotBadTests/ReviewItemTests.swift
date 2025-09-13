//
//  ReviewItemTests.swift
//  NotBadTests
//
//  Created by AI Assistant on 2025/9/13.
//

import XCTest
@testable import NotBad

// MARK: - ReviewItem实体测试
class ReviewItemTests: XCTestCase {
    
    func testReviewItemCreation() {
        // Given
        let content = ReviewContent(
            imageData: nil,
            recognizedText: "1+1等于多少？",
            userNotes: "简单的加法题",
            subject: "数学",
            tags: ["加法", "基础"],
            difficulty: .easy
        )
        
        let metadata = ReviewItemMetadata(
            ownerId: UUID(),
            parentShareStatus: .none,
            parentAccessRevokedAt: nil,
            sharedWithClassIds: [],
            isArchived: false
        )
        
        // When
        let reviewItem = ReviewItem(
            content: content,
            metadata: metadata
        )
        
        // Then
        XCTAssertEqual(reviewItem.content.recognizedText, "1+1等于多少？")
        XCTAssertEqual(reviewItem.content.userNotes, "简单的加法题")
        XCTAssertEqual(reviewItem.content.subject, "数学")
        XCTAssertEqual(reviewItem.content.difficulty, .easy)
        XCTAssertEqual(reviewItem.masteryLevel, .notLearned)
        XCTAssertEqual(reviewItem.studyHistory.count, 0)
    }
    
    func testReviewItemEquality() {
        // Given
        let id = UUID()
        let ownerId = UUID()
        let fixedDate = Date() // 使用固定时间戳
        
        let content1 = ReviewContent(
            imageData: nil,
            recognizedText: "1+1等于多少？",
            userNotes: "简单的加法题",
            subject: "数学",
            tags: ["加法", "基础"],
            difficulty: .easy
        )
        
        let metadata1 = ReviewItemMetadata(
            ownerId: ownerId,
            parentShareStatus: .none,
            parentAccessRevokedAt: nil,
            sharedWithClassIds: [],
            isArchived: false
        )
        
        let content2 = ReviewContent(
            imageData: nil,
            recognizedText: "1+1等于多少？",
            userNotes: "简单的加法题",
            subject: "数学",
            tags: ["加法", "基础"],
            difficulty: .easy
        )
        
        let metadata2 = ReviewItemMetadata(
            ownerId: ownerId,
            parentShareStatus: .none,
            parentAccessRevokedAt: nil,
            sharedWithClassIds: [],
            isArchived: false
        )
        
        // When
        let item1 = ReviewItem(
            content: content1,
            metadata: metadata1
        )
        
        let item2 = ReviewItem(
            content: content2,
            metadata: metadata2
        )
        
        // Then
        XCTAssertEqual(item1, item2)
    }
    
    func testMasteryLevelDisplayName() {
        // Then
        XCTAssertEqual(MasteryLevel.notLearned.displayName, "未掌握")
        XCTAssertEqual(MasteryLevel.unclear.displayName, "模糊")
        XCTAssertEqual(MasteryLevel.learned.displayName, "已掌握")
    }
    
    func testMasteryLevelColor() {
        // Then
        XCTAssertEqual(MasteryLevel.notLearned.color, "red")
        XCTAssertEqual(MasteryLevel.unclear.color, "orange")
        XCTAssertEqual(MasteryLevel.learned.color, "green")
    }
    
    func testDifficultyLevelWeight() {
        // Then
        XCTAssertEqual(DifficultyLevel.easy.weight, 1)
        XCTAssertEqual(DifficultyLevel.medium.weight, 2)
        XCTAssertEqual(DifficultyLevel.hard.weight, 3)
    }
    
    func testStudyRecordCreation() {
        // When
        let studyRecord = StudyRecord(
            isCorrect: true,
            timeSpent: 30.0,
            notes: "做对了"
        )
        
        // Then
        XCTAssertTrue(studyRecord.isCorrect)
        XCTAssertEqual(studyRecord.timeSpent, 30.0)
        XCTAssertEqual(studyRecord.notes, "做对了")
    }
    
    func testReviewItemCodable() {
        // Given
        let reviewItem = ReviewItem(
            content: ReviewContent(
                imageData: nil,
                recognizedText: "1+1等于多少？",
                userNotes: "简单的加法题",
                subject: "数学",
                tags: ["加法", "基础"],
                difficulty: .easy
            ),
            metadata: ReviewItemMetadata(
                ownerId: UUID(),
                parentShareStatus: .none,
                parentAccessRevokedAt: nil,
                sharedWithClassIds: [],
                isArchived: false
            )
        )
        
        // When
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(reviewItem)
            let decodedItem = try decoder.decode(ReviewItem.self, from: data)
            
            // Then
            XCTAssertEqual(reviewItem.id, decodedItem.id)
            XCTAssertEqual(reviewItem.content.recognizedText, decodedItem.content.recognizedText)
            XCTAssertEqual(reviewItem.content.userNotes, decodedItem.content.userNotes)
            XCTAssertEqual(reviewItem.content.subject, decodedItem.content.subject)
            XCTAssertEqual(reviewItem.content.difficulty, decodedItem.content.difficulty)
            XCTAssertEqual(reviewItem.masteryLevel, decodedItem.masteryLevel)
        } catch {
            XCTFail("编码/解码失败: \(error)")
        }
    }
    
    func testReviewItemHashable() {
        // Given
        let reviewItem = ReviewItem(
            content: ReviewContent(
                imageData: nil,
                recognizedText: "1+1等于多少？",
                userNotes: "简单的加法题",
                subject: "数学",
                tags: ["加法", "基础"],
                difficulty: .easy
            ),
            metadata: ReviewItemMetadata(
                ownerId: UUID(),
                parentShareStatus: .none,
                parentAccessRevokedAt: nil,
                sharedWithClassIds: [],
                isArchived: false
            )
        )
        
        // When
        let hashValue = reviewItem.hashValue
        
        // Then
        XCTAssertNotEqual(hashValue, 0)
    }
}