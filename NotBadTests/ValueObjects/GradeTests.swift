//
//  GradeTests.swift
//  NotBadTests
//
//  年级值对象单元测试
//

import Testing
import Foundation
import SwiftUI
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
    
    // MARK: - 显示属性测试
    
    @Test("shortLabel 格式正确")
    func shortLabelFormat() {
        #expect(Grade.grade1.shortLabel == "一年级")
        #expect(Grade.grade6.shortLabel == "六年级")
        #expect(Grade.grade7.shortLabel == "初一")
        #expect(Grade.grade9.shortLabel == "初三")
        #expect(Grade.grade10.shortLabel == "高一")
        #expect(Grade.grade12.shortLabel == "高三")
    }
    
    @Test("所有年级都有图标")
    func allGradesHaveIcons() {
        for grade in Grade.allCases {
            #expect(!grade.icon.isEmpty)
        }
    }
    
    @Test("所有年级都有颜色")
    func allGradesHaveColors() {
        for grade in Grade.allCases {
            _ = grade.color
        }
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
    
    @Test("年级 stage 属性正确")
    func gradeStageProperty() {
        #expect(Grade.grade1.stage == .primary)
        #expect(Grade.grade6.stage == .primary)
        #expect(Grade.grade7.stage == .junior)
        #expect(Grade.grade9.stage == .junior)
        #expect(Grade.grade10.stage == .senior)
        #expect(Grade.grade12.stage == .senior)
    }
    
    // MARK: - 排序测试
    
    @Test("年级序号正确递增")
    func gradeOrderIncreasing() {
        #expect(Grade.grade1.order == 1)
        #expect(Grade.grade6.order == 6)
        #expect(Grade.grade7.order == 7)
        #expect(Grade.grade9.order == 9)
        #expect(Grade.grade10.order == 10)
        #expect(Grade.grade12.order == 12)
        
        // 验证递增
        for i in 1..<Grade.allCases.count {
            #expect(Grade.allCases[i].order > Grade.allCases[i-1].order)
        }
    }
    
    @Test("Comparable 按序号排序")
    func comparableConformance() {
        #expect(Grade.grade1 < Grade.grade2)
        #expect(Grade.grade6 < Grade.grade7)
        #expect(Grade.grade9 < Grade.grade10)
        #expect(Grade.grade12 > Grade.grade1)
    }
    
    // MARK: - 毕业年级测试
    
    @Test("isGraduationYear 正确判断")
    func graduationYearProperty() {
        #expect(Grade.grade6.isGraduationYear == true)
        #expect(Grade.grade9.isGraduationYear == true)
        #expect(Grade.grade12.isGraduationYear == true)
        
        #expect(Grade.grade1.isGraduationYear == false)
        #expect(Grade.grade7.isGraduationYear == false)
        #expect(Grade.grade10.isGraduationYear == false)
    }
    
    @Test("graduationGrades 静态集合正确")
    func graduationGradesCollection() {
        #expect(Grade.graduationGrades.count == 3)
        #expect(Grade.graduationGrades.contains(.grade6))
        #expect(Grade.graduationGrades.contains(.grade9))
        #expect(Grade.graduationGrades.contains(.grade12))
    }
    
    // MARK: - 工厂方法测试
    
    @Test("from(order:) 创建正确")
    func fromOrderFactory() {
        #expect(Grade.from(order: 1) == .grade1)
        #expect(Grade.from(order: 7) == .grade7)
        #expect(Grade.from(order: 12) == .grade12)
        
        #expect(Grade.from(order: 0) == nil)
        #expect(Grade.from(order: 13) == nil)
    }
    
    @Test("grades(for:) 返回正确年级")
    func gradesForStage() {
        let primary = Grade.grades(for: .primary)
        #expect(primary.count == 6)
        
        let junior = Grade.grades(for: .junior)
        #expect(junior.count == 3)
        
        let senior = Grade.grades(for: .senior)
        #expect(senior.count == 3)
    }
    
    // MARK: - 静态集合测试
    
    @Test("primaryGrades 包含正确年级")
    func primaryGradesCollection() {
        #expect(Grade.primaryGrades.count == 6)
        for grade in Grade.primaryGrades {
            #expect(grade.stage == .primary)
        }
    }
    
    @Test("juniorGrades 包含正确年级")
    func juniorGradesCollection() {
        #expect(Grade.juniorGrades.count == 3)
        for grade in Grade.juniorGrades {
            #expect(grade.stage == .junior)
        }
    }
    
    @Test("seniorGrades 包含正确年级")
    func seniorGradesCollection() {
        #expect(Grade.seniorGrades.count == 3)
        for grade in Grade.seniorGrades {
            #expect(grade.stage == .senior)
        }
    }
    
    // MARK: - GradeStage 测试
    
    @Test("GradeStage 有3个学段")
    func gradeStageCount() {
        #expect(GradeStage.allCases.count == 3)
    }
    
    @Test("GradeStage 显示属性正确")
    func gradeStageDisplayProperties() {
        #expect(GradeStage.primary.displayName == "小学")
        #expect(GradeStage.junior.displayName == "初中")
        #expect(GradeStage.senior.displayName == "高中")
        
        #expect(GradeStage.primary.shortLabel == "小")
        #expect(GradeStage.junior.shortLabel == "初")
        #expect(GradeStage.senior.shortLabel == "高")
    }
    
    @Test("GradeStage 年级范围正确")
    func gradeStageRanges() {
        #expect(GradeStage.primary.gradeRange == "1-6年级")
        #expect(GradeStage.junior.gradeRange == "7-9年级")
        #expect(GradeStage.senior.gradeRange == "10-12年级")
        
        #expect(GradeStage.primary.gradeCount == 6)
        #expect(GradeStage.junior.gradeCount == 3)
        #expect(GradeStage.senior.gradeCount == 3)
    }
    
    @Test("GradeStage from(gradeOrder:) 正确")
    func gradeStageFromOrder() {
        #expect(GradeStage.from(gradeOrder: 1) == .primary)
        #expect(GradeStage.from(gradeOrder: 6) == .primary)
        #expect(GradeStage.from(gradeOrder: 7) == .junior)
        #expect(GradeStage.from(gradeOrder: 9) == .junior)
        #expect(GradeStage.from(gradeOrder: 10) == .senior)
        #expect(GradeStage.from(gradeOrder: 12) == .senior)
        
        #expect(GradeStage.from(gradeOrder: 0) == nil)
        #expect(GradeStage.from(gradeOrder: 13) == nil)
    }
    
    @Test("GradeStage contains(gradeOrder:) 正确")
    func gradeStageContainsOrder() {
        #expect(GradeStage.primary.contains(gradeOrder: 1) == true)
        #expect(GradeStage.primary.contains(gradeOrder: 6) == true)
        #expect(GradeStage.primary.contains(gradeOrder: 7) == false)
        
        #expect(GradeStage.junior.contains(gradeOrder: 7) == true)
        #expect(GradeStage.junior.contains(gradeOrder: 10) == false)
    }
    
    @Test("GradeStage Comparable 正确")
    func gradeStageComparable() {
        #expect(GradeStage.primary < GradeStage.junior)
        #expect(GradeStage.junior < GradeStage.senior)
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
    
    @Test("GradeStage Codable 正确")
    func gradeStageCodable() throws {
        let stage = GradeStage.junior
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(stage)
        let decoded = try decoder.decode(GradeStage.self, from: data)
        
        #expect(decoded == stage)
    }
}
