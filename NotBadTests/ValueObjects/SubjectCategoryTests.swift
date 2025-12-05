//
//  SubjectCategoryTests.swift
//  NotBadTests
//
//  学科分类值对象单元测试
//

import Testing
import Foundation
@testable import NotBad

@Suite("SubjectCategory 值对象测试")
struct SubjectCategoryTests {

    // MARK: - 初始化测试

    @Test("学科分类有5种")
    func categoryCount() {
        #expect(SubjectCategory.allCases.count == 5)
    }

    @Test("所有分类都有显示名称")
    func allCategoriesHaveDisplayNames() {
        for category in SubjectCategory.allCases {
            #expect(!category.displayName.isEmpty)
        }
    }

    // MARK: - 枚举值测试

    @Test("分类包含语言、理科、人文、技术、其他")
    func categoryValues() {
        #expect(SubjectCategory.language.rawValue == "language")
        #expect(SubjectCategory.science.rawValue == "science")
        #expect(SubjectCategory.humanities.rawValue == "humanities")
        #expect(SubjectCategory.technology.rawValue == "technology")
        #expect(SubjectCategory.other.rawValue == "other")
    }

    // MARK: - 显示属性测试

    @Test("shortLabel 简短有意义")
    func shortLabelNotEmpty() {
        for category in SubjectCategory.allCases {
            #expect(!category.shortLabel.isEmpty)
        }
    }

    @Test("所有分类都有图标")
    func allCategoriesHaveIcons() {
        for category in SubjectCategory.allCases {
            #expect(!category.icon.isEmpty)
        }

        #expect(SubjectCategory.language.icon == "textformat")
        #expect(SubjectCategory.science.icon == "flask")
        #expect(SubjectCategory.humanities.icon == "book")
        #expect(SubjectCategory.technology.icon == "desktopcomputer")
        #expect(SubjectCategory.other.icon == "ellipsis.circle")
    }

    // Note: color 属性已移至 Presentation/Common/Styles/ValueObjects+UI.swift

    // MARK: - Identifiable 测试

    @Test("id 使用 rawValue")
    func idEqualsRawValue() {
        for category in SubjectCategory.allCases {
            #expect(category.id == category.rawValue)
        }
    }

    // MARK: - Codable 测试

    @Test("可以编解码")
    func codable() throws {
        let original = SubjectCategory.science
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SubjectCategory.self, from: encoded)
        #expect(original == decoded)
    }

    // MARK: - Hashable 测试

    @Test("可用于 Set 和 Dictionary")
    func hashable() {
        let set: Set<SubjectCategory> = [.language, .science, .humanities, .language]
        #expect(set.count == 3)
    }
}
