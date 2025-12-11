import XCTest
@testable import ReviewKit

final class ReviewSchedulerTests: XCTestCase {
    
    var scheduler: ReviewScheduler!
    var referenceDate: Date!
    
    override func setUp() {
        super.setUp()
        scheduler = ReviewScheduler()
        // 固定参考日期，避免测试时间依赖
        referenceDate = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1))!
    }
    
    // MARK: - 基础间隔测试
    
    func testFirstReviewInterval() {
        // 第一次复习，正常掌握，应该是 1 天后
        let nextDate = scheduler.calculateNextReviewDate(
            currentMastery: 2,
            reviewCount: 0,
            from: referenceDate
        )
        
        let interval = Calendar.current.dateComponents([.day], from: referenceDate, to: nextDate).day!
        XCTAssertEqual(interval, 1, "第一次复习后应该是 1 天间隔")
    }
    
    func testProgressiveIntervals() {
        // 验证间隔递增
        let intervals = (0..<7).map { reviewCount in
            scheduler.calculateIntervalDays(currentMastery: 2, reviewCount: reviewCount)
        }
        
        // 正常掌握（倍率 1.0）: [1, 2, 4, 7, 14, 30, 60]
        XCTAssertEqual(intervals, [1, 2, 4, 7, 14, 30, 60])
    }
    
    // MARK: - 掌握程度影响
    
    func testForgotShortensInterval() {
        let forgotInterval = scheduler.calculateIntervalDays(currentMastery: 0, reviewCount: 2)
        let normalInterval = scheduler.calculateIntervalDays(currentMastery: 2, reviewCount: 2)
        
        XCTAssertLessThan(forgotInterval, normalInterval, "忘记应该缩短间隔")
    }
    
    func testEasyExtendsInterval() {
        let easyInterval = scheduler.calculateIntervalDays(currentMastery: 4, reviewCount: 2)
        let normalInterval = scheduler.calculateIntervalDays(currentMastery: 2, reviewCount: 2)
        
        XCTAssertGreaterThan(easyInterval, normalInterval, "完全掌握应该延长间隔")
    }
    
    // MARK: - ReviewPerformance 枚举
    
    func testPerformanceEnum() {
        let basicDate = scheduler.calculateNextReviewDate(
            performance: .basic,
            reviewCount: 0,
            from: referenceDate
        )
        
        let masteryDate = scheduler.calculateNextReviewDate(
            currentMastery: ReviewPerformance.basic.rawValue,
            reviewCount: 0,
            from: referenceDate
        )
        
        XCTAssertEqual(basicDate, masteryDate, "两种调用方式结果应该一致")
    }
    
    // MARK: - 边界条件
    
    func testMinimumIntervalIsOneDay() {
        // 即使掌握程度很差，间隔也至少 1 天
        let interval = scheduler.calculateIntervalDays(currentMastery: 0, reviewCount: 0)
        XCTAssertGreaterThanOrEqual(interval, 1)
    }
    
    func testHighReviewCountUsesMaxInterval() {
        // 复习次数超过配置数组长度时，使用最大间隔
        let interval100 = scheduler.calculateIntervalDays(currentMastery: 2, reviewCount: 100)
        let interval6 = scheduler.calculateIntervalDays(currentMastery: 2, reviewCount: 6)
        
        XCTAssertEqual(interval100, interval6, "超出范围应使用最大间隔")
    }
    
    // MARK: - 自定义配置
    
    func testCustomConfiguration() {
        let customScheduler = ReviewScheduler(
            baseIntervals: [1, 3, 7, 14],
            masteryMultipliers: [0: 0.5, 1: 1.0, 2: 1.5, 3: 2.0]
        )
        
        let interval = customScheduler.calculateIntervalDays(currentMastery: 2, reviewCount: 1)
        // 3 * 1.5 = 4.5 → 4
        XCTAssertEqual(interval, 4)
    }
    
    // MARK: - Sendable 合规
    
    func testSchedulerIsSendable() async {
        // 验证可以跨 Actor 传递
        let localScheduler = self.scheduler! // 捕获本地副本，避免跨隔离域捕获 self
        let result = await Task.detached {
            localScheduler.calculateIntervalDays(currentMastery: 2, reviewCount: 0)
        }.value
        
        XCTAssertEqual(result, 1)
    }
}
