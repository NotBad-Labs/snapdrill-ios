// ReviewKit CLI - 终极纯粹性验证
//
// 这是一个没有任何 UI 的命令行工具。
// 如果它能成功运行，证明 ReviewKit 完全独立于 UIKit/SwiftUI。

import Foundation
import ReviewKit

print("═══════════════════════════════════════════")
print("  ReviewKit CLI - 间隔重复算法验证")
print("═══════════════════════════════════════════\n")

// 1. 创建调度器
let scheduler = ReviewScheduler()

// 2. 模拟复习场景
print("📚 模拟复习场景：一道新题目的复习轨迹\n")

let today = Date()
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd"

print("掌握程度: .good (正常掌握)\n")
print("复习次数 │ 间隔天数 │ 下次复习日期")
print("─────────┼──────────┼──────────────")

for reviewCount in 0..<7 {
    let nextDate = scheduler.calculateNextReviewDate(
        performance: .good,
        reviewCount: reviewCount,
        from: today
    )
    let intervalDays = scheduler.calculateIntervalDays(currentMastery: 2, reviewCount: reviewCount)
    print(String(format: "    %d    │    %2d    │ %@", reviewCount, intervalDays, dateFormatter.string(from: nextDate)))
}

print("\n─────────────────────────────────────────────")

// 3. 不同掌握程度对比
print("\n📊 不同掌握程度的间隔对比（第3次复习后）\n")

let performances: [(ReviewPerformance, String)] = [
    (.forgot, "完全忘记"),
    (.hard, "勉强记得"),
    (.good, "正常掌握"),
    (.easy, "轻松掌握")
]

print("掌握程度 │ 间隔天数")
print("─────────┼──────────")

for (performance, name) in performances {
    let interval = scheduler.calculateIntervalDays(currentMastery: performance.rawValue, reviewCount: 3)
    print("\(name) │    \(interval)")
}

print("\n═══════════════════════════════════════════")
print("  ✅ ReviewKit 验证通过！")
print("  核心算法完全独立于 UI，可复用到任何平台。")
print("═══════════════════════════════════════════\n")
