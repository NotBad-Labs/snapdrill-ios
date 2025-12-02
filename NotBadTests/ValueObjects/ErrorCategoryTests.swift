//
//  ErrorCategoryTests.swift
//  NotBadTests
//
//  错误分类值对象单元测试
//

import Testing
import Foundation
import SwiftUI
@testable import NotBad

@Suite("ErrorCategory 值对象测试")
struct ErrorCategoryTests {

    // MARK: - 初始化测试

    @Test("错误分类有5种")
    func errorCategoryCount() {
        #expect(ErrorCategory.allCases.count == 5)
    }

    @Test("所有分类都有显示名称")
    func allCategoriesHaveDisplayNames() {
        for category in ErrorCategory.allCases {
            #expect(!category.displayName.isEmpty)
        }
    }

    // MARK: - 枚举值测试

    @Test("分类包含知识、方法、习惯、客观、其他")
    func categoryValues() {
        #expect(ErrorCategory.knowledge.rawValue == "知识类")
        #expect(ErrorCategory.method.rawValue == "方法类")
        #expect(ErrorCategory.habit.rawValue == "习惯类")
        #expect(ErrorCategory.objective.rawValue == "客观类")
        #expect(ErrorCategory.other.rawValue == "其他")
    }

    // MARK: - 显示属性测试

    @Test("shortLabel 简短有意义")
    func shortLabelNotEmpty() {
        for category in ErrorCategory.allCases {
            #expect(!category.shortLabel.isEmpty)
        }
    }

    @Test("所有分类都有图标")
    func allCategoriesHaveIcons() {
        for category in ErrorCategory.allCases {
            #expect(!category.icon.isEmpty)
        }

        #expect(ErrorCategory.knowledge.icon == "brain")
        #expect(ErrorCategory.method.icon == "arrow.triangle.branch")
        #expect(ErrorCategory.habit.icon == "hand.raised")
        #expect(ErrorCategory.objective.icon == "clock")
        #expect(ErrorCategory.other.icon == "ellipsis.circle")
    }

    @Test("所有分类都有颜色")
    func allCategoriesHaveColors() {
        #expect(ErrorCategory.knowledge.color == .purple)
        #expect(ErrorCategory.method.color == .red)
        #expect(ErrorCategory.habit.color == .orange)
        #expect(ErrorCategory.objective.color == .gray)
        #expect(ErrorCategory.other.color == .secondary)
    }

    @Test("所有分类都有改进方向建议")
    func allCategoriesHaveImprovementDirection() {
        for category in ErrorCategory.allCases {
            #expect(!category.improvementDirection.isEmpty)
        }
    }

    // MARK: - Identifiable 测试

    @Test("id 使用 rawValue")
    func idEqualsRawValue() {
        for category in ErrorCategory.allCases {
            #expect(category.id == category.rawValue)
        }
    }

    // MARK: - Codable 测试

    @Test("可以编解码")
    func codable() throws {
        let original = ErrorCategory.knowledge
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ErrorCategory.self, from: encoded)
        #expect(original == decoded)
    }

    // MARK: - Hashable 测试

    @Test("可用于 Set 和 Dictionary")
    func hashable() {
        let set: Set<ErrorCategory> = [.knowledge, .method, .habit, .knowledge]
        #expect(set.count == 3)
    }
}
