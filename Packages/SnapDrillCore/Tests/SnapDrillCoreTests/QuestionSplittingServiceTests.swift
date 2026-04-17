//
//  QuestionSplittingServiceTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs on 2026/04/17.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  QuestionSplittingService Mock 行为与生产实现空文本场景测试。
//  生产实现依赖 FoundationModels（需 Apple Intelligence 设备），
//  完整准确率验证需真机 PoC（Issue #626）。
//

import Testing
import Foundation
@testable import SnapDrillCore

@Suite("QuestionSplittingService 测试")
struct QuestionSplittingServiceTests {

    // MARK: - ExtractedQuestionItem 值类型

    @Test("ExtractedQuestionItem 初始化正确")
    func itemInit() {
        let item = ExtractedQuestionItem(text: "1. 求 1+1", ordinal: 1)
        #expect(item.text == "1. 求 1+1")
        #expect(item.ordinal == 1)
    }

    @Test("ExtractedQuestionItem Equatable 正确比较")
    func itemEquatable() {
        let a = ExtractedQuestionItem(text: "题目", ordinal: 1)
        let b = ExtractedQuestionItem(text: "题目", ordinal: 1)
        let c = ExtractedQuestionItem(text: "题目", ordinal: 2)
        #expect(a == b)
        #expect(a != c)
    }

    // MARK: - Mock 行为

    @Test("Mock 默认返回空数组")
    func mockDefaultEmpty() async {
        let mock = QuestionSplittingServiceMock()
        let result = await mock.split(documentText: "整页文本")
        #expect(result.isEmpty)
        #expect(mock.splitCallCount == 1)
        #expect(mock.lastReceivedText == "整页文本")
    }

    @Test("Mock 返回配置的题目列表")
    func mockReturnsConfiguredQuestions() async {
        let mock = QuestionSplittingServiceMock()
        mock.splitResult = [
            ExtractedQuestionItem(text: "1. 求 1+1", ordinal: 1),
            ExtractedQuestionItem(text: "2. 求 2+2", ordinal: 2)
        ]
        let result = await mock.split(documentText: "整页 OCR 文本 …")
        #expect(result.count == 2)
        #expect(result[0].ordinal == 1)
        #expect(result[1].text == "2. 求 2+2")
        #expect(mock.splitCallCount == 1)
    }

    @Test("Mock 可被重复调用并记录调用次数")
    func mockTracksMultipleCalls() async {
        let mock = QuestionSplittingServiceMock()
        _ = await mock.split(documentText: "a")
        _ = await mock.split(documentText: "b")
        _ = await mock.split(documentText: "c")
        #expect(mock.splitCallCount == 3)
        #expect(mock.lastReceivedText == "c")
    }

    // MARK: - 生产实现（不依赖真机）

    @Test("空文本输入直接返回空数组")
    func productionEmptyText() async {
        let service = QuestionSplittingService()
        let result = await service.split(documentText: "")
        #expect(result.isEmpty)
    }

    @Test("纯空白文本视为空")
    func productionWhitespaceOnly() async {
        let service = QuestionSplittingService()
        let result = await service.split(documentText: "   \n\t  ")
        #expect(result.isEmpty)
    }

    // 注：含真实文本的生产实现需要 iOS 26 真机 + Apple Intelligence。
    // CI 模拟器跳过；真机准确率验证见 Issue #626 PoC 报告。
}
