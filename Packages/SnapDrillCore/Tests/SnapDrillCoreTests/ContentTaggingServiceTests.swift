//
//  ContentTaggingServiceTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs on 2026/04/16.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  ContentTaggingService Mock 行为与 ContentTagSuggestion 值类型测试。
//  生产实现依赖 FoundationModels（需 Apple Intelligence 设备），
//  因此测试通过 Mock 验证协议契约和消费方集成。
//

import Testing
import Foundation
@testable import SnapDrillCore

@Suite("ContentTaggingService 测试")
struct ContentTaggingServiceTests {

    // MARK: - ContentTagSuggestion 值类型

    @Test("ContentTagSuggestion 初始化正确")
    func suggestionInit() {
        let suggestion = ContentTagSuggestion(subject: "数学", difficulty: 3)
        #expect(suggestion.subject == "数学")
        #expect(suggestion.difficulty == 3)
    }

    @Test("ContentTagSuggestion Equatable 正确比较")
    func suggestionEquatable() {
        let a = ContentTagSuggestion(subject: "英语", difficulty: 2)
        let b = ContentTagSuggestion(subject: "英语", difficulty: 2)
        let c = ContentTagSuggestion(subject: "数学", difficulty: 2)
        #expect(a == b)
        #expect(a != c)
    }

    // MARK: - Mock 行为验证

    @Test("Mock 返回配置的结果")
    func mockReturnsConfiguredResult() async {
        let mock = ContentTaggingServiceMock()
        mock.suggestResult = ContentTagSuggestion(subject: "物理", difficulty: 4)

        let result = await mock.suggestTags(for: "计算物体的加速度")
        #expect(result?.subject == "物理")
        #expect(result?.difficulty == 4)
        #expect(mock.suggestCallCount == 1)
    }

    @Test("Mock 默认返回 nil")
    func mockDefaultNil() async {
        let mock = ContentTaggingServiceMock()
        let result = await mock.suggestTags(for: "任意文本")
        #expect(result == nil)
        #expect(mock.suggestCallCount == 1)
    }

    @Test("Mock 多次调用递增 callCount")
    func mockCallCount() async {
        let mock = ContentTaggingServiceMock()
        _ = await mock.suggestTags(for: "a")
        _ = await mock.suggestTags(for: "b")
        _ = await mock.suggestTags(for: "c")
        #expect(mock.suggestCallCount == 3)
    }

    // 生产实现依赖 FoundationModels（SystemLanguageModel.default.isAvailable 在
    // Simulator 上检查耗时 ~150s），因此不在 CI 测试中调用 ContentTaggingService。
    // 真机验证通过手动测试覆盖。
}
