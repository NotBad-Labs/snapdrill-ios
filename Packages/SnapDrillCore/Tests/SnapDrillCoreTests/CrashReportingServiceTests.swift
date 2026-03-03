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
    
    func testLogLevels_doesNotCrash() {
        // Firebase Crashlytics 真实调用无法在 unit test 中验证结果，仅验证不崩溃
        XCTAssertNoThrow(service.log("Debug message", level: .debug))
        XCTAssertNoThrow(service.log("Info message", level: .info))
        XCTAssertNoThrow(service.log("Warning message", level: .warning))
        XCTAssertNoThrow(service.log("Error message", level: .error))
        XCTAssertNoThrow(service.log("Critical message", level: .critical))
    }

    func testSetUserIdentifier_doesNotCrash() {
        // setUserIdentifier 将 ID 异步存入 Keychain（非 UserDefaults），仅验证不崩溃
        XCTAssertNoThrow(service.setUserIdentifier("test-user-123"))
        XCTAssertNoThrow(service.setUserIdentifier(""))
    }

    func testSetCustomValue_doesNotCrash() {
        // Firebase Crashlytics 真实调用无法在 unit test 中验证结果，仅验证不崩溃
        XCTAssertNoThrow(service.setCustomValue("testValue", forKey: "testKey"))
    }

    func testLeaveBreadcrumb_doesNotCrash() {
        // Firebase Crashlytics 真实调用无法在 unit test 中验证结果，仅验证不崩溃
        XCTAssertNoThrow(service.leaveBreadcrumb("User tapped button", metadata: [
            "screen": "Dashboard",
            "action": "tap"
        ]))
    }

    func testDisabledService_doesNotCrash() {
        // Firebase Crashlytics 真实调用无法在 unit test 中验证结果，仅验证不崩溃
        service.setEnabled(false)
        let testError = NSError(domain: "TestDomain", code: 200)
        XCTAssertNoThrow(service.recordError(testError))
        service.setEnabled(true)
    }
}
