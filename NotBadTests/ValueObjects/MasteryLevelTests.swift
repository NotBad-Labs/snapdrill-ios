//
//  MasteryLevelTests.swift
//  NotBadTests
//
//  掌握程度值对象单元测试
//

import Testing
import SwiftUI
import Foundation
@testable import NotBad

@Suite("MasteryLevel 值对象测试")
struct MasteryLevelTests {
    
    // MARK: - 初始化测试
    
    @Test("掌握程度有5个等级")
    func levelCount() {
        #expect(MasteryLevel.allCases.count == 5)
    }
    
    @Test("rawValue 从0到4")
    func rawValues() {
        #expect(MasteryLevel.none.rawValue == 0)
        #expect(MasteryLevel.glimpse.rawValue == 1)
        #expect(MasteryLevel.partial.rawValue == 2)
        #expect(MasteryLevel.good.rawValue == 3)
        #expect(MasteryLevel.mastered.rawValue == 4)
    }
    
    // MARK: - 显示属性测试
    
    @Test("所有等级都有显示名称")
    func allLevelsHaveDisplayNames() {
        for level in MasteryLevel.allCases {
            #expect(!level.displayName.isEmpty)
        }
    }
    
    @Test("shortLabel 简洁有效")
    func shortLabelValues() {
        #expect(MasteryLevel.none.shortLabel == "不会")
        #expect(MasteryLevel.glimpse.shortLabel == "半解")
        #expect(MasteryLevel.partial.shortLabel == "似懂")
        #expect(MasteryLevel.good.shortLabel == "掌握")
        #expect(MasteryLevel.mastered.shortLabel == "精通")
    }
    
    @Test("detailText 详细描述")
    func detailTextNotEmpty() {
        for level in MasteryLevel.allCases {
            #expect(!level.detailText.isEmpty)
            #expect(level.detailText.count > 5)
        }
    }
    
    @Test("所有等级都有图标")
    func allLevelsHaveIcons() {
        for level in MasteryLevel.allCases {
            #expect(!level.icon.isEmpty)
        }
    }
    
    @Test("所有等级都有颜色")
    func allLevelsHaveColors() {
        // 验证颜色渐进：红 → 绿
        #expect(MasteryLevel.none.color == .red)
        #expect(MasteryLevel.mastered.color == .green)
        
        for level in MasteryLevel.allCases {
            _ = level.color
        }
    }
    
    @Test("星级从1到5")
    func starRatings() {
        #expect(MasteryLevel.none.stars == 1)
        #expect(MasteryLevel.glimpse.stars == 2)
        #expect(MasteryLevel.partial.stars == 3)
        #expect(MasteryLevel.good.stars == 4)
        #expect(MasteryLevel.mastered.stars == 5)
    }
    
    // MARK: - 进度值测试
    
    @Test("进度值在0到1之间")
    func progressValues() {
        #expect(MasteryLevel.none.progress == 0.0)
        #expect(MasteryLevel.mastered.progress == 1.0)
        
        for level in MasteryLevel.allCases {
            #expect(level.progress >= 0.0)
            #expect(level.progress <= 1.0)
        }
    }
    
    // MARK: - 复习间隔测试
    
    @Test("复习间隔天数正确")
    func reviewIntervalDays() {
        #expect(MasteryLevel.none.reviewIntervalDays == 0)      // 立即
        #expect(MasteryLevel.glimpse.reviewIntervalDays == 1)   // 1天
        #expect(MasteryLevel.partial.reviewIntervalDays == 3)   // 3天
        #expect(MasteryLevel.good.reviewIntervalDays == 7)      // 7天
        #expect(MasteryLevel.mastered.reviewIntervalDays == 14) // 14天
    }
    
    @Test("复习间隔递增")
    func reviewIntervalIncreasing() {
        var previousInterval = -1
        for level in MasteryLevel.allCases {
            #expect(level.reviewIntervalDays > previousInterval)
            previousInterval = level.reviewIntervalDays
        }
    }
    
    @Test("reviewPriority 递减")
    func reviewPriorityDecreasing() {
        // 掌握程度越低，复习优先级越高
        #expect(MasteryLevel.none.reviewPriority > MasteryLevel.mastered.reviewPriority)
        
        var previousPriority = Int.max
        for level in MasteryLevel.allCases {
            #expect(level.reviewPriority < previousPriority)
            previousPriority = level.reviewPriority
        }
    }
    
    // MARK: - 状态判断测试
    
    @Test("needsReview 正确判断")
    func needsReviewFlag() {
        #expect(MasteryLevel.none.needsReview == true)
        #expect(MasteryLevel.glimpse.needsReview == true)
        #expect(MasteryLevel.partial.needsReview == true)
        #expect(MasteryLevel.good.needsReview == false)
        #expect(MasteryLevel.mastered.needsReview == false)
    }
    
