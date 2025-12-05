//
//  ReviewItemCategoryTests.swift
//  NotBadTests
//
//  题型分类值对象单元测试
//

import Testing
import Foundation
@testable import NotBad

@Suite("ReviewItemCategory 值对象测试")
struct ReviewItemCategoryTests {

    // MARK: - 初始化测试

    @Test("题型分类有4种")
    func categoryCount() {
        #expect(ReviewItemCategory.allCases.count == 4)
    }

    @Test("所有分类都有显示名称")
    func allCategoriesHaveDisplayNames() {
        for category in ReviewItemCategory.allCases {
            #expect(!category.displayName.isEmpty)
        }
    }

    // MARK: - 枚举值测试

    @Test("分类包含客观、主观、综合、其他")
    func categoryValues() {
        #expect(ReviewItemCategory.objective.rawValue == "objective")
        #expect(ReviewItemCategory.subjective.rawValue == "subjective")
        #expect(ReviewItemCategory.comprehensive.rawValue == "comprehensive")
        #expect(ReviewItemCategory.other.rawValue == "other")
    }

    // MARK: - 显示属性测试

    @Test("shortLabel 简短有意义")
    func shortLabelNotEmpty() {
        for category in ReviewItemCategory.allCases {
            #expect(!category.shortLabel.isEmpty)
        }
    }

    @Test("所有分类都有图标")
    func allCategoriesHaveIcons() {
        for category in ReviewItemCategory.allCases {
            #expect(!category.icon.isEmpty)
        }

        #expect(ReviewItemCategory.objective.icon == "checkmark.square")
        #expect(ReviewItemCategory.subjective.icon == "pencil")
        #expect(ReviewItemCategory.comprehensive.icon == "doc.text")
        #expect(ReviewItemCategory.other.icon == "ellipsis.circle")
    }

    // Note: color 属性已移至 Presentation/Common/Styles/ValueObjects+UI.swift

    @Test("所有分类都有评分特点描述")
    func allCategoriesHaveGradingCharacteristic() {
        for category in ReviewItemCategory.allCases {
            #expect(!category.gradingCharacteristic.isEmpty)
        }
    }

    // MARK: - Identifiable 测试

    @Test("id 使用 rawValue")
    func idEqualsRawValue() {
        for category in ReviewItemCategory.allCases {
            #expect(category.id == category.rawValue)
        }
    }

    // MARK: - Codable 测试

    @Test("可以编解码")
    func codable() throws {
        let original = ReviewItemCategory.subjective
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ReviewItemCategory.self, from: encoded)
        #expect(original == decoded)
    }

    // MARK: - Hashable 测试

    @Test("可用于 Set 和 Dictionary")
    func hashable() {
        let set: Set<ReviewItemCategory> = [.objective, .subjective, .comprehensive, .objective]
        #expect(set.count == 3)
    }
}
