import SwiftUI

private struct AnalyticsServiceKey: EnvironmentKey {
    static let defaultValue: any AnalyticsService = LoggingAnalyticsService()
}

public extension EnvironmentValues {
    var analyticsService: any AnalyticsService {
        get { self[AnalyticsServiceKey.self] }
        set { self[AnalyticsServiceKey.self] = newValue }
    }
}
