//
//  SourceCategoryTests.swift
//  NotBadTests
//
//  来源分类值对象单元测试
//

import Testing
import Foundation
import SwiftUI
@testable import NotBad

@Suite("SourceCategory 值对象测试")
struct SourceCategoryTests {

    // MARK: - 初始化测试

    @Test("来源分类有4种")
    func categoryCount() {
        #expect(SourceCategory.allCases.count == 4)
    }

    @Test("所有分类都有显示名称")
    func allCategoriesHaveDisplayNames() {
        for category in SourceCategory.allCases {
            #expect(!category.displayName.isEmpty)
        }
    }

    // MARK: - 枚举值测试

    @Test("分类包含官方、学校、课外、其他")
    func categoryValues() {
        #expect(SourceCategory.official.rawValue == "官方")
        #expect(SourceCategory.school.rawValue == "学校")
        #expect(SourceCategory.extra.rawValue == "课外")
        #expect(SourceCategory.other.rawValue == "其他")
    }

    // MARK: - 显示属性测试

    @Test("shortLabel 简短有意义")
    func shortLabelNotEmpty() {
        for category in SourceCategory.allCases {
            #expect(!category.shortLabel.isEmpty)
        }
    }

    @Test("所有分类都有图标")
    func allCategoriesHaveIcons() {
        for category in SourceCategory.allCases {
            #expect(!category.icon.isEmpty)
        }

        #expect(SourceCategory.official.icon == "building.columns")
        #expect(SourceCategory.school.icon == "graduationcap")
        #expect(SourceCategory.extra.icon == "books.vertical")
        #expect(SourceCategory.other.icon == "ellipsis.circle")
    }

    @Test("所有分类都有颜色")
    func allCategoriesHaveColors() {
        #expect(SourceCategory.official.color == .red)
        #expect(SourceCategory.school.color == .blue)
        #expect(SourceCategory.extra.color == .orange)
        #expect(SourceCategory.other.color == .gray)
    }

    @Test("所有分类都有分类描述")
    func allCategoriesHaveCategoryDescription() {
        for category in SourceCategory.allCases {
            #expect(!category.categoryDescription.isEmpty)
        }
    }

    // MARK: - Identifiable 测试

    @Test("id 使用 rawValue")
    func idEqualsRawValue() {
        for category in SourceCategory.allCases {
            #expect(category.id == category.rawValue)
        }
    }

    // MARK: - Codable 测试

    @Test("可以编解码")
    func codable() throws {
        let original = SourceCategory.official
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SourceCategory.self, from: encoded)
        #expect(original == decoded)
    }

    // MARK: - Hashable 测试

    @Test("可用于 Set 和 Dictionary")
    func hashable() {
        let set: Set<SourceCategory> = [.official, .school, .extra, .official]
        #expect(set.count == 3)
    }
}
