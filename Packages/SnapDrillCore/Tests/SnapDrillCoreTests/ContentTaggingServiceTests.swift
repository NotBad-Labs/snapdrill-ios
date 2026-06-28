//
//  ContentTaggingServiceTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
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
        let suggestion = ContentTagSuggestion(category: "数学")
        #expect(suggestion.category == "数学")
    }

    @Test("ContentTagSuggestion Equatable 正确比较")
    func suggestionEquatable() {
        let a = ContentTagSuggestion(category: "英语")
        let b = ContentTagSuggestion(category: "英语")
        let c = ContentTagSuggestion(category: "数学")
        #expect(a == b)
        #expect(a != c)
    }

    // MARK: - Mock 行为验证

    @Test("Mock 返回配置的结果")
    func mockReturnsConfiguredResult() async {
        let mock = ContentTaggingServiceMock()
        mock.suggestResult = ContentTagSuggestion(category: "物理")

        let result = await mock.suggestTags(for: "计算物体的加速度")
        #expect(result?.category == "物理")
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

    // MARK: - 生产实现确定性守卫（审计 #9：原测试只覆盖 Mock，不触发生产 suggestTags）

    @Test("生产 suggestTags：空白文本走输入守卫直接返回 nil，不触发 FoundationModels 可用性检查")
    func production_blankText_returnsNilWithoutModelCheck() async {
        let service = ContentTaggingService()
        // 空文本守卫位于 SystemLanguageModel.isAvailable 检查之前，
        // 故此路径快速且确定，不触发 Simulator 上 ~150s 的可用性检查。
        #expect(await service.suggestTags(for: "") == nil)
        #expect(await service.suggestTags(for: "   \n\t  ") == nil)
    }

    // 生产实现的 AI 推断路径（非空文本）依赖 FoundationModels：
    // SystemLanguageModel.default.isAvailable 在 Simulator 上检查耗时 ~150s，
    // 故 CI 不调用该路径，仅由真机手动测试覆盖。空文本守卫路径已由上方测试守护。
}
