//
//  ReviewItemTypeTests.swift
//  NotBadTests
//
//  题型值对象单元测试
//

import Testing
import Foundation
@testable import NotBad

@Suite("ReviewItemType 值对象测试")
struct ReviewItemTypeTests {

    // MARK: - 基础测试

    @Test("ReviewItemType 有15种题型")
    func typeCount() {
        #expect(ReviewItemType.allCases.count == 15)
    }

    @Test("所有题型都有显示名称")
    func allTypesHaveDisplayNames() {
        for type in ReviewItemType.allCases {
            #expect(!type.displayName.isEmpty)
        }
    }

    @Test("所有题型都有简短标签")
    func allTypesHaveShortLabels() {
        for type in ReviewItemType.allCases {
            #expect(!type.shortLabel.isEmpty)
            #expect(type.shortLabel.count == 1) // 单字标签
        }
    }

    @Test("所有题型都有图标")
    func allTypesHaveIcons() {
        for type in ReviewItemType.allCases {
            #expect(!type.icon.isEmpty)
        }
    }

    // MARK: - 分类测试

    @Test("ReviewItemCategory 有4种分类")
    func categoryCount() {
        #expect(ReviewItemCategory.allCases.count == 4)
    }

    @Test("客观题归类正确")
    func objectiveTypesCategory() {
        #expect(ReviewItemType.choice.category == .objective)
        #expect(ReviewItemType.multiChoice.category == .objective)
        #expect(ReviewItemType.judgment.category == .objective)
        #expect(ReviewItemType.fillBlank.category == .objective)
        #expect(ReviewItemType.matching.category == .objective)
    }

    @Test("主观题归类正确")
    func subjectiveTypesCategory() {
        #expect(ReviewItemType.shortAnswer.category == .subjective)
        #expect(ReviewItemType.calculation.category == .subjective)
        #expect(ReviewItemType.proof.category == .subjective)
        #expect(ReviewItemType.drawing.category == .subjective)
        #expect(ReviewItemType.experiment.category == .subjective)
        #expect(ReviewItemType.analysis.category == .subjective)
    }

    @Test("综合题归类正确")
    func comprehensiveTypesCategory() {
        #expect(ReviewItemType.reading.category == .comprehensive)
        #expect(ReviewItemType.writing.category == .comprehensive)
        #expect(ReviewItemType.cloze.category == .comprehensive)
    }

    @Test("types(in:) 返回正确数量")
    func typesInCategory() {
        #expect(ReviewItemType.types(in: .objective).count == 5)
        #expect(ReviewItemType.types(in: .subjective).count == 6)
        #expect(ReviewItemType.types(in: .comprehensive).count == 3)
        #expect(ReviewItemType.types(in: .other).count == 1)
    }

    // MARK: - 分类便捷属性测试

    @Test("isObjective 正确判断")
    func isObjectiveProperty() {
        #expect(ReviewItemType.choice.isObjective == true)
        #expect(ReviewItemType.calculation.isObjective == false)
    }

    @Test("isSubjective 正确判断")
    func isSubjectiveProperty() {
        #expect(ReviewItemType.calculation.isSubjective == true)
        #expect(ReviewItemType.choice.isSubjective == false)
    }

    @Test("isComprehensive 正确判断")
    func isComprehensiveProperty() {
        #expect(ReviewItemType.writing.isComprehensive == true)
        #expect(ReviewItemType.choice.isComprehensive == false)
    }

    // MARK: - 时间和难度测试

    @Test("estimatedMinutes 为正数")
    func estimatedMinutesPositive() {
        for type in ReviewItemType.allCases {
            #expect(type.estimatedMinutes > 0)
        }
    }

    @Test("选择题时间最短")
    func choiceShortestTime() {
        #expect(ReviewItemType.choice.estimatedMinutes == 1)
        #expect(ReviewItemType.judgment.estimatedMinutes == 1)
    }

    @Test("作文时间最长")
    func writingLongestTime() {
        #expect(ReviewItemType.writing.estimatedMinutes == 45)
    }

    @Test("difficultyWeight 根据分类设置")
    func difficultyWeightByCategory() {
        #expect(ReviewItemType.choice.difficultyWeight == 1.0)
        #expect(ReviewItemType.calculation.difficultyWeight == 1.5)
        #expect(ReviewItemType.writing.difficultyWeight == 2.0)
    }

