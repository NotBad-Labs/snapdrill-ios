//
//  GradeTests.swift
//  NotBadTests
//
//  年级值对象单元测试
//

import Testing
import Foundation
@testable import NotBad

@Suite("Grade 值对象测试")
struct GradeTests {
    
    // MARK: - 初始化测试
    
    @Test("所有年级都有有效的显示名称")
    func allGradesHaveDisplayNames() {
        for grade in Grade.allCases {
            #expect(!grade.displayName.isEmpty)
        }
    }
    
    @Test("年级数量正确（小学6年+初中3年+高中3年=12）")
    func gradeCount() {
        #expect(Grade.allCases.count == 12)
    }
    
    // MARK: - 学段测试
    
    @Test("小学学段包含正确的年级")
    func primarySchoolGrades() {
        let primary = GradeStage.primary.grades
        #expect(primary.count == 6)
        #expect(primary.contains(.grade1))
        #expect(primary.contains(.grade6))
        #expect(!primary.contains(.grade7))
    }
    
    @Test("初中学段包含正确的年级")
    func middleSchoolGrades() {
        let middle = GradeStage.junior.grades
        #expect(middle.count == 3)
        #expect(middle.contains(.grade7))
        #expect(middle.contains(.grade9))
        #expect(!middle.contains(.grade6))
        #expect(!middle.contains(.grade10))
    }
    
    @Test("高中学段包含正确的年级")
    func highSchoolGrades() {
        let high = GradeStage.senior.grades
        #expect(high.count == 3)
        #expect(high.contains(.grade10))
        #expect(high.contains(.grade12))
        #expect(!high.contains(.grade9))
    }
    
    // MARK: - 排序测试
    
    @Test("年级序号正确递增")
    func gradeOrderIncreasing() {
        #expect(Grade.grade1.order < Grade.grade2.order)
        #expect(Grade.grade6.order < Grade.grade7.order)
        #expect(Grade.grade9.order < Grade.grade10.order)
        #expect(Grade.grade12.order > Grade.grade1.order)
    }
    
    // MARK: - 编码测试
    
    @Test("年级可正确序列化和反序列化")
    func gradeCodable() throws {
        let grade = Grade.grade10
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(grade)
        let decoded = try decoder.decode(Grade.self, from: data)
        
        #expect(decoded == grade)
    }
}
