//
//  AnalyticsServiceTests.swift
//  NotBadCoreTests
//
//  Created by NotBad Labs on 2026/01/02.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  AnalyticsService 单元测试
//

import XCTest
@testable import NotBadCore

final class AnalyticsServiceTests: XCTestCase {
    
    var sut: AnalyticsService!
    
    override func setUp() {
        super.setUp()
        sut = AnalyticsService.shared
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Singleton Tests
    
    func testShared_ShouldReturnSameInstance() {
        // Arrange & Act
        let instance1 = AnalyticsService.shared
        let instance2 = AnalyticsService.shared
        
        // Assert
        XCTAssertTrue(instance1 === instance2)
    }
    
    // MARK: - Event Tracking Tests
    
    func testTrackEvent_ShouldNotCrash() {
        // Arrange
        let eventName = "test_event"
        let parameters: [String: Any] = ["key": "value"]
        
        // Act & Assert - Should not crash
        XCTAssertNoThrow {
            sut.trackEvent(eventName, parameters: parameters)
        }
    }
    
    func testTrackEvent_WithEmptyParameters_ShouldNotCrash() {
        // Arrange
        let eventName = "test_event"
        
        // Act & Assert
        XCTAssertNoThrow {
            sut.trackEvent(eventName, parameters: [:])
        }
    }
    
    func testTrackEvent_WithNilParameters_ShouldNotCrash() {
        // Arrange
        let eventName = "test_event"
        
        // Act & Assert
        XCTAssertNoThrow {
            sut.trackEvent(eventName, parameters: nil)
        }
    }
}
