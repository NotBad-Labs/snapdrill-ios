// NotBad/Configuration/FeatureFlags.swift
// Feature flags with DEBUG toggles via UserDefaults and a RELEASE stub.

import Foundation

enum FeatureFlag: String, CaseIterable {
    case newOnboarding = "new_onboarding_flow"
    case advancedStatistics = "advanced_statistics"
}

extension FeatureFlag {
    var isEnabled: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: rawValue)
        #else
        return RemoteConfig.shared.bool(for: rawValue)
        #endif
    }
}

#if !DEBUG
// Stub RemoteConfig for RELEASE; replace with real implementation when ready.
final class RemoteConfig {
    static let shared = RemoteConfig()
    private init() {}
    func bool(for key: String) -> Bool { false }
}
#endif
