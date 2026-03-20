//
//  Date+Extensions.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2025/12/30.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Date 扩展，提供常用的日期格式化和计算功能。
//

import Foundation

public extension Date {
    
    // MARK: - Properties
    
    /// 转换为本地时区的日期字符串 (YYYY-MM-DD)
    ///
    /// 使用 static DateFormatter 避免每次调用创建实例（DateFormatter 初始化是重量级操作）。
    /// 不使用 `.formatted(.iso8601)` 是因为 ISO8601 FormatStyle 默认 UTC 时区，
    /// 在 UTC+ 时区（如中国）会导致日期差一天。
    var iso8601DateString: String {
        Self.iso8601Formatter.string(from: self)
    }

    private static let iso8601Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    /// 相对时间描述（系统自动本地化）
    ///
    /// 使用 `RelativeDateTimeFormatter` 系统 API，自动处理多语言。
    /// 例如：中文”今天”/”2天后”，英文”today”/”in 2 days”。
    func relativeDescription(relativeTo other: Date = Date()) -> String {
        // 每次创建 RelativeDateTimeFormatter（轻量级，不像 DateFormatter）
        // 系统自动处理多语言，输出如”今天”/”明天”/”2天后”
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: self, relativeTo: other)
    }
}
