//
//  TelemetryGateTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs on 2026/05/12.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Telemetry opt-in gate tests.
//

import Foundation
import Testing
@testable import SnapDrillCore

@Suite("TelemetryGate 单元测试", .serialized)
struct TelemetryGateTests {

    @Test("默认拒绝遥测")
    func defaultConsentDenied() {
        let defaults = makeDefaults()

        #expect(TelemetryGate.state(in: defaults) == .denied)
        #expect(TelemetryGate.isGranted(in: defaults) == false)
    }

    @Test("显式开启写入单一授权状态并同步旧 key")
    func setEnabledPersistsSingleGateAndLegacyMirrors() {
        let defaults = makeDefaults()

        TelemetryGate.setGranted(true, in: defaults)

        #expect(TelemetryGate.state(in: defaults) == .granted)
        #expect(defaults.string(forKey: UDKey.telemetryConsent) == TelemetryGate.State.granted.rawValue)
        #expect(defaults.bool(forKey: UDKey.analyticsEnabled) == true)
        #expect(defaults.bool(forKey: UDKey.crashReportingEnabled) == true)
    }

    @Test("pending 状态不允许采集")
    func pendingStateDeniesCollection() {
        let defaults = makeDefaults()

        TelemetryGate.setState(.pending, in: defaults)

        #expect(TelemetryGate.state(in: defaults) == .pending)
        #expect(TelemetryGate.isGranted(in: defaults) == false)
        #expect(defaults.bool(forKey: UDKey.analyticsEnabled) == false)
        #expect(defaults.bool(forKey: UDKey.crashReportingEnabled) == false)
    }

    @Test("旧双开关只有全部显式开启才迁移为允许")
    func legacyMigrationRequiresBothTelemetryKeysEnabled() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: UDKey.analyticsEnabled)
        defaults.set(false, forKey: UDKey.crashReportingEnabled)

        #expect(TelemetryGate.state(in: defaults) == .denied)
        #expect(defaults.string(forKey: UDKey.telemetryConsent) == TelemetryGate.State.denied.rawValue)
        #expect(defaults.bool(forKey: UDKey.analyticsEnabled) == false)
        #expect(defaults.bool(forKey: UDKey.crashReportingEnabled) == false)
    }

    @Test("FeatureFlags 兼容入口委托给 TelemetryGate 且默认拒绝")
    func featureFlagsDelegateToTelemetryGate() {
        let defaults = UserDefaults.standard
        let telemetryConsent = defaults.object(forKey: UDKey.telemetryConsent)
        let analyticsEnabled = defaults.object(forKey: UDKey.analyticsEnabled)
        let crashReportingEnabled = defaults.object(forKey: UDKey.crashReportingEnabled)

        defer {
            restore(telemetryConsent, forKey: UDKey.telemetryConsent, in: defaults)
            restore(analyticsEnabled, forKey: UDKey.analyticsEnabled, in: defaults)
            restore(crashReportingEnabled, forKey: UDKey.crashReportingEnabled, in: defaults)
        }

        defaults.removeObject(forKey: UDKey.telemetryConsent)
        defaults.removeObject(forKey: UDKey.analyticsEnabled)
        defaults.removeObject(forKey: UDKey.crashReportingEnabled)

        #expect(AppConfiguration.FeatureFlags.analyticsEnabled == false)
        #expect(AppConfiguration.FeatureFlags.crashReportingEnabled == false)

        AppConfiguration.FeatureFlags.analyticsEnabled = true

        #expect(TelemetryGate.isGranted == true)
        #expect(AppConfiguration.FeatureFlags.crashReportingEnabled == true)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "TelemetryGateTests-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            preconditionFailure("Failed to create test UserDefaults suite: \(suiteName)")
        }
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func restore(_ value: Any?, forKey key: String, in defaults: UserDefaults) {
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
