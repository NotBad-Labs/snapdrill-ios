//
//  DifficultyTests.swift
//  NotBadTests
//
//  难度值对象单元测试
//

import Testing
import Foundation
import SwiftUI
@testable import NotBad

@Suite("Difficulty 值对象测试")
struct DifficultyTests {
    
    // MARK: - 初始化测试
    
    @Test("难度有5个等级")
    func difficultyCount() {
        #expect(Difficulty.allCases.count == 5)
    }
    
    @Test("所有难度都有显示名称")
    func allDifficultiesHaveDisplayNames() {
        for difficulty in Difficulty.allCases {
            #expect(!difficulty.displayName.isEmpty)
        }
    }
    
    // MARK: - 数值测试
    
    @Test("难度值从0到4")
    func difficultyValues() {
        #expect(Difficulty.basic.rawValue == 0)
        #expect(Difficulty.easy.rawValue == 1)
        #expect(Difficulty.medium.rawValue == 2)
        #expect(Difficulty.hard.rawValue == 3)
        #expect(Difficulty.extreme.rawValue == 4)
    }
    
    @Test("星级显示正确（1-5）")
    func starDisplay() {
        #expect(Difficulty.basic.stars == 1)
        #expect(Difficulty.easy.stars == 2)
        #expect(Difficulty.medium.stars == 3)
        #expect(Difficulty.hard.stars == 4)
        #expect(Difficulty.extreme.stars == 5)
    }
    
    // MARK: - 显示属性测试
    
    @Test("shortLabel 为单字")
    func shortLabelIsSingleChar() {
        for difficulty in Difficulty.allCases {
            #expect(difficulty.shortLabel.count == 1)
        }
        
        #expect(Difficulty.basic.shortLabel == "送")
        #expect(Difficulty.extreme.shortLabel == "压")
    }
    
    @Test("detailText 描述详细")
    func detailTextNotEmpty() {
        for difficulty in Difficulty.allCases {
            #expect(!difficulty.detailText.isEmpty)
            #expect(difficulty.detailText.count > 5) // 应该是完整句子
        }
    }
    
    @Test("所有难度都有图标")
    func allDifficultiesHaveIcons() {
        for difficulty in Difficulty.allCases {
            #expect(!difficulty.icon.isEmpty)
        }
        
        #expect(Difficulty.extreme.icon == "flame.fill")
    }
    
    @Test("所有难度都有颜色")
    func allDifficultiesHaveColors() {
        // 验证颜色存在且不会崩溃
        for difficulty in Difficulty.allCases {
            _ = difficulty.color
        }
        
        // 验证颜色渐进：绿 → 红
        #expect(Difficulty.basic.color == .mint)
        #expect(Difficulty.extreme.color == .red)
    }
    
    // MARK: - 系数和指标测试
    
    @Test("coefficient 在0-1范围内")
    func coefficientRange() {
        for difficulty in Difficulty.allCases {
            #expect(difficulty.coefficient >= 0.0)
            #expect(difficulty.coefficient <= 1.0)
        }
        
        #expect(Difficulty.basic.coefficient == 0.0)
        #expect(Difficulty.extreme.coefficient == 1.0)
    }
    
    @Test("timeMultiplier 合理范围")
    func timeMultiplierValues() {
        #expect(Difficulty.basic.timeMultiplier == 0.5)
        #expect(Difficulty.easy.timeMultiplier == 1.0)
        #expect(Difficulty.medium.timeMultiplier == 1.5)
        #expect(Difficulty.hard.timeMultiplier == 2.0)
        #expect(Difficulty.extreme.timeMultiplier == 3.0)
        
        // 验证递增
        var previousMultiplier = 0.0
        for difficulty in Difficulty.allCases {
            #expect(difficulty.timeMultiplier > previousMultiplier)
            previousMultiplier = difficulty.timeMultiplier
        }
    }
    
    // MARK: - 工厂方法测试
    
    @Test("Difficulty from(stars:) 创建正确")
    func difficultyFromStarsFactory() {
        #expect(Difficulty.from(stars: 1) == .basic)
        #expect(Difficulty.from(stars: 3) == .medium)
        #expect(Difficulty.from(stars: 5) == .extreme)
        
        #expect(Difficulty.from(stars: 0) == nil)
        #expect(Difficulty.from(stars: 6) == nil)
    }
    
    @Test("Difficulty from(coefficient:) 创建正确")
    func difficultyFromCoefficientFactory() {
        #expect(Difficulty.from(coefficient: 0.0) == .basic)
        #expect(Difficulty.from(coefficient: 0.5) == .medium)
        #expect(Difficulty.from(coefficient: 1.0) == .extreme)
        
        // 边界处理
        #expect(Difficulty.from(coefficient: -0.5) == .basic)
        #expect(Difficulty.from(coefficient: 1.5) == .extreme)
    }
    
    // MARK: - 比较测试
    
    @Test("Comparable 正确实现")
    func comparableConformance() {
        #expect(Difficulty.basic < Difficulty.easy)
        #expect(Difficulty.easy < Difficulty.medium)
        #expect(Difficulty.medium < Difficulty.hard)
        #expect(Difficulty.hard < Difficulty.extreme)
        
        #expect(Difficulty.extreme > Difficulty.basic)
    }
    
    // MARK: - Identifiable 测试
    
    @Test("id 等于 rawValue")
    func identifiableId() {
        for difficulty in Difficulty.allCases {
            #expect(difficulty.id == difficulty.rawValue)
        }
    }
    
    // MARK: - 编码测试
    
    @Test("Codable 正确编解码")
    func codableRoundTrip() throws {
        let original = Difficulty.hard
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Difficulty.self, from: data)
        
        #expect(decoded == original)
    }
    
    // MARK: - 描述测试
    
    @Test("description 等于 displayName")
    func descriptionEqualsDisplayName() {
        for difficulty in Difficulty.allCases {
            #expect(difficulty.description == difficulty.displayName)
        }
    }
}
