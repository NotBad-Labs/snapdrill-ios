//
//  DifficultyTests.swift
//  NotBadTests
//
//  难度值对象单元测试
//

import Testing
import Foundation
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
        #expect(Difficulty.medium.stars == 3)
        #expect(Difficulty.extreme.stars == 5)
    }
    
    // MARK: - 比较测试
    
    @Test("Comparable 正确实现")
    func comparableConformance() {
        #expect(Difficulty.basic < Difficulty.easy)
        #expect(Difficulty.easy < Difficulty.medium)
        #expect(Difficulty.medium < Difficulty.hard)
        #expect(Difficulty.hard < Difficulty.extreme)
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
}
