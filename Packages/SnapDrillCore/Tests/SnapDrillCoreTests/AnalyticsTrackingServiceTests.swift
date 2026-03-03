//
//  AnalyticsTrackingServiceTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs on 2026/01/03.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  分析追踪服务单元测试
//

import XCTest
@testable import SnapDrillCore

@MainActor
final class AnalyticsTrackingServiceTests: XCTestCase {
    var service: AnalyticsTrackingService!
    
    override func setUp() async throws {
        try await super.setUp()
        service = AnalyticsTrackingService.shared
        // 测试时启用服务
        service.setEnabled(true)
    }
    
    override func tearDown() async throws {
        // 清理测试分析文件
        let analyticsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Analytics", isDirectory: true)
        try? FileManager.default.removeItem(at: analyticsDirectory)
        try await super.tearDown()
    }
    
    func testServiceInitialization() {
        XCTAssertNotNil(service, "Service should be initialized")
    }
    
    func testEnableDisableService() {
        // 测试启用
        service.setEnabled(true)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "analyticsEnabled"))
        
        // 测试禁用
        service.setEnabled(false)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "analyticsEnabled"))
        
        // 恢复启用状态
        service.setEnabled(true)
    }
    
    func testTrackEvent() {
        // 测试追踪事件
        service.track(.appLaunched, parameters: [
            "version": "1.0.0",
            "platform": "iOS"
        ])
        
        // 验证事件文件是否创建
        let analyticsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Analytics", isDirectory: true)
        
        let eventFiles = try? FileManager.default.contentsOfDirectory(at: analyticsDirectory, includingPropertiesForKeys: nil)
        XCTAssertNotNil(eventFiles, "Event files should be created")
        XCTAssertTrue(eventFiles?.count ?? 0 > 0, "At least one event file should exist")
    }
    
    func testTrackMultipleEvents() {
        // 测试追踪多个事件
        service.track(.reviewItemCreated)
        service.track(.reviewItemCompleted)
        service.track(.cameraOpened)
        service.track(.ocrPerformed)
        
        let analyticsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Analytics", isDirectory: true)
        
        let eventFiles = try? FileManager.default.contentsOfDirectory(at: analyticsDirectory, includingPropertiesForKeys: nil)
        XCTAssertTrue(eventFiles?.count ?? 0 >= 4, "Multiple event files should be created")
    }
    
    func testTrackScreen_doesNotCrash() {
        // Firebase 真实调用无法在 unit test 中验证结果，仅验证不崩溃
        service.trackScreen("Dashboard", parameters: [
            "source": "app_launch"
        ])
        XCTAssertNoThrow(service.trackScreen("Library", parameters: [:]))
    }

    func testSessionManagement_doesNotCrash() {
        // Firebase 真实调用无法在 unit test 中验证结果，仅验证不崩溃
        service.startSession()
        Thread.sleep(forTimeInterval: 0.1)
        XCTAssertNoThrow(service.endSession())
    }

    func testSetUserProperty_doesNotCrash() {
        // Firebase 真实调用无法在 unit test 中验证结果，仅验证不崩溃
        XCTAssertNoThrow(service.setUserProperty("premium", forKey: "subscription_type"))
        XCTAssertNoThrow(service.setUserProperty("en", forKey: "language"))
    }

    func testTrackRetention_doesNotCrash() {
        // Firebase 真实调用无法在 unit test 中验证结果，仅验证不崩溃
        XCTAssertNoThrow(service.trackRetention(daysSinceInstall: 1))
        XCTAssertNoThrow(service.trackRetention(daysSinceInstall: 7))
        XCTAssertNoThrow(service.trackRetention(daysSinceInstall: 30))
    }

    func testDisabledService_doesNotCrash() {
        // Firebase 真实调用无法在 unit test 中验证结果，仅验证不崩溃
        service.setEnabled(false)
        XCTAssertNoThrow(service.track(.appLaunched))
        XCTAssertNoThrow(service.trackScreen("Test Screen"))
        service.setEnabled(true)
    }

    func testEventTypes_doesNotCrash() {
        // Firebase 真实调用无法在 unit test 中验证结果，仅验证不崩溃
        let events: [AnalyticsEvent] = [
            .appLaunched, .reviewItemCreated, .reviewItemCompleted,
            .reviewSessionStarted, .reviewSessionCompleted, .cameraOpened,
            .ocrPerformed, .pdfExported, .dataExported,
            .icloudSyncStarted, .icloudSyncCompleted, .icloudSyncFailed, .errorOccurred
        ]
        for event in events {
            XCTAssertNoThrow(service.track(event))
        }
    }

    // MARK: - Mock 行为验证（可断言属性）

    func testMock_tracksEvents() {
        let mock = AnalyticsServiceMock()
        mock.track(.appLaunched, parameters: [:])
        mock.track(.reviewItemCreated, parameters: ["subject": "数学"])
        XCTAssertFalse(mock.trackedEvents.isEmpty)
        XCTAssertTrue(mock.hasTrackedEvent(.appLaunched))
        XCTAssertTrue(mock.hasTrackedEvent(.reviewItemCreated))
        XCTAssertEqual(mock.trackedEvents.count, 2)
    }

    func testMock_tracksScreens() {
        let mock = AnalyticsServiceMock()
        mock.trackScreen("Dashboard", parameters: [:])
        XCTAssertTrue(mock.hasTrackedScreen("Dashboard"))
        XCTAssertFalse(mock.hasTrackedScreen("Library"))
    }

    func testMock_sessionCounting() {
        let mock = AnalyticsServiceMock()
        mock.startSession()
        mock.startSession()
        mock.endSession()
        XCTAssertEqual(mock.sessionStartCount, 2)
        XCTAssertEqual(mock.sessionEndCount, 1)
    }

    func testMock_userProperties() {
        let mock = AnalyticsServiceMock()
        mock.setUserProperty("premium", forKey: "subscription_type")
        XCTAssertEqual(mock.userProperties["subscription_type"], "premium")
    }

    func testMock_clear() {
        let mock = AnalyticsServiceMock()
        mock.track(.appLaunched, parameters: [:])
        mock.startSession()
        mock.clear()
        XCTAssertTrue(mock.trackedEvents.isEmpty)
        XCTAssertEqual(mock.sessionStartCount, 0)
    }
}
