import Foundation

/// 复习评分等级
public enum ReviewRating {
    case again  // 忘记了
    case hard   // 很难
    case good   // 还行
    case easy   // 简单
}

/// 复习调度器，计算下一次复习时间
public struct ReviewScheduler {
    public init() {}
    
    /// 计算下一次复习时间
    /// - Parameters:
    ///   - item: 当前复习条目
    ///   - rating: 用户评分
    /// - Returns: 更新后的复习条目（包含新的 lastReviewedAt 和 nextReviewAt）
    public func scheduleNextReview(for item: ReviewItem, rating: ReviewRating) -> ReviewItem {
        var newItem = item
        let now = Date()
        newItem.lastReviewedAt = now
        
        let interval = self.interval(for: rating)
        newItem.nextReviewAt = now.addingTimeInterval(interval)
        return newItem
    }
    
    public func interval(for rating: ReviewRating) -> TimeInterval {
        switch rating {
        case .again:
            return 60 * 5 // 5分钟
        case .hard:
            return 60 * 60 * 24 * 1 // 1天
        case .good:
            return 60 * 60 * 24 * 3 // 3天
        case .easy:
            return 60 * 60 * 24 * 7 // 7天
        }
    }
}
