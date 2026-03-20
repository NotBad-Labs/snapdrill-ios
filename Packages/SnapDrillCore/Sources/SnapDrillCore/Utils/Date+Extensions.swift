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
    
    /// 相对时间描述（L10n 本地化）
    ///
    /// 保留原始精确天数逻辑，仅将硬编码中文替换为 L10n 键。
    /// 不使用 `RelativeDateTimeFormatter`：它的粒度不适合复习场景
    /// （”今天”变”现在”、7-13天都显示”下周”丢失精度）。
    func relativeDescription(relativeTo other: Date = Date()) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return L10n.Common.today
        } else if calendar.isDateInTomorrow(self) {
            return L10n.Common.tomorrow
        } else if calendar.isDateInYesterday(self) {
            return L10n.Common.yesterday
        }

        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: other), to: calendar.startOfDay(for: self))
        if let days = components.day {
            if days > 0 {
                return L10n.Common.daysLater(days)
            } else {
                return L10n.Common.daysAgo(abs(days))
            }
        }
        return self.iso8601DateString
    }
}
