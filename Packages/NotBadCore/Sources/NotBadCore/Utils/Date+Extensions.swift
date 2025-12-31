//
//  Date+Extensions.swift
//  NotBadUtils
//
//  Created by NotBad Architect.
//

import Foundation

public extension Date {
    /// 转换为 ISO8601 字符串 (YYYY-MM-DD)
    var iso8601DateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
    
    /// 相对时间描述（中文）
    /// 例如：“今天”，“2天后”
    func relativeDescription(relativeTo other: Date = Date()) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return "今天"
        } else if calendar.isDateInTomorrow(self) {
            return "明天"
        } else if calendar.isDateInYesterday(self) {
            return "昨天"
        }
        
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: other), to: calendar.startOfDay(for: self))
        if let days = components.day {
            if days > 0 {
                return "\(days)天后"
            } else {
                return "\(abs(days))天前"
            }
        }
        return self.iso8601DateString
    }
}
