//
//  ErrorTypeTests.swift
//  NotBadTests
//
//  错误类型值对象单元测试
//

import Testing
import Foundation
@testable import NotBad

@Suite("ErrorType 值对象测试")
struct ErrorTypeTests {

    // MARK: - 基础测试

    @Test("ErrorType 有10种类型")
    func errorTypeCount() {
        #expect(ErrorType.allCases.count == 10)
    }

    @Test("所有类型都有显示名称")
    func allTypesHaveDisplayNames() {
        for type in ErrorType.allCases {
            #expect(!type.displayName.isEmpty)
        }
    }

    @Test("所有类型都有简短标签")
    func allTypesHaveShortLabels() {
        for type in ErrorType.allCases {
            #expect(!type.shortLabel.isEmpty)
            #expect(type.shortLabel.count <= 2)
        }
    }

    @Test("所有类型都有图标")
    func allTypesHaveIcons() {
        for type in ErrorType.allCases {
            #expect(!type.icon.isEmpty)
        }
    }

    // MARK: - 分类测试

    @Test("ErrorCategory 有5种分类")
    func categoryCount() {
        #expect(ErrorCategory.allCases.count == 5)
    }

    @Test("知识类错误归类正确")
    func knowledgeTypesCategory() {
        #expect(ErrorType.concept.category == .knowledge)
        #expect(ErrorType.forgotten.category == .knowledge)
    }

    @Test("方法类错误归类正确")
    func methodTypesCategory() {
        #expect(ErrorType.method.category == .method)
        #expect(ErrorType.wrongDirection.category == .method)
    }

    @Test("习惯类错误归类正确")
    func habitTypesCategory() {
        #expect(ErrorType.calculation.category == .habit)
        #expect(ErrorType.careless.category == .habit)
        #expect(ErrorType.misread.category == .habit)
        #expect(ErrorType.incomplete.category == .habit)
    }

    @Test("客观类错误归类正确")
    func objectiveTypesCategory() {
        #expect(ErrorType.timeLimit.category == .objective)
    }

    @Test("types(in:) 返回正确数量")
    func typesInCategory() {
        #expect(ErrorType.types(in: .knowledge).count == 2)
        #expect(ErrorType.types(in: .method).count == 2)
        #expect(ErrorType.types(in: .habit).count == 4)
        #expect(ErrorType.types(in: .objective).count == 1)
        #expect(ErrorType.types(in: .other).count == 1)
    }

    // MARK: - 改进建议测试

    @Test("所有类型都有改进建议")
    func allTypesHaveSuggestions() {
        for type in ErrorType.allCases {
            #expect(!type.suggestion.isEmpty)
        }
    }

    @Test("所有分类都有改进方向")
    func allCategoriesHaveImprovementDirection() {
        for category in ErrorCategory.allCases {
            #expect(!category.improvementDirection.isEmpty)
        }
    }

    // MARK: - 可控性测试

    @Test("isControllable 正确判断")
    func controllableProperty() {
        // 可控错误
        #expect(ErrorType.concept.isControllable == true)
        #expect(ErrorType.calculation.isControllable == true)

        // 不可控错误
        #expect(ErrorType.timeLimit.isControllable == false)
        #expect(ErrorType.other.isControllable == false)
    }

    @Test("controllableTypes 不包含不可控类型")
    func controllableTypesCollection() {
        let controllable = ErrorType.controllableTypes

        #expect(!controllable.contains(.timeLimit))
        #expect(!controllable.contains(.other))
        #expect(controllable.contains(.concept))
    }

    // MARK: - 严重程度测试

    @Test("severity 在1-5范围内")
    func severityRange() {
        for type in ErrorType.allCases {
            #expect(type.severity >= 1)
            #expect(type.severity <= 5)
        }
    }

    @Test("概念和方法错误严重程度最高")
    func conceptAndMethodHighestSeverity() {
        #expect(ErrorType.concept.severity == 5)
        #expect(ErrorType.method.severity == 5)
    }

    @Test("sortedBySeverity 正确排序")
    func sortedBySeverityOrder() {
        let sorted = ErrorType.sortedBySeverity

        for i in 1..<sorted.count {
            #expect(sorted[i-1].severity >= sorted[i].severity)
        }
    }

    // MARK: - Comparable 测试

    @Test("Comparable 按严重程度排序")
    func comparableBySeverity() {
        #expect(ErrorType.other < ErrorType.concept)
        #expect(ErrorType.careless < ErrorType.method)
    }

    // MARK: - 静态集合测试

    @Test("commonTypes 不包含其他")
    func commonTypesExcludesOther() {
        #expect(!ErrorType.commonTypes.contains(.other))
    }

    @Test("knowledgeTypes 包含正确类型")
    func knowledgeTypesCollection() {
        #expect(ErrorType.knowledgeTypes.contains(.concept))
        #expect(ErrorType.knowledgeTypes.contains(.forgotten))
        #expect(ErrorType.knowledgeTypes.count == 2)
    }

    @Test("methodTypes 包含正确类型")
    func methodTypesCollection() {
        #expect(ErrorType.methodTypes.contains(.method))
        #expect(ErrorType.methodTypes.contains(.wrongDirection))
        #expect(ErrorType.methodTypes.count == 2)
    }

    @Test("habitTypes 包含正确类型")
    func habitTypesCollection() {
        #expect(ErrorType.habitTypes.count == 4)
        #expect(ErrorType.habitTypes.contains(.calculation))
        #expect(ErrorType.habitTypes.contains(.careless))
    }

    // MARK: - Codable 测试

    @Test("Codable 正确编解码")
    func codableRoundTrip() throws {
        let original = ErrorType.calculation

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(ErrorType.self, from: data)

        #expect(decoded == original)
    }

    // MARK: - 描述测试

    @Test("description 等于 displayName")
    func descriptionEqualsDisplayName() {
        for type in ErrorType.allCases {
            #expect(type.description == type.displayName)
        }
    }
}
