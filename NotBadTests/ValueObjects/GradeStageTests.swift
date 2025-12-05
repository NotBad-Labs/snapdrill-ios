//
//  GradeStageTests.swift
//  NotBadTests
//
//  学段值对象单元测试
//

import Testing
import Foundation
@testable import NotBad

@Suite("GradeStage 值对象测试")
struct GradeStageTests {

    // MARK: - 初始化测试

    @Test("学段有3个等级")
    func gradeStageCount() {
        #expect(GradeStage.allCases.count == 3)
    }

    @Test("所有学段都有显示名称")
    func allGradeStagesHaveDisplayNames() {
        for stage in GradeStage.allCases {
            #expect(!stage.displayName.isEmpty)
        }
    }

    // MARK: - 枚举值测试

    @Test("学段包含小初高")
    func gradeStageValues() {
        #expect(GradeStage.primary.rawValue == "primary")
        #expect(GradeStage.junior.rawValue == "junior")
        #expect(GradeStage.senior.rawValue == "senior")
    }

    // MARK: - 显示属性测试

    @Test("shortLabel 简短有意义")
    func shortLabelNotEmpty() {
        for stage in GradeStage.allCases {
            #expect(!stage.shortLabel.isEmpty)
            #expect(stage.shortLabel.count <= 3)
        }
    }

    @Test("所有学段都有图标")
    func allGradeStagesHaveIcons() {
        for stage in GradeStage.allCases {
            #expect(!stage.icon.isEmpty)
        }

        #expect(GradeStage.primary.icon == "figure.child")
        #expect(GradeStage.junior.icon == "figure.stand")
        #expect(GradeStage.senior.icon == "graduationcap")
    }

    @Test("所有学段都有颜色")
    func allGradeStagesHaveColors() {
        #expect(GradeStage.primary.color == .green)
        #expect(GradeStage.junior.color == .orange)
        #expect(GradeStage.senior.color == .purple)
    }

    @Test("gradeRange 描述年级范围")
    func gradeRangeNotEmpty() {
        for stage in GradeStage.allCases {
            #expect(!stage.gradeRange.isEmpty)
        }
    }

    // MARK: - 年级关联测试

    @Test("各学段包含正确的年级数量")
    func gradesCountForStage() {
        #expect(GradeStage.primary.grades.count == 7)  // 幼儿园 + 1-6年级
        #expect(GradeStage.junior.grades.count == 3)   // 7-9年级
        #expect(GradeStage.senior.grades.count == 3)   // 10-12年级
    }

    @Test("小学包含1-6年级")
    func primaryContainsCorrectGrades() {
        let grades = GradeStage.primary.grades
        #expect(grades.contains(.grade1))
        #expect(grades.contains(.grade6))
        #expect(!grades.contains(.grade7))
    }

    @Test("初中包含7-9年级")
    func juniorContainsCorrectGrades() {
        let grades = GradeStage.junior.grades
        #expect(grades.contains(.grade7))
        #expect(grades.contains(.grade9))
        #expect(!grades.contains(.grade6))
        #expect(!grades.contains(.grade10))
    }

    @Test("高中包含10-12年级")
    func seniorContainsCorrectGrades() {
        let grades = GradeStage.senior.grades
        #expect(grades.contains(.grade10))
        #expect(grades.contains(.grade12))
        #expect(!grades.contains(.grade9))
    }

    // MARK: - Identifiable 测试

    @Test("id 使用 rawValue")
    func idEqualsRawValue() {
        for stage in GradeStage.allCases {
            #expect(stage.id == stage.rawValue)
        }
    }

    // MARK: - Codable 测试

    @Test("可以编解码")
    func codable() throws {
        let original = GradeStage.junior
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GradeStage.self, from: encoded)
        #expect(original == decoded)
    }

    // MARK: - Hashable 测试

    @Test("可用于 Set 和 Dictionary")
    func hashable() {
        let set: Set<GradeStage> = [.primary, .junior, .senior, .junior]
        #expect(set.count == 3)
    }
}