    @Test("isMastered 正确判断")
    func isMasteredFlag() {
        #expect(MasteryLevel.none.isMastered == false)
        #expect(MasteryLevel.glimpse.isMastered == false)
        #expect(MasteryLevel.partial.isMastered == false)
        #expect(MasteryLevel.good.isMastered == true)
        #expect(MasteryLevel.mastered.isMastered == true)
    }
    
    @Test("isFullyMastered 正确判断")
    func isFullyMasteredFlag() {
        #expect(MasteryLevel.none.isFullyMastered == false)
        #expect(MasteryLevel.good.isFullyMastered == false)
        #expect(MasteryLevel.mastered.isFullyMastered == true)
    }
    
    @Test("isUnknown 正确判断")
    func isUnknownFlag() {
        #expect(MasteryLevel.none.isUnknown == true)
        #expect(MasteryLevel.glimpse.isUnknown == false)
        #expect(MasteryLevel.mastered.isUnknown == false)
    }
    
    // MARK: - 工厂方法测试
    
    @Test("MasteryLevel from(stars:) 正常值创建正确")
    func masteryLevelFromStarsFactoryNormal() {
        // 使用 Optional 比较方式，避免可能的类型推断问题
        let result1: MasteryLevel? = MasteryLevel.from(stars: 1)
        let result2: MasteryLevel? = MasteryLevel.from(stars: 2)
        let result3: MasteryLevel? = MasteryLevel.from(stars: 3)
        let result4: MasteryLevel? = MasteryLevel.from(stars: 4)
        let result5: MasteryLevel? = MasteryLevel.from(stars: 5)
        
        #expect(result1 != nil)
        #expect(result2 != nil)
        #expect(result3 != nil)
        #expect(result4 != nil)
        #expect(result5 != nil)
        
        if let r1 = result1 { #expect(r1 == .none) }
        if let r2 = result2 { #expect(r2 == .glimpse) }
        if let r3 = result3 { #expect(r3 == .partial) }
        if let r4 = result4 { #expect(r4 == .good) }
        if let r5 = result5 { #expect(r5 == .mastered) }
    }
    
    @Test("MasteryLevel from(stars:) 边界值返回 nil")
    func masteryLevelFromStarsFactoryBoundary() {
        #expect(MasteryLevel.from(stars: 0) == nil)
        #expect(MasteryLevel.from(stars: 6) == nil)
        #expect(MasteryLevel.from(stars: -1) == nil)
    }
    
    @Test("MasteryLevel from(progress:) 创建正确")
    func masteryLevelFromProgressFactory() {
        #expect(MasteryLevel.from(progress: 0.0) == .none)
        #expect(MasteryLevel.from(progress: 0.5) == .partial)
        #expect(MasteryLevel.from(progress: 1.0) == .mastered)
        
        // 边界处理
        #expect(MasteryLevel.from(progress: -0.5) == .none)
        #expect(MasteryLevel.from(progress: 1.5) == .mastered)
    }
    
    // MARK: - 静态集合测试
    
    @Test("reviewNeeded 包含正确等级")
    func reviewNeededCollection() {
        #expect(MasteryLevel.reviewNeeded.count == 3)
        #expect(MasteryLevel.reviewNeeded.contains(.none))
        #expect(MasteryLevel.reviewNeeded.contains(.glimpse))
        #expect(MasteryLevel.reviewNeeded.contains(.partial))
        #expect(!MasteryLevel.reviewNeeded.contains(.good))
    }
    
    @Test("masteredLevels 包含正确等级")
    func masteredLevelsCollection() {
        #expect(MasteryLevel.masteredLevels.count == 2)
        #expect(MasteryLevel.masteredLevels.contains(.good))
        #expect(MasteryLevel.masteredLevels.contains(.mastered))
    }
    
    @Test("sortedByReviewPriority 正确排序")
    func sortedByReviewPriorityOrder() {
        let sorted = MasteryLevel.sortedByReviewPriority
        
        for i in 1..<sorted.count {
            #expect(sorted[i-1].reviewPriority > sorted[i].reviewPriority)
        }
    }
    
    // MARK: - 比较测试
    
    @Test("Comparable 正确实现")
    func comparableConformance() {
        #expect(MasteryLevel.none < MasteryLevel.glimpse)
        #expect(MasteryLevel.glimpse < MasteryLevel.partial)
        #expect(MasteryLevel.partial < MasteryLevel.good)
        #expect(MasteryLevel.good < MasteryLevel.mastered)
        
        #expect(MasteryLevel.mastered > MasteryLevel.none)
    }
    
    // MARK: - 编码测试
    
    @Test("Codable 正确编解码")
    func codableRoundTrip() throws {
        let original = MasteryLevel.good
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(MasteryLevel.self, from: data)
        
        #expect(decoded == original)
    }
    
    // MARK: - 描述测试
    
    @Test("description 等于 displayName")
    func descriptionEqualsDisplayName() {
        for level in MasteryLevel.allCases {
            #expect(level.description == level.displayName)
        }
    }
}
