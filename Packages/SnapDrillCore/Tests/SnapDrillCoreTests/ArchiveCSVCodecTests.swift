//
//  ArchiveCSVCodecTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  资料库 CSV 导出契约的回归守护：列 schema + 转义 + Excel 公式注入防护。
//

import Testing
import Foundation
@testable import SnapDrillCore

struct ArchiveCSVCodecTests {

    /// 测试替身：遵守 CSV 行契约的最小 Sendable 值类型。
    private nonisolated struct Row: ArchiveCSVRow {
        let id: UUID
        let content: String?
        let answerText: String?
        let createdAt: Date
        let dimensionValues: [String: [String]]
    }

    @Test("fixedHeader 是固定列 schema（动态维度列在其后追加）")
    func testFixedHeaderSchema() {
        #expect(ArchiveCSVCodec.fixedHeader == "ID,Content,Answer,CreatedAt")
    }

    @Test("普通字段与空串均加引号包裹")
    func testEscapeNormal() {
        #expect(ArchiveCSVCodec.escapeField("hello") == "\"hello\"")
        #expect(ArchiveCSVCodec.escapeField("") == "\"\"")
    }

    @Test("内部双引号转义为两个双引号")
    func testEscapeQuotes() {
        #expect(ArchiveCSVCodec.escapeField("a\"b") == "\"a\"\"b\"")
    }

    @Test("公式注入字符（= + - @）开头时前置制表符失活")
    func testInjectionGuardPrefixes() {
        for ch in ["=", "+", "-", "@"] {
            #expect(ArchiveCSVCodec.escapeField("\(ch)cmd") == "\"\t\(ch)cmd\"", "\(ch) 开头应前置 tab")
        }
    }

    @Test("注入字符出现在非首位不前置制表符")
    func testInjectionGuardOnlyLeading() {
        #expect(ArchiveCSVCodec.escapeField("1+1") == "\"1+1\"")
        #expect(ArchiveCSVCodec.escapeField("a=b") == "\"a=b\"")
    }

    @Test("makeCSV：固定列居首、动态维度列追加、注入防护与多值 join 正确")
    func testMakeCSVStructure() {
        let id = UUID()
        let row = Row(
            id: id,
            content: "=danger",
            answerText: nil,
            createdAt: Date(timeIntervalSince1970: 0),
            dimensionValues: ["标签": ["a", "b"], "分类": ["数学"]]
        )
        let csv = ArchiveCSVCodec.makeCSV([row])

        // header 居首 = 固定列 + 按列名排序的维度列（分类 < 标签），行尾 \n
        #expect(csv.hasPrefix(ArchiveCSVCodec.header(dimensionColumns: ["分类", "标签"]) + "\n"))
        #expect(csv.hasSuffix("\n"))
        // 注入内容被前置 tab 防护
        #expect(csv.contains("\"\t=danger\""))
        // id 不加引号（裸值）
        #expect(csv.contains(id.uuidString))
        // 空 answerText 编码为空串；创建时间按 ISO 8601 编码
        #expect(csv.contains("\"\""))
        #expect(csv.contains(row.createdAt.ISO8601Format()))
        // 多值维度以 "; " 连接后整体转义；维度列名进 header
        #expect(csv.contains("\"a; b\""))
        #expect(csv.contains("\"标签\""))
        #expect(csv.contains("\"分类\""))
    }

    @Test("makeCSV：空数组只产出固定列 header 行")
    func testMakeCSVEmpty() {
        let csv = ArchiveCSVCodec.makeCSV([Row]())
        #expect(csv == ArchiveCSVCodec.fixedHeader + "\n")
    }
}
