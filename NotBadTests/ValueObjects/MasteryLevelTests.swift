//
//  MasteryLevelTests.swift
//  NotBadTests
//
//  掌握程度值对象单元测试
//

import Testing
import SwiftUI
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
    
    @Test("所有等级都有图标")
    func allLevelsHaveIcons() {
        for level in MasteryLevel.allCases {
            #expect(!level.icon.isEmpty)
        }
    }
    
    @Test("星级从1到5")
    func starRatings() {
        #expect(MasteryLevel.none.stars == 1)
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
}
