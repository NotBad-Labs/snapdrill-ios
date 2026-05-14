//
//  TelemetryGate.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Single privacy consent gate for all telemetry collection.
//

import Foundation

/// Single source of truth for Analytics and Crashlytics consent.
///
/// Default state is `.denied`; enabling telemetry always requires an explicit
/// persisted opt-in. Legacy per-service keys are migrated conservatively:
/// only users who had explicitly enabled both Analytics and Crashlytics keep
/// telemetry enabled after the migration.
nonisolated public enum TelemetryGate {

    public enum State: String, CaseIterable, Sendable {
        case denied
        case pending
        case granted
    }

    public static let didChangeNotification = Notification.Name("TelemetryGate.didChangeNotification")

    public static var state: State {
        get { state(in: .standard) }
        set { setState(newValue, in: .standard) }
    }

    public static var isGranted: Bool {
        get { isGranted(in: .standard) }
        set { setGranted(newValue, in: .standard) }
    }

    public static var consent: State {
        get { state }
        set { state = newValue }
    }

    public static var isEnabled: Bool {
        get { isGranted }
        set { isGranted = newValue }
    }

    public static func state(in defaults: UserDefaults) -> State {
        if let rawValue = defaults.string(forKey: UDKey.telemetryConsent),
           let state = State(rawValue: rawValue) {
            return state
        }

        if let migratedState = migrateLegacyStateIfNeeded(in: defaults) {
            return migratedState
        }

        return .denied
    }

    public static func consent(in defaults: UserDefaults) -> State {
        state(in: defaults)
    }

    public static func isGranted(in defaults: UserDefaults) -> Bool {
        state(in: defaults) == .granted
    }

    public static func isEnabled(in defaults: UserDefaults) -> Bool {
        isGranted(in: defaults)
    }

    public static func setGranted(_ granted: Bool, in defaults: UserDefaults = .standard) {
        setState(granted ? .granted : .denied, in: defaults)
    }

    public static func setEnabled(_ enabled: Bool, in defaults: UserDefaults = .standard) {
        setGranted(enabled, in: defaults)
    }

    public static func setState(_ state: State, in defaults: UserDefaults = .standard) {
        let oldState = self.state(in: defaults)
        defaults.set(state.rawValue, forKey: UDKey.telemetryConsent)
        defaults.set(state == .granted, forKey: UDKey.analyticsEnabled)
        defaults.set(state == .granted, forKey: UDKey.crashReportingEnabled)

        guard oldState != state else { return }
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }

    public static func setConsent(_ consent: State, in defaults: UserDefaults = .standard) {
        setState(consent, in: defaults)
    }

    public static func reset(in defaults: UserDefaults = .standard) {
        setState(.denied, in: defaults)
    }

    private static func migrateLegacyStateIfNeeded(in defaults: UserDefaults) -> State? {
        let hasAnalyticsSetting = defaults.object(forKey: UDKey.analyticsEnabled) != nil
        let hasCrashSetting = defaults.object(forKey: UDKey.crashReportingEnabled) != nil
        guard hasAnalyticsSetting || hasCrashSetting else { return nil }

        let migratedState: State = (
            hasAnalyticsSetting
            && hasCrashSetting
            && defaults.bool(forKey: UDKey.analyticsEnabled)
            && defaults.bool(forKey: UDKey.crashReportingEnabled)
        ) ? .granted : .denied

        defaults.set(migratedState.rawValue, forKey: UDKey.telemetryConsent)
        defaults.set(migratedState == .granted, forKey: UDKey.analyticsEnabled)
        defaults.set(migratedState == .granted, forKey: UDKey.crashReportingEnabled)
        return migratedState
    }
}
