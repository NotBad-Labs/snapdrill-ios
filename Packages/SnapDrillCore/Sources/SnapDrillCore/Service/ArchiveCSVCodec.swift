//
//  ArchiveCSVCodec.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  资料库 CSV 导出的单一契约源：列 schema + 行序 + 转义 + Excel 公式注入防护。
//

import Foundation

// 需求显式 `nonisolated`：本类型在全局 `defaultIsolation(MainActor)` 下默认会变 MainActor 隔离，
// 而 `ArchiveCSVCodec` 是 nonisolated（供 actor / nonisolated Transferable 复用），故需求须可从
// nonisolated 上下文读取。遵守方（ArchiveExportSnapshot / ExportableItem）本就是 nonisolated struct，一致。
/// 可被编码为资料库 CSV 一行的只读契约。
///
/// 现有实现：`ArchiveExportSnapshot`（Data）/ `ExportableItem`（Settings）。
/// 字段顺序即 CSV 列序，由 `ArchiveCSVCodec` 统一编码，遵守方只需提供字段。
public protocol ArchiveCSVRow: Sendable {
    /// 资料唯一标识符
    nonisolated var id: UUID { get }
    /// 资料内容文本；纯图片资料为 `nil`
    nonisolated var content: String? { get }
    /// 答案文本；无答案为 `nil`
    nonisolated var answerText: String? { get }
    /// 创建时间
    nonisolated var createdAt: Date { get }
    /// 动态维度值：维度名 → 该资料在该维度下的值名
    nonisolated var dimensionValues: [String: [String]] { get }
}

/// 资料库 CSV 导出的单一真理源（列 schema + 行序 + 转义 + 注入防护）。
///
/// 纯字符串逻辑、无副作用，`nonisolated` 以供 actor（`DataExporter`）与
/// nonisolated `Transferable` 两处同步复用。
public enum ArchiveCSVCodec {

    /// 固定列表头（动态维度列在其后按列名追加；维度列名因用户可改/可删，故 header 非定值）。
    public nonisolated static var fixedHeader: String {
        "ID,Content,Answer,CreatedAt"
    }

    /// 给定动态维度列名时的完整表头（固定列 + 各维度列；维度列名也走 escape 防注入）。
    public nonisolated static func header(dimensionColumns: [String]) -> String {
        var head = fixedHeader
        for column in dimensionColumns { head += "," + escapeField(column) }
        return head
    }

    /// 将若干行编码为完整 CSV 文本（含表头，每行以 `\n` 结尾）。
    /// 动态维度列 = 所有行 `dimensionValues` 键的并集，按列名排序（确定性、自包含，无需外部传维度表）。
    public nonisolated static func makeCSV(_ rows: [some ArchiveCSVRow]) -> String {
        let dimensionColumns = Set(rows.flatMap { $0.dimensionValues.keys }).sorted()
        var csv = header(dimensionColumns: dimensionColumns) + "\n"
        for row in rows {
            var cells = [
                row.id.uuidString,
                escapeField(row.content ?? ""),
                escapeField(row.answerText ?? ""),
                row.createdAt.ISO8601Format()
            ]
            for column in dimensionColumns {
                cells.append(escapeField((row.dimensionValues[column] ?? []).joined(separator: "; ")))
            }
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
        if let first = value.first, "=+-@".contains(first) {
            value = "\t" + value
        }
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