    @Test("estimatedTimeDescription 返回非空字符串")
    func estimatedTimeDescriptionNotEmpty() {
        for type in ReviewItemType.allCases {
            #expect(!type.estimatedTimeDescription.isEmpty)
        }
    }

    // MARK: - 学科适用性测试

    @Test("applicableSubjects 返回非空数组")
    func applicableSubjectsNotEmpty() {
        for type in ReviewItemType.allCases {
            #expect(!type.applicableSubjects.isEmpty)
        }
    }

    @Test("完形填空仅适用于英语")
    func clozeOnlyForEnglish() {
        #expect(ReviewItemType.cloze.applicableSubjects.count == 1)
        #expect(ReviewItemType.cloze.applicableSubjects.first == .english)
    }

    @Test("计算题适用于数学物理化学")
    func calculationForMathPhysicsChemistry() {
        let subjects = ReviewItemType.calculation.applicableSubjects

        #expect(subjects.contains(.math))
        #expect(subjects.contains(.physics))
        #expect(subjects.contains(.chemistry))
    }

    @Test("isApplicable(to:) 正确判断")
    func isApplicableToSubject() {
        #expect(ReviewItemType.cloze.isApplicable(to: .english) == true)
        #expect(ReviewItemType.cloze.isApplicable(to: .math) == false)

        #expect(ReviewItemType.calculation.isApplicable(to: .math) == true)
        #expect(ReviewItemType.calculation.isApplicable(to: .chinese) == false)
    }

    @Test("types(for:) 返回适用题型")
    func typesForSubject() {
        let mathTypes = ReviewItemType.types(for: .math)

        #expect(mathTypes.contains(.calculation))
        #expect(mathTypes.contains(.proof))
        #expect(!mathTypes.contains(.cloze))
    }

    // MARK: - 静态集合测试

    @Test("objectiveTypes 包含正确题型")
    func objectiveTypesCollection() {
        #expect(ReviewItemType.objectiveTypes.count == 5)
        #expect(ReviewItemType.objectiveTypes.contains(.choice))
        #expect(ReviewItemType.objectiveTypes.contains(.multiChoice))
    }

    @Test("subjectiveTypes 包含正确题型")
    func subjectiveTypesCollection() {
        #expect(ReviewItemType.subjectiveTypes.count == 6)
        #expect(ReviewItemType.subjectiveTypes.contains(.calculation))
        #expect(ReviewItemType.subjectiveTypes.contains(.proof))
    }

    @Test("comprehensiveTypes 包含正确题型")
    func comprehensiveTypesCollection() {
        #expect(ReviewItemType.comprehensiveTypes.count == 3)
        #expect(ReviewItemType.comprehensiveTypes.contains(.reading))
        #expect(ReviewItemType.comprehensiveTypes.contains(.writing))
    }

    @Test("sortedByTime 正确排序")
    func sortedByTimeOrder() {
        let sorted = ReviewItemType.sortedByTime

        for i in 1..<sorted.count {
            #expect(sorted[i-1].estimatedMinutes <= sorted[i].estimatedMinutes)
        }
    }

    @Test("sortedByDifficulty 正确排序")
    func sortedByDifficultyOrder() {
        let sorted = ReviewItemType.sortedByDifficulty

        for i in 1..<sorted.count {
            #expect(sorted[i-1].difficultyWeight <= sorted[i].difficultyWeight)
        }
    }

    // MARK: - Codable 测试

    @Test("Codable 正确编解码")
    func codableRoundTrip() throws {
        let original = ReviewItemType.calculation

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(ReviewItemType.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - 分类显示属性测试

    @Test("ReviewItemCategory 都有显示名称")
    func categoryDisplayNames() {
        for category in ReviewItemCategory.allCases {
            #expect(!category.displayName.isEmpty)
        }
    }

    @Test("ReviewItemCategory 都有评分特点描述")
    func categoryGradingCharacteristics() {
        for category in ReviewItemCategory.allCases {
            #expect(!category.gradingCharacteristic.isEmpty)
        }
    }
}
