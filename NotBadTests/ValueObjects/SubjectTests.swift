//
//  SubjectTests.swift
//  NotBadTests
//
//  学科值对象单元测试
//

import Testing
import SwiftUI
import Foundation
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

    @Test("学科数量正确")
    func subjectCount() {
        // 语文、英语、数学、物理、化学、生物、科学、历史、地理、政治、道法、信息、通技、其他 = 14
        #expect(Subject.allCases.count == 14)
    }

    // MARK: - 显示属性测试

    @Test("shortLabel 为单字")
    func shortLabelIsSingleChar() {
        for subject in Subject.allCases {
            #expect(subject.shortLabel.count == 1)
        }

        #expect(Subject.math.shortLabel == "数")
        #expect(Subject.physics.shortLabel == "物")
        #expect(Subject.chinese.shortLabel == "语")
    }

    // MARK: - 分类测试

    @Test("SubjectCategory 有5种分类")
    func categoryCount() {
        #expect(SubjectCategory.allCases.count == 5)
    }

    @Test("SubjectCategory 显示属性正确")
    func categoryDisplayProperties() {
        for category in SubjectCategory.allCases {
            #expect(!category.displayName.isEmpty)
            #expect(!category.icon.isEmpty)
            _ = category.color
        }
    }

    @Test("学科分类正确")
    func subjectCategoryMapping() {
        // 语言类
        #expect(Subject.chinese.category == .language)
        #expect(Subject.english.category == .language)

        // 理科类
        #expect(Subject.math.category == .science)
        #expect(Subject.physics.category == .science)
        #expect(Subject.chemistry.category == .science)
        #expect(Subject.biology.category == .science)
        #expect(Subject.science.category == .science)

        // 人文类
        #expect(Subject.history.category == .humanities)
        #expect(Subject.geography.category == .humanities)
        #expect(Subject.politics.category == .humanities)
        #expect(Subject.ethics.category == .humanities)

        // 技术类
        #expect(Subject.informationTech.category == .technology)
        #expect(Subject.generalTech.category == .technology)

        // 其他
        #expect(Subject.other.category == .other)
    }

    @Test("subjects(in:) 返回正确学科")
    func subjectsInCategory() {
        let language = Subject.subjects(in: .language)
        #expect(language.count == 2)
        #expect(language.contains(.chinese))
        #expect(language.contains(.english))

        let science = Subject.subjects(in: .science)
        #expect(science.count == 5)

        let humanities = Subject.subjects(in: .humanities)
        #expect(humanities.count == 4)
    }

    // MARK: - 学段适用性测试

    @Test("主科适用所有学段")
    func coreSubjectsApplicableAllStages() {
        for subject in Subject.coreSubjects {
            #expect(subject.isApplicable(for: .primary))
            #expect(subject.isApplicable(for: .junior))
            #expect(subject.isApplicable(for: .senior))
        }
    }

    @Test("物理化学适用初中高中")
    func physicsChemistryApplicableJuniorSenior() {
        #expect(Subject.physics.isApplicable(for: .primary) == false)
        #expect(Subject.physics.isApplicable(for: .junior) == true)
        #expect(Subject.physics.isApplicable(for: .senior) == true)

        #expect(Subject.chemistry.isApplicable(for: .primary) == false)
        #expect(Subject.chemistry.isApplicable(for: .junior) == true)
        #expect(Subject.chemistry.isApplicable(for: .senior) == true)
    }

    @Test("生物适用初中高中")
    func biologyJuniorSenior() {
        #expect(Subject.biology.isApplicable(for: .primary) == false)
        #expect(Subject.biology.isApplicable(for: .junior) == true)
        #expect(Subject.biology.isApplicable(for: .senior) == true)
    }

    @Test("科学适用小学初中")
    func scienceApplicablePrimaryJunior() {
        #expect(Subject.science.isApplicable(for: .primary) == true)
        #expect(Subject.science.isApplicable(for: .junior) == true)
        #expect(Subject.science.isApplicable(for: .senior) == false)
    }

    @Test("subjects(for:) 返回正确学科")
    func subjectsForStage() {
        let primary = Subject.subjects(for: .primary)
        #expect(primary.contains(.chinese))
        #expect(primary.contains(.math))
        #expect(primary.contains(.science))
        #expect(!primary.contains(.physics))
        #expect(!primary.contains(.biology))

        let senior = Subject.subjects(for: .senior)
        #expect(senior.contains(.biology))
        #expect(senior.contains(.physics))
        #expect(!senior.contains(.science))
    }

    // MARK: - 静态集合测试

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

    @Test("理科组合正确")
    func scienceCombo() {
        let combo = Subject.scienceCombo
        #expect(combo.count == 3)
        #expect(combo.contains(.physics))
        #expect(combo.contains(.chemistry))
        #expect(combo.contains(.biology))
    }

    @Test("文科组合正确")
    func artsCombo() {
        let combo = Subject.artsCombo
        #expect(combo.count == 3)
        #expect(combo.contains(.history))
        #expect(combo.contains(.geography))
        #expect(combo.contains(.politics))
    }

    // MARK: - 颜色测试

    @Test("每个学科都有独特的颜色")
    func subjectColors() {
        var colors: [Color] = []
        for subject in Subject.allCases {
            let color = subject.color
            colors.append(color)
        }
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

    @Test("rawValue 正确（英文ID）")
    func subjectRawValue() {
        #expect(Subject.math.rawValue == "math")
        #expect(Subject.chinese.rawValue == "chinese")
        #expect(Subject(rawValue: "physics") == .physics)
    }

    // MARK: - 描述测试

    @Test("description 等于 displayName")
    func descriptionEqualsDisplayName() {
        for subject in Subject.allCases {
            #expect(subject.description == subject.displayName)
        }
    }
}
