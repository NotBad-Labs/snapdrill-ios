//
//  ReviewCSVCodec.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  题库 CSV 导出的单一契约源：列 schema + 行序 + 转义 + Excel 公式注入防护。
//  此前 DataExporter（Settings）与 ReviewExport（Library）各写一份逐字相同的实现，
//  schema / 注入规则改一处忘另一处会漂移（注入防护漂移 = 安全回归），故收口于此。
//

import Foundation

// 需求显式 `nonisolated`：本类型在全局 `defaultIsolation(MainActor)` 下默认会变 MainActor 隔离，
// 而 `ReviewCSVCodec` 是 nonisolated（供 actor / nonisolated Transferable 复用），故需求须可从
// nonisolated 上下文读取。遵守方（ReviewExportSnapshot / ExportableItem）本就是 nonisolated struct，一致。
/// 可被编码为题库 CSV 一行的只读契约。
///
/// 现有实现：`ReviewExportSnapshot`（Data）/ `ExportableItem`（Settings）。
/// 字段顺序即 CSV 列序，由 `ReviewCSVCodec` 统一编码，遵守方只需提供字段。
public protocol ReviewCSVRow: Sendable {
    /// 题目唯一标识符
    nonisolated var id: UUID { get }
    /// 题目内容文本；纯图片题为 `nil`
    nonisolated var content: String? { get }
    /// 所属学科
    nonisolated var subject: String { get }
    /// 题目来源
    nonisolated var source: String { get }
    /// 难度等级（1-5）
    nonisolated var difficulty: Int { get }
    /// 答案文本；无答案为 `nil`
    nonisolated var answerText: String? { get }
    /// 创建时间
    nonisolated var createdAt: Date { get }
    /// 上次复习时间
    nonisolated var lastReviewedAt: Date? { get }
    /// 下次计划复习时间
    nonisolated var nextReviewAt: Date? { get }
    /// 标签列表
    nonisolated var tags: [String] { get }
}

/// 题库 CSV 导出的单一真理源（列 schema + 行序 + 转义 + 注入防护）。
///
/// 纯字符串逻辑、无副作用，`nonisolated` 以供 actor（`DataExporter`）与
/// nonisolated `Transferable`（`ReviewExport`）两处同步复用。
public enum ReviewCSVCodec {

    /// CSV 表头（列 schema 的唯一定义）。
    public nonisolated static var header: String {
        "ID,Content,Subject,Source,Difficulty,Answer,CreatedAt,LastReviewed,NextReview,Tags"
    }

    /// 将若干行编码为完整 CSV 文本（含表头，每行以 `\n` 结尾）。
    public nonisolated static func makeCSV(_ rows: [some ReviewCSVRow]) -> String {
        var csv = header + "\n"
        for row in rows {
            let cells = [
                row.id.uuidString,
                escapeField(row.content ?? ""),
                escapeField(row.subject),
                escapeField(row.source),
                "\(row.difficulty)",
                escapeField(row.answerText ?? ""),
                row.createdAt.ISO8601Format(),
                row.lastReviewedAt?.ISO8601Format() ?? "",
                row.nextReviewAt?.ISO8601Format() ?? "",
                escapeField(row.tags.joined(separator: "; "))
            ]
            csv += cells.joined(separator: ",") + "\n"
        }
        return csv
    }

    /// CSV 字段转义 + Excel 公式注入防护。
    ///
    /// 首字符为 `=` `+` `-` `@` 时前置制表符使其在表格软件中失活，
    /// 再将内部双引号转义为 `""` 并整体加引号。
    public nonisolated static func escapeField(_ string: String) -> String {
        var value = string
        if let first = value.first, "=+\\-@".contains(first) {
            value = "\t" + value
        }
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
