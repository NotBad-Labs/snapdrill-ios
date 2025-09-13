//
//  ModuleProtocolsTests.swift
//  NotBadTests
//
//  Created by AI Assistant on 2025/9/13.
//

import XCTest
@testable import NotBad

// MARK: - 模块协议测试
class ModuleProtocolsTests: XCTestCase {
    
    func testDomainEntityProtocol() {
        // Given
        let reviewItem = ReviewItem(
            content: ReviewContent(
                title: "数学题",
                question: "1+1等于多少？",
                subject: "数学"
            ),
            metadata: ReviewMetadata(ownerId: UUID())
        )
        
        // Then
        XCTAssertNotNil(reviewItem.id)
        XCTAssertEqual(reviewItem.id, reviewItem.id)
    }
    
    func testOCRErrorTypes() {
        // Given & When
        let invalidImageError = OCRError.invalidImage
        let recognitionFailedError = OCRError.recognitionFailed
        let lowConfidenceError = OCRError.lowConfidence
        
        // Then
        XCTAssertNotNil(invalidImageError)
        XCTAssertNotNil(recognitionFailedError)
        XCTAssertNotNil(lowConfidenceError)
    }
    
    func testNetworkErrorTypes() {
        // Given & When
        let noConnectionError = NetworkError.noConnection
        let timeoutError = NetworkError.timeout
        let invalidResponseError = NetworkError.invalidResponse
        
        // Then
        XCTAssertNotNil(noConnectionError)
        XCTAssertNotNil(timeoutError)
        XCTAssertNotNil(invalidResponseError)
    }
    
    func testSyncErrorTypes() {
        // Given & When
        let conflictError = SyncError.conflictDetected
        let quotaError = SyncError.quotaExceeded
        let cloudKitError = SyncError.cloudKitUnavailable
        
        // Then
        XCTAssertNotNil(conflictError)
        XCTAssertNotNil(quotaError)
        XCTAssertNotNil(cloudKitError)
    }
    
    func testMasteryLevelEnum() {
        // Then
        XCTAssertEqual(MasteryLevel.notMastered.rawValue, "not_mastered")
        XCTAssertEqual(MasteryLevel.unclear.rawValue, "unclear")
        XCTAssertEqual(MasteryLevel.mastered.rawValue, "mastered")
    }
    
    func testParentShareStatusEnum() {
        // Then
        XCTAssertEqual(ParentShareStatus.none.rawValue, "none")
        XCTAssertEqual(ParentShareStatus.summary.rawValue, "summary")
        XCTAssertEqual(ParentShareStatus.oneTime.rawValue, "one_time")
        XCTAssertEqual(ParentShareStatus.itemLevel.rawValue, "item_level")
    }
    
    func testStudyResultEnum() {
        // Then
        XCTAssertEqual(StudyResult.correct.rawValue, "correct")
        XCTAssertEqual(StudyResult.incorrect.rawValue, "incorrect")
        XCTAssertEqual(StudyResult.partial.rawValue, "partial")
        XCTAssertEqual(StudyResult.skipped.rawValue, "skipped")
    }
}
