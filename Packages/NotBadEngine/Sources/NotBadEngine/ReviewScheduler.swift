import Foundation
import NotBadCore

/// 复习调度引擎
public actor ReviewScheduler {
    public init() {}
    
    /// 计算下一次复习时间
    public func calculateNextReviewDate(for item: ReviewItem, performance: Double) -> Date {
        // TODO: 实现基于间隔重复算法的逻辑
        return Date().addingTimeInterval(86400) // 默认一天后
    }
}
