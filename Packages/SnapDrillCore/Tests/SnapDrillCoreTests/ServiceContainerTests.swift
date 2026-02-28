//
//  ServiceContainerTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  DI 容器的验证测试。
//

import Testing
import Foundation
@testable import SnapDrillCore

@MainActor
struct ServiceContainerTests {

    // MARK: - LiveServiceContainer

    @Test("LiveServiceContainer 提供所有服务属性")
    func testLiveServiceContainerProvidesAllServices() {
        let container = LiveServiceContainer()

        _ = container.analytics
        _ = container.crashReporting
        _ = container.performanceMonitor
        _ = container.networkMonitor
        _ = container.pdfExport
        _ = container.appConfig
        _ = container.privacyConsent
        _ = container.subscription
        _ = container.notification
    }

    @Test("LiveServiceContainer 重复访问同一属性返回相同实例")
    func testLiveServiceContainerReturnsSameInstances() {
        let container = LiveServiceContainer()

        let analytics1 = container.analytics
        let analytics2 = container.analytics
        #expect(analytics1 === analytics2)
    }

    // MARK: - MockServiceContainer

    @Test("MockServiceContainer 提供所有 Mock 服务")
    func testMockServiceContainerProvidesAllServices() {
        let container = MockServiceContainer()

        #expect(container.analytics is AnalyticsServiceMock)
        #expect(container.crashReporting is CrashReportingServiceMock)
        #expect(container.notification is NotificationServiceMock)
    }

    // MARK: - ServiceContainer 协议

    @Test("LiveServiceContainer 和 MockServiceContainer 均符合 ServiceContainer 协议")
    func testServiceContainerProtocolConformance() {
        let live: any ServiceContainer = LiveServiceContainer()
        let mock: any ServiceContainer = MockServiceContainer()

        #expect(live.analytics is any AnalyticsServiceProtocol)
        #expect(mock.analytics is any AnalyticsServiceProtocol)
        #expect(live.notification is any NotificationServiceProtocol)
        #expect(mock.notification is any NotificationServiceProtocol)
    }
}
