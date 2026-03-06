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
        #expect(analytics1 as AnyObject === analytics2 as AnyObject)
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

    @Test("MockServiceContainer 各属性返回正确的 Mock 实现类型")
    func testMockServiceContainerImplementationTypes() {
        // 编译期静态保证 ServiceContainer 协议符合性；
        // 此处验证 MockServiceContainer 正确注入各 Mock 实现。
        let mock = MockServiceContainer()

        #expect(mock.analytics is AnalyticsServiceMock)
        #expect(mock.crashReporting is CrashReportingServiceMock)
        #expect(mock.notification is NotificationServiceMock)
    }
}
