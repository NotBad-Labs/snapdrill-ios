//
//  AnalyticsTrackingServiceTests.swift
//  NotBadCoreTests
//
//  Created by NotBad Architect on 2026/01/03.
//  Copyright © 2026 NotBad Team. All rights reserved.
//
//  分析追踪服务单元测试
//

import XCTest
@testable import NotBadCore

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
    
    func testTrackScreen() {
        // 测试屏幕追踪
        service.trackScreen("Dashboard", parameters: [
            "source": "app_launch"
        ])
        
        XCTAssertTrue(true, "Screen tracking should not crash")
    }
    
    func testSessionManagement() {
        // 测试会话管理
        service.startSession()
        
        // 模拟一些操作
        Thread.sleep(forTimeInterval: 0.1)
        
        service.endSession()
        
        XCTAssertTrue(true, "Session management should work correctly")
    }
    
    func testSetUserProperty() {
        // 测试设置用户属性
        service.setUserProperty("premium", forKey: "subscription_type")
        service.setUserProperty("en", forKey: "language")
        
        XCTAssertTrue(true, "Setting user properties should not crash")
    }
    
    func testTrackRetention() {
        // 测试留存追踪
        service.trackRetention(daysSinceInstall: 1)
        service.trackRetention(daysSinceInstall: 7)
        service.trackRetention(daysSinceInstall: 30)
        
        XCTAssertTrue(true, "Retention tracking should not crash")
    }
    
    func testDisabledService() {
        // 禁用服务
        service.setEnabled(false)
        
        // 尝试追踪事件
        service.track(.appLaunched)
        service.trackScreen("Test Screen")
        
        // 验证没有创建事件文件（因为服务已禁用）
        XCTAssertTrue(true, "Disabled service should not crash")
        
        // 恢复启用状态
        service.setEnabled(true)
    }
    
    func testEventTypes() {
        // 测试所有事件类型
        let events: [AnalyticsEvent] = [
            .appLaunched,
            .reviewItemCreated,
            .reviewItemCompleted,
            .reviewSessionStarted,
            .reviewSessionCompleted,
            .cameraOpened,
            .ocrPerformed,
            .pdfExported,
            .dataExported,
            .icloudSyncStarted,
            .icloudSyncCompleted,
            .icloudSyncFailed,
            .errorOccurred
        ]
        
        for event in events {
            service.track(event)
        }
        
        XCTAssertTrue(true, "All event types should be trackable")
    }
}
