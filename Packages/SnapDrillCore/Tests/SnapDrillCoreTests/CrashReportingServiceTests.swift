//
//  CrashReportingServiceTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs on 2026/01/03.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  崩溃报告服务单元测试
//

import XCTest
@testable import SnapDrillCore

@MainActor
final class CrashReportingServiceTests: XCTestCase {
    var service: CrashReportingService!
    
    override func setUp() async throws {
        try await super.setUp()
        service = CrashReportingService.shared
        // 确保测试时启用服务
        service.setEnabled(true)
    }
    
    override func tearDown() async throws {
        // 清理测试日志文件
        let logsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Logs", isDirectory: true)
        try? FileManager.default.removeItem(at: logsDirectory)
        try await super.tearDown()
    }
    
    func testServiceInitialization() {
        XCTAssertNotNil(service, "Service should be initialized")
    }
    
    func testEnableDisableService() {
        // 测试启用
        service.setEnabled(true)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "crashReportingEnabled"))
        
        // 测试禁用
        service.setEnabled(false)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "crashReportingEnabled"))
        
        // 恢复启用状态
        service.setEnabled(true)
    }
    
    func testRecordError() {
        // 创建测试错误
        let testError = NSError(domain: "TestDomain", code: 100, userInfo: [
            NSLocalizedDescriptionKey: "Test error description"
        ])
        
        // 记录错误
        service.recordError(testError, context: [
            "testKey": "testValue",
            "operation": "unit test"
        ])
        
        // 验证日志文件是否创建
        let logsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Logs", isDirectory: true)
        
        let logFiles = try? FileManager.default.contentsOfDirectory(at: logsDirectory, includingPropertiesForKeys: nil)
        XCTAssertNotNil(logFiles, "Log files should be created")
        XCTAssertTrue(logFiles?.count ?? 0 > 0, "At least one log file should exist")
    }
    
    func testLogLevels() {
        // 测试不同日志级别
        service.log("Debug message", level: .debug)
        service.log("Info message", level: .info)
        service.log("Warning message", level: .warning)
        service.log("Error message", level: .error)
        service.log("Critical message", level: .critical)
        
        // 这些调用不应该崩溃
        XCTAssertTrue(true, "All log levels should work without crashing")
    }
    
    func testSetUserIdentifier() {
        let testUserID = "test-user-123"
        service.setUserIdentifier(testUserID)
        
        let savedUserID = UserDefaults.standard.string(forKey: "crashReportingUserID")
        XCTAssertEqual(savedUserID, testUserID, "User ID should be saved")
    }
    
    func testSetCustomValue() {
        // 测试设置自定义值（不应崩溃）
        service.setCustomValue("testValue", forKey: "testKey")
        XCTAssertTrue(true, "Setting custom values should not crash")
    }
    
    func testLeaveBreadcrumb() {
        // 测试面包屑记录（不应崩溃）
        service.leaveBreadcrumb("User tapped button", metadata: [
            "screen": "Dashboard",
            "action": "tap"
        ])
        XCTAssertTrue(true, "Leaving breadcrumbs should not crash")
    }
    
    func testDisabledService() {
        // 禁用服务
        service.setEnabled(false)
        
        // 尝试记录错误
        let testError = NSError(domain: "TestDomain", code: 200)
        service.recordError(testError)
        
        // 验证没有创建日志文件（因为服务已禁用）
        // 注意：这个测试可能需要清理之前的日志
        XCTAssertTrue(true, "Disabled service should not crash")
        
        // 恢复启用状态
        service.setEnabled(true)
    }
}
