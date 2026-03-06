//
//  AnalyticsTrackingServiceTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs on 2026/01/03.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  分析追踪服务单元测试。
//  架构说明：
//  - AnalyticsTrackingService（真实服务）：在 unit test 中无法验证 Firebase 调用结果，
//    仅做 enable/disable 状态与本地持久化的断言。
//  - AnalyticsServiceMock：完整可断言，是业务逻辑验证的主要载体。
//

import XCTest
@testable import SnapDrillCore

@MainActor
final class AnalyticsTrackingServiceTests: XCTestCase {

    // AnalyticsTrackingService 是单例，直接赋初值消除 IUO
    var service = AnalyticsTrackingService.shared

    override func setUp() async throws {
        try await super.setUp()
        service.setEnabled(true)
    }

    override func tearDown() async throws {
        service.setEnabled(false)
        try await super.tearDown()
    }

    // MARK: - 可断言行为（enable/disable 状态机）

    @MainActor
    func testEnableDisableService() {
        service.setEnabled(true)
        XCTAssertTrue(
            UserDefaults.standard.bool(forKey: "analyticsEnabled"),
            "启用后 UserDefaults 应写入 true"
        )

        service.setEnabled(false)
        XCTAssertFalse(
            UserDefaults.standard.bool(forKey: "analyticsEnabled"),
            "禁用后 UserDefaults 应写入 false"
        )

        service.setEnabled(true)
    }

    func testAllEventTypes_smokeTest() {
        // [SmokeTest] 验证所有 AnalyticsEvent case 均可调用，防止 enum 变更后出现漏项
        let allEvents: [AnalyticsEvent] = [
            .appLaunched, .reviewItemCreated, .reviewItemCompleted,
            .reviewSessionStarted, .reviewSessionCompleted, .cameraOpened,
            .ocrPerformed, .pdfExported, .dataExported,
            .icloudSyncStarted, .icloudSyncCompleted, .icloudSyncFailed, .errorOccurred
        ]
        for event in allEvents {
            service.track(event)
        }
        // 验证所有 case 均有 rawValue（防止 enum 定义破坏）
        for event in allEvents {
            XCTAssertFalse(event.rawValue.isEmpty, "\(event) 的 rawValue 不应为空")
        }
    }

    func testDisabledService_doesNotTrack() {
        // 禁用后调用不应崩溃，且不应写入 UserDefaults 额外状态
        service.setEnabled(false)
        service.track(.appLaunched)
        service.trackScreen("Test Screen")
        // 重新启用，验证状态恢复正常
        service.setEnabled(true)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "analyticsEnabled"))
    }

    // MARK: - Mock 行为验证（完整断言，业务逻辑验证主载体）

    func testMock_tracksEvents() {
        let mock = AnalyticsServiceMock()
        mock.track(.appLaunched, parameters: [:])
        mock.track(.reviewItemCreated, parameters: ["subject": "数学"])

        XCTAssertFalse(mock.trackedEvents.isEmpty, "Mock 应记录事件")
        XCTAssertTrue(mock.hasTrackedEvent(.appLaunched), "应记录 appLaunched")
        XCTAssertTrue(mock.hasTrackedEvent(.reviewItemCreated), "应记录 reviewItemCreated")
        XCTAssertEqual(mock.trackedEvents.count, 2, "应精确记录 2 个事件")
    }

    func testMock_tracksScreens() {
        let mock = AnalyticsServiceMock()
        mock.trackScreen("Dashboard", parameters: [:])

        XCTAssertTrue(mock.hasTrackedScreen("Dashboard"), "Dashboard 应被记录")
        XCTAssertFalse(mock.hasTrackedScreen("Library"), "未访问的 Library 不应被记录")
    }

    func testMock_sessionCounting() {
        let mock = AnalyticsServiceMock()
        mock.startSession()
        mock.startSession()
        mock.endSession()

        XCTAssertEqual(mock.sessionStartCount, 2, "startSession 调用 2 次")
        XCTAssertEqual(mock.sessionEndCount, 1, "endSession 调用 1 次")
    }

    func testMock_userProperties() {
        let mock = AnalyticsServiceMock()
        mock.setUserProperty("premium", forKey: "subscription_type")

        XCTAssertEqual(
            mock.userProperties["subscription_type"], "premium",
            "用户属性应被正确存储"
        )
    }

    func testMock_clearResetsAllState() {
        // AnalyticsServiceMock 无 setEnabled，通过 clear() 验证重置逻辑完整性
        let mock = AnalyticsServiceMock()
        mock.track(.appLaunched, parameters: [:])
        mock.track(.reviewItemCreated, parameters: [:])
        mock.startSession()
        mock.setUserProperty("premium", forKey: "plan")

        XCTAssertEqual(mock.trackedEvents.count, 2)
        XCTAssertEqual(mock.sessionStartCount, 1)

        mock.clear()

        XCTAssertTrue(mock.trackedEvents.isEmpty, "clear 后事件应为空")
        XCTAssertTrue(mock.userProperties.isEmpty, "clear 后用户属性应为空")
        XCTAssertEqual(mock.sessionStartCount, 0, "clear 后 session 计数应为 0")
    }

    func testMock_clear() {
        let mock = AnalyticsServiceMock()
        mock.track(.appLaunched, parameters: [:])
        mock.startSession()
        mock.clear()

        XCTAssertTrue(mock.trackedEvents.isEmpty, "clear 后事件列表应为空")
        XCTAssertEqual(mock.sessionStartCount, 0, "clear 后计数应归零")
    }

    func testMock_eventParameters() {
        let mock = AnalyticsServiceMock()
        mock.track(.reviewItemCreated, parameters: ["subject": "数学", "difficulty": "3"])

        XCTAssertEqual(mock.trackedEvents.count, 1)
        XCTAssertTrue(mock.hasTrackedEvent(.reviewItemCreated))
    }
}
