// NotBad/Core/Monitoring/AppMetrics.swift
// Minimal metrics helper with DEBUG timing logs and a pluggable analytics sink.

import Foundation

protocol AnalyticsSink {
    func track(_ action: String, properties: [String: Any])
}

#if DEBUG
final class DebugConsoleAnalytics: AnalyticsSink {
    func track(_ action: String, properties: [String: Any]) {
        print("📊 [\(action)] props=\(properties)")
    }
}
#endif

final class AppMetrics {
    static let shared = AppMetrics()
    private var sink: AnalyticsSink?

    private init() {
        #if DEBUG
        sink = DebugConsoleAnalytics()
        #endif
    }

    @discardableResult
    func trackAction<T>(_ action: String, properties: [String: Any] = [:], _ work: () throws -> T) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - start
            var props = properties
            props["duration_ms"] = (duration * 1000).rounded()
            #if DEBUG
            print("📊 [\(action)] took \((duration * 1000).rounded())ms")
            #endif
            sink?.track(action, properties: props)
        }
        return try work()
    }

    func trackEvent(_ action: String, properties: [String: Any] = [:]) {
        #if DEBUG
        print("📈 [\(action)] props=\(properties)")
        #endif
        sink?.track(action, properties: properties)
    }
}
