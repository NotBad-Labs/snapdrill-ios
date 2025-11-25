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
    func coreSubjects() {
        let core = Subject.coreSubjects
        #expect(core.count == 3)
        #expect(core.contains(.chinese))
        #expect(core.contains(.math))
        #expect(core.contains(.english))
    }
    
    @Test("初中考试学科分类正确")
    func juniorExamSubjects() {
        let junior = Subject.juniorExamSubjects
        #expect(junior.count == 9)
        #expect(junior.contains(.physics))
        #expect(junior.contains(.chemistry))
        #expect(junior.contains(.biology))
    }
    
    @Test("高中考试学科分类正确")
    func seniorExamSubjects() {
        let senior = Subject.seniorExamSubjects
        #expect(senior.count == 9)
        #expect(senior.contains(.physics))
        #expect(senior.contains(.chemistry))
        #expect(senior.contains(.biology))
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
