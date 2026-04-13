//
//  SettingsViewModel+CSVParser.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/04/13.
//

import Foundation

/// 解析 CSV 文本为字典数组（key 为小写列名）。
func parseCSVRows(_ csvString: String) -> [[String: String]] {
    let lines = csvString.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    guard lines.count >= 2 else { return [] }

    let headers = parseCSVLine(lines[0]).map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
    guard !headers.isEmpty else { return [] }

    var results: [[String: String]] = []
    for lineIndex in 1..<lines.count {
        let values = parseCSVLine(lines[lineIndex])
        var row: [String: String] = [:]
        for (index, header) in headers.enumerated() where index < values.count {
            let value = values[index].trimmingCharacters(in: .whitespaces)
            if !value.isEmpty {
                row[header] = value
            }
        }
        // 至少有 content 或 subject 才算有效行
        if row["content"] != nil || row["subject"] != nil {
            results.append(row)
        }
    }
    return results
}

/// 解析单行 CSV（RFC 4180：支持转义双引号 "" 和带引号字段）。
private func parseCSVLine(_ line: String) -> [String] {
    var fields: [String] = []
    var current = ""
    var inQuotes = false
    var index = line.startIndex

    while index < line.endIndex {
        let char = line[index]
        if inQuotes {
            if char == "\"" {
                let next = line.index(after: index)
                if next < line.endIndex, line[next] == "\"" {
                    current.append("\"")
                    index = line.index(after: next)
                    continue
                } else {
                    inQuotes = false
                }
            } else {
                current.append(char)
            }
        } else {
            if char == "\"" {
                inQuotes = true
            } else if char == "," {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        index = line.index(after: index)
    }
    fields.append(current)
    return fields
}
