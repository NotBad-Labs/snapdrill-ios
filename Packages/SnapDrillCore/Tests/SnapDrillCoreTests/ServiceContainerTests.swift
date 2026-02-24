//
//  ServiceContainerTests.swift
//  SnapDrillCoreTests
//
//  Created by SnapDrill Labs on 2026/02/25.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  DI 容器的验证测试。
//

import Testing
import Foundation
@testable import SnapDrillCore

@MainActor
struct ServiceContainerTests {

    // MARK: - LiveServiceContainer

    @Test
    func testLiveServiceContainerProvidesAllServices() {
        let container = LiveServiceContainer()

        // 验证所有服务属性非 nil
        #expect(container.analytics is AnalyticsTrackingService)
        #expect(container.crashReporting is CrashReportingService)
        #expect(container.configuration is AppConfiguration)
    }

    @Test
    func testLiveServiceContainerReturnsSameInstances() {
        let container = LiveServiceContainer()

        // 访问两次应该返回相同实例
        let analytics1 = container.analytics
        let analytics2 = container.analytics
        #expect(analytics1 === analytics2)
    }

    // MARK: - MockServiceContainer

    @Test
    func testMockServiceContainerProvidesAllServices() {
        let container = MockServiceContainer()

        // Mock 容器也应提供所有服务
        #expect(container.analytics is AnalyticsTrackingService)
        #expect(container.crashReporting is CrashReportingService)
        #expect(container.configuration is AppConfiguration)
    }

    // MARK: - ServiceContainer 协议

    @Test
    func testServiceContainerProtocolConformance() {
        // 两种实现都应该符合协议
        let live: any ServiceContainer = LiveServiceContainer()
        let mock: any ServiceContainer = MockServiceContainer()

        // 协议多态：可以统一使用
        #expect(live.analytics is AnalyticsServiceProtocol)
        #expect(mock.analytics is AnalyticsServiceProtocol)
    }
}
