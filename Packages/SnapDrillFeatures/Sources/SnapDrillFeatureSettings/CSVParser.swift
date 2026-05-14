//
//  CSVParser.swift
//  SnapDrillFeatureSettings
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  RFC 4180 合规的 CSV 解析器（`SettingsViewModel.importCSV` 专用）。
//

import Foundation

/// RFC 4180 合规的 CSV 解析器。
///
/// 从 `SettingsViewModel` 抽出（PR-2 from Codex 3 PR 方案），
/// 原因：
/// 1. 解除 SettingsViewModel 文件长度超 file_length 门（500 行）
/// 2. 纯函数无状态，与 ViewModel 职责分离
/// 3. 便于独立单元测试（未来可直接测 parseCSV 而无需 ViewModel 依赖）
enum CSVParser {

    /// 解析 CSV 文本为字典数组（RFC 4180 合规）
    ///
    /// 单字符状态机扫描全文，正确处理：
    /// - 引号内的逗号、换行（字段内嵌换行不被错误切成多行）
    /// - 双引号转义 `""` → `"`
    /// - CRLF / CR / LF 三种行终止符（预处理归一化为 LF）
    ///
    /// - Parameter csvString: 原始 CSV 文本（首行为列名）
    /// - Returns: 每行一个字典，key 为列名（小写），value 为字段值；至少有 content 或 subject 才算有效行
    static func parse(_ csvString: String) -> [[String: String]] {
        // UTF-8 BOM (U+FEFF) 剥离：Excel 导出 CSV 常带 BOM，不剥会让首列 key 变成
        // "\u{FEFF}content" 导致字段映射异常（Codex PR #695 审查 🔴 指出）
        let stripped = csvString.hasPrefix("\u{FEFF}")
            ? String(csvString.dropFirst())
            : csvString
        let normalized = stripped
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        let rows = tokenizeRows(normalized)
        guard let headerRow = rows.first else { return [] }
        let headers = headerRow.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
        guard !headers.isEmpty else { return [] }

        var results: [[String: String]] = []
        for row in rows.dropFirst() {
            var dict: [String: String] = [:]
            for (index, header) in headers.enumerated() where index < row.count {
                let value = row[index].trimmingCharacters(in: .whitespaces)
                if !value.isEmpty {
                    dict[header] = value
                }
            }
            if dict["content"] != nil || dict["subject"] != nil {
                results.append(dict)
            }
        }
        return results
    }

    /// 将 CSV 文本分割为行的二维字段数组（RFC 4180 状态机）
    ///
    /// 假设输入已完成行终止符归一化（只含 `\n`）。空行（全字段为空）被过滤。
    private static func tokenizeRows(_ csv: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var inQuotes = false
        var index = csv.startIndex

        while index < csv.endIndex {
            let char = csv[index]
            if inQuotes {
                if char == "\"" {
                    let next = csv.index(after: index)
                    if next < csv.endIndex, csv[next] == "\"" {
                        currentField.append("\"")
                        index = csv.index(after: next)
                        continue
                    }
                    inQuotes = false
                } else {
                    currentField.append(char)
                }
            } else {
                if char == "\"" {
                    inQuotes = true
                } else if char == "," {
                    currentRow.append(currentField)
                    currentField = ""
                } else if char == "\n" {
                    currentRow.append(currentField)
                    if !isEmptyRow(currentRow) {
                        rows.append(currentRow)
                    }
                    currentField = ""
                    currentRow = []
                } else {
                    currentField.append(char)
                }
            }
            index = csv.index(after: index)
        }
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            if !isEmptyRow(currentRow) {
                rows.append(currentRow)
            }
        }
        return rows
    }

    private static func isEmptyRow(_ row: [String]) -> Bool {
        row.allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
}
