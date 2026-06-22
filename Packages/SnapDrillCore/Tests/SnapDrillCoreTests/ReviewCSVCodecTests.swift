//
//  ReviewCSVCodecTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  题库 CSV 导出契约的回归守护：列 schema + 转义 + Excel 公式注入防护。
//  此前 DataExporter / ReviewExport 各写一份且零 oracle；收口到 ReviewCSVCodec 后由本测试守缝。
//

import Testing
import Foundation
@testable import SnapDrillCore

struct ReviewCSVCodecTests {

    /// 测试替身：遵守 CSV 行契约的最小 Sendable 值类型。
    private nonisolated struct Row: ReviewCSVRow {
        let id: UUID
        let content: String?
        let difficulty: Int
        let answerText: String?
        let createdAt: Date
        let lastReviewedAt: Date?
        let nextReviewAt: Date?
        let dimensionValues: [String: [String]]
    }

    @Test("fixedHeader 是固定列 schema（动态维度列在其后追加）")
    func testFixedHeaderSchema() {
        #expect(ReviewCSVCodec.fixedHeader == "ID,Content,Difficulty,Answer,CreatedAt,LastReviewed,NextReview")
    }

    @Test("普通字段与空串均加引号包裹")
    func testEscapeNormal() {
        #expect(ReviewCSVCodec.escapeField("hello") == "\"hello\"")
        #expect(ReviewCSVCodec.escapeField("") == "\"\"")
    }

    @Test("内部双引号转义为两个双引号")
    func testEscapeQuotes() {
        #expect(ReviewCSVCodec.escapeField("a\"b") == "\"a\"\"b\"")
    }

    @Test("公式注入字符（= + - @）开头时前置制表符失活")
    func testInjectionGuardPrefixes() {
        for ch in ["=", "+", "-", "@"] {
            #expect(ReviewCSVCodec.escapeField("\(ch)cmd") == "\"\t\(ch)cmd\"", "\(ch) 开头应前置 tab")
        }
    }

    @Test("注入字符出现在非首位不前置制表符")
    func testInjectionGuardOnlyLeading() {
        #expect(ReviewCSVCodec.escapeField("1+1") == "\"1+1\"")
        #expect(ReviewCSVCodec.escapeField("a=b") == "\"a=b\"")
    }

    @Test("makeCSV：固定列居首、动态维度列追加、注入防护与多值 join 正确")
    func testMakeCSVStructure() {
        let id = UUID()
        let row = Row(
            id: id,
            content: "=danger",
            difficulty: 3,
            answerText: nil,
            createdAt: Date(timeIntervalSince1970: 0),
            lastReviewedAt: nil,
            nextReviewAt: nil,
            dimensionValues: ["标签": ["a", "b"], "分类": ["数学"]]
        )
        let csv = ReviewCSVCodec.makeCSV([row])

        // header 居首 = 固定列 + 按列名排序的维度列（分类 < 标签），行尾 \n
        #expect(csv.hasPrefix(ReviewCSVCodec.header(dimensionColumns: ["分类", "标签"]) + "\n"))
        #expect(csv.hasSuffix("\n"))
        // 注入内容被前置 tab 防护
        #expect(csv.contains("\"\t=danger\""))
        // id 与 difficulty 不加引号（裸值）
        #expect(csv.contains(id.uuidString))
        #expect(csv.contains(",3,"))
        // 空 answerText / 空日期 → 编码为空串
        #expect(csv.contains("\"\""))
        // 多值维度以 "; " 连接后整体转义；维度列名进 header
        #expect(csv.contains("\"a; b\""))
        #expect(csv.contains("\"标签\""))
        #expect(csv.contains("\"分类\""))
    }

    @Test("makeCSV：空数组只产出固定列 header 行")
    func testMakeCSVEmpty() {
        let csv = ReviewCSVCodec.makeCSV([Row]())
        #expect(csv == ReviewCSVCodec.fixedHeader + "\n")
    }
}
