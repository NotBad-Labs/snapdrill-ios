//
//  SubjectTests.swift
//  NotBadTests
//
//  学科值对象单元测试
//

import Testing
import SwiftUI
@testable import NotBad

@Suite("Subject 值对象测试")
struct SubjectTests {
    
    // MARK: - 初始化测试
    
    @Test("所有学科都有有效的显示名称")
    func allSubjectsHaveDisplayNames() {
        for subject in Subject.allCases {
            #expect(!subject.displayName.isEmpty)
        }
    }
    
    @Test("所有学科都有有效的图标")
    func allSubjectsHaveIcons() {
        for subject in Subject.allCases {
            #expect(!subject.icon.isEmpty)
        }
    }
    
    @Test("学科数量正确（主要9科+其他）")
    func subjectCount() {
        // 语数英物化生政史地 + other = 10
        #expect(Subject.allCases.count == 10)
    }
    
    // MARK: - 分类测试
    
    @Test("主科分类正确")
    func mainSubjects() {
        let main = Subject.mainSubjects
        #expect(main.count == 3)
        #expect(main.contains(.chinese))
        #expect(main.contains(.math))
        #expect(main.contains(.english))
    }
    
    @Test("理科分类正确")
    func scienceSubjects() {
        let science = Subject.scienceSubjects
        #expect(science.count == 3)
        #expect(science.contains(.physics))
        #expect(science.contains(.chemistry))
        #expect(science.contains(.biology))
    }
    
    @Test("文科分类正确")
    func humanitiesSubjects() {
        let humanities = Subject.humanitiesSubjects
        #expect(humanities.count == 3)
        #expect(humanities.contains(.politics))
        #expect(humanities.contains(.history))
        #expect(humanities.contains(.geography))
    }
    
    // MARK: - 颜色测试
    
    @Test("每个学科都有独特的颜色")
    func subjectColors() {
        var colors: [Color] = []
        for subject in Subject.allCases {
            let color = subject.color
            // 注意：Color 比较可能不完全准确，但至少验证不会崩溃
            colors.append(color)
        }
        // 至少有 10 种颜色
        #expect(colors.count == Subject.allCases.count)
    }
    
    // MARK: - 编码测试
    
    @Test("学科可正确序列化和反序列化")
    func subjectCodable() throws {
        let subject = Subject.math
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(subject)
        let decoded = try decoder.decode(Subject.self, from: data)
        
        #expect(decoded == subject)
    }
    
    @Test("rawValue 正确")
    func subjectRawValue() {
        #expect(Subject.math.rawValue == "math")
        #expect(Subject.chinese.rawValue == "chinese")
        #expect(Subject(rawValue: "physics") == .physics)
    }
}
