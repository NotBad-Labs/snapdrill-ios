//
//  ServiceContainerTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  DI 容器的验证测试（S-D4-001 扩展到 14 个服务属性）。
//

import Testing
import Foundation
@testable import SnapDrillCore

struct ServiceContainerTests {

    // MARK: - LiveServiceContainer

    @Test("LiveServiceContainer 重复访问同一属性返回相同实例")
    func testLiveServiceContainerReturnsSameInstances() {
        let container = LiveServiceContainer()

        let analytics1 = container.analytics
        let analytics2 = container.analytics
        #expect(analytics1 as AnyObject === analytics2 as AnyObject)
    }

    @Test("LiveServiceContainer 14 个服务属性全部可访问")
    func testLiveServiceContainerAllPropertiesAccessible() {
        let container = LiveServiceContainer()

        // 既有 5 项
        _ = container.analytics
        _ = container.pdfExport
        _ = container.appConfig
        _ = container.privacyConsent
        _ = container.notification
        // S-D4-001 新挂 8 项
        _ = container.ocr
        _ = container.captureDraft
        _ = container.contentTagging
        _ = container.questionSplitting
        _ = container.deletionScheduler
        _ = container.proEntitlement
        _ = container.activityTracker
        _ = container.reviewScheduler
        _ = container.metricService
    }

    @Test("LiveServiceContainer @Observable 服务单例语义（容器生命周期内同实例）")
    func testLiveServiceContainerObservableSingletonSemantics() {
        let container = LiveServiceContainer()

        #expect(container.deletionScheduler === container.deletionScheduler)
        #expect(container.activityTracker === container.activityTracker)
    }

    // MARK: - Activity tracker identity

    @Test("LiveServiceContainer 默认 activityTracker 与现有 ViewModel fallback 同实例")
    func testLiveServiceContainerActivityTrackerIsShared() {
        // 部分现有 ViewModel 默认参数仍回落到 .shared；完成全量 DI 前，生产容器
        // 保持同一实例，避免应用级活动状态分裂。
        let container = LiveServiceContainer()
        #expect(container.activityTracker === AppActivityTracker.shared)
    }

    // MARK: - MockServiceContainer

    @Test("MockServiceContainer 提供所有 Mock 服务")
    func testMockServiceContainerProvidesAllServices() {
        let container = MockServiceContainer()

        #expect(container.analytics is AnalyticsServiceMock)
        #expect(container.notification is NotificationServiceMock)
        #expect(container.captureDraft is CaptureDraftServiceMock)
        #expect(container.contentTagging is ContentTaggingServiceMock)
        #expect(container.questionSplitting is QuestionSplittingServiceMock)
        #expect(container.proEntitlement is MockProEntitlementProvider)
        #expect(container.metricService is MetricServiceMock)
    }

    @Test("MockServiceContainer 14 个服务属性全部可访问")
    func testMockServiceContainerAllPropertiesAccessible() {
        let container = MockServiceContainer()

        _ = container.analytics
        _ = container.pdfExport
        _ = container.appConfig
        _ = container.privacyConsent
        _ = container.notification
        _ = container.ocr
        _ = container.captureDraft
        _ = container.contentTagging
        _ = container.questionSplitting
        _ = container.deletionScheduler
        _ = container.proEntitlement
        _ = container.activityTracker
        _ = container.reviewScheduler
        _ = container.metricService
    }

    // MARK: - ServiceContainer 协议

    @Test("ServiceContainer 协议变量持有 Live / Mock 容器均合法")
    func testProtocolVariance() {
        let _: any ServiceContainer = LiveServiceContainer()
        let _: any ServiceContainer = MockServiceContainer()
    }

    @Test("MockProEntitlementProvider 可注入 isProUser=true/false")
    func testMockProEntitlementProviderInjection() {
        let proContainer = MockServiceContainer(
            proEntitlement: MockProEntitlementProvider(isProUser: true)
        )
        let freeContainer = MockServiceContainer(
            proEntitlement: MockProEntitlementProvider(isProUser: false)
        )

        #expect(proContainer.proEntitlement.isProUser == true)
        #expect(freeContainer.proEntitlement.isProUser == false)
    }
}
