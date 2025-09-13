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
            title: "数学题",
            question: "1+1等于多少？",
            answer: "2",
            subject: "数学",
            difficulty: .easy
        )
        
        let metadata = ReviewMetadata(
            ownerId: UUID(),
            source: .manual
        )
        
        // When
        let reviewItem = ReviewItem(
            content: content,
            metadata: metadata
        )
        
        // Then
        XCTAssertEqual(reviewItem.content.title, "数学题")
        XCTAssertEqual(reviewItem.content.question, "1+1等于多少？")
        XCTAssertEqual(reviewItem.content.answer, "2")
        XCTAssertEqual(reviewItem.content.subject, "数学")
        XCTAssertEqual(reviewItem.content.difficulty, .easy)
        XCTAssertEqual(reviewItem.masteryLevel, .notMastered)
        XCTAssertEqual(reviewItem.studyHistory.count, 0)
    }
    
    func testReviewItemEquality() {
        // Given
        let id = UUID()
        let ownerId = UUID()
        
        let content1 = ReviewContent(
            title: "数学题",
            question: "1+1等于多少？",
            answer: "2",
            subject: "数学",
            difficulty: .easy
        )
        
        let metadata1 = ReviewMetadata(
            ownerId: ownerId,
            source: .manual
        )
        
        let content2 = ReviewContent(
            title: "数学题",
            question: "1+1等于多少？",
            answer: "2",
            subject: "数学",
            difficulty: .easy
        )
        
        let metadata2 = ReviewMetadata(
            ownerId: ownerId,
            source: .manual
        )
        
        // When
        let item1 = ReviewItem(
            id: id,
            content: content1,
            metadata: metadata1
        )
        
        let item2 = ReviewItem(
            id: id,
            content: content2,
            metadata: metadata2
        )
        
        // Then
        XCTAssertEqual(item1, item2)
    }
    
    func testMasteryLevelDisplayName() {
        // Then
        XCTAssertEqual(MasteryLevel.notMastered.displayName, "未掌握")
        XCTAssertEqual(MasteryLevel.fuzzy.displayName, "模糊")
        XCTAssertEqual(MasteryLevel.mastered.displayName, "已掌握")
    }
    
    func testMasteryLevelColor() {
        // Then
        XCTAssertEqual(MasteryLevel.notMastered.color, "red")
        XCTAssertEqual(MasteryLevel.fuzzy.color, "orange")
        XCTAssertEqual(MasteryLevel.mastered.color, "green")
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
                title: "数学题",
                question: "1+1等于多少？",
                answer: "2",
                subject: "数学",
                difficulty: .easy
            ),
            metadata: ReviewMetadata(
                ownerId: UUID(),
                source: .manual
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
            XCTAssertEqual(reviewItem.content.title, decodedItem.content.title)
            XCTAssertEqual(reviewItem.content.question, decodedItem.content.question)
            XCTAssertEqual(reviewItem.content.answer, decodedItem.content.answer)
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
                title: "数学题",
                question: "1+1等于多少？",
                subject: "数学"
            ),
            metadata: ReviewMetadata(ownerId: UUID())
        )
        
        // When
        let hashValue = reviewItem.hashValue
        
        // Then
        XCTAssertNotEqual(hashValue, 0)
    }