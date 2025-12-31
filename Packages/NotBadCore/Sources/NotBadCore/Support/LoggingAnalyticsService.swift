import Foundation
import OSLog

/// 基于日志的统计服务 (具体实现层)
///
/// 目前阶段暂不接入第三方 SDK，仅通过 OSLog 打印统计事件。
/// 未来如果要接入 Firebase，只需新建一个 FirebaseAnalyticsService 遵循 AnalyticsService 协议即可。
public final class LoggingAnalyticsService: AnalyticsService {
    private let logger = Logger(subsystem: "com.LIAOYIMING.NotBad", category: "Analytics")
    
    public init() {}
    
    public func logEvent(_ name: String, properties: [String: String]?) {
        if let properties = properties {
            logger.info("[Analytics] Event: \(name), Props: \(properties)")
        } else {
            logger.info("[Analytics] Event: \(name)")
        }
    }
}
