//
//  DatePeriod.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainErrors // 包含 SystemDomainError (或其他通用领域错误)

/// 系统领域错误 (仅为编译目的包含，实际应从 SystemDomainError.swift 导入)
// Note: In a real project, this would be in its own file: Core/Domain/Errors/SystemDomainError.swift
enum SystemDomainError: Error, CustomStringConvertible, LocalizedError {
    case invalidDatePeriod(String) // 无效的日期周期

    var description: String {
        switch self {
        case .invalidDatePeriod(let reason):
            return "日期周期无效: \(reason)。"
        }
    }

    var errorDescription: String? {
        return description
    }
}


/// 日期周期值对象
/// 封装了一个由开始日期和结束日期（包含）定义的日历时间段。
/// 与 `TimeRange` 不同，`DatePeriod` 更侧重于完整的日历天数或更长的周期。
/// 这是一个不可变的值对象，内部包含自验证逻辑，确保日期周期的有效性。
///
/// 遵循 `Codable`, `Hashable`, `Sendable` 协议，以支持序列化、哈希和并发安全。
struct DatePeriod: Codable, Sendable, Hashable {
    let startDate: Date // 日期周期的开始日期（包含）
    let endDate: Date // 日期周期的结束日期（包含）

    /// 初始化 DatePeriod
    /// - Parameters:
    ///   - startDate: 日期周期的开始日期
    ///   - endDate: 日期周期的结束日期
    /// - Throws: SystemDomainError 如果开始日期晚于结束日期
    init(startDate: Date, endDate: Date) throws {
        // 验证：结束日期必须晚于或等于开始日期
        guard endDate >= startDate else {
            throw SystemDomainError.invalidDatePeriod("结束日期必须晚于或等于开始日期。")
        }
        self.startDate = Calendar.current.startOfDay(for: startDate) // 确保是当天的开始
        self.endDate = Calendar.current.startOfDay(for: endDate) // 确保是当天的开始
    }

    /// 计算日期周期的总天数（包含开始和结束日期）
    var numberOfDays: Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: startDate)
        let endOfDay = calendar.startOfDay(for: endDate)
        let components = calendar.dateComponents([.day], from: startOfDay, to: endOfDay)
        return (components.day ?? 0) + 1 // 加1是因为包含开始和结束日期
    }

    /// 判断一个日期是否在此日期周期内（包含开始和结束日期）
    /// - Parameter date: 要检查的日期
    /// - Returns: true 如果日期在范围内，否则为 false
    func contains(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let checkDate = calendar.startOfDay(for: date)
        return checkDate >= startDate && checkDate <= endDate
    }

    /// 判断此日期周期是否与另一个日期周期重叠
    /// - Parameter other: 另一个日期周期
    /// - Returns: true 如果重叠，否则为 false
    func overlaps(with other: DatePeriod) -> Bool {
        return self.startDate <= other.endDate && self.endDate >= other.startDate
    }

    /// 获取两个日期周期的交集
    /// - Parameter other: 另一个日期周期
    /// - Returns: 交集的 DatePeriod，如果无交集则为 nil
    func intersection(with other: DatePeriod) -> DatePeriod? {
        let intersectionStart = max(self.startDate, other.startDate)
        let intersectionEnd = min(self.endDate, other.endDate)

        guard intersectionStart <= intersectionEnd else {
            return nil // 无交集
        }

        return try? DatePeriod(startDate: intersectionStart, endDate: intersectionEnd)
    }

    /// 创建一个表示单天的日期周期
    /// - Parameter date: 指定日期
    /// - Returns: 单天的 DatePeriod
    static func singleDay(_ date: Date) -> DatePeriod {
        return try! DatePeriod(startDate: date, endDate: date)
    }

    /// 创建一个表示一周的日期周期（从指定日期开始的7天）
    /// - Parameter startOfWeek: 周的开始日期
    /// - Returns: 一周的 DatePeriod
    static func week(starting startOfWeek: Date) -> DatePeriod {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startOfWeek)
        let end = calendar.date(byAdding: .day, value: 6, to: start)! // 包含7天
        return try! DatePeriod(startDate: start, endDate: end)
    }

    /// 创建一个表示一个月的日期周期
    /// - Parameter month: 月份的任意日期
    /// - Returns: 一个月的 DatePeriod
    static func month(containing date: Date) -> DatePeriod {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        let startOfMonth = calendar.date(from: components)!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        return try! DatePeriod(startDate: startOfMonth, endDate: endOfMonth)
    }
}

// MARK: - CustomStringConvertible (用于调试和日志)
extension DatePeriod: CustomStringConvertible {
    var description: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none // 只显示日期
        return "从 \(formatter.string(from: startDate)) 到 \(formatter.string(from: endDate))"
    }
}

// MARK: - Sample Data for Testing
extension DatePeriod {
    static func today() -> DatePeriod {
        return try! DatePeriod.singleDay(Date())
    }

    static func thisWeek() -> DatePeriod {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today) // 1 for Sunday, 2 for Monday
        let daysToMonday = (weekday == 1) ? -6 : (2 - weekday) // Adjust to Monday
        let startOfWeek = calendar.date(byAdding: .day, value: daysToMonday, to: today)!
        return try! DatePeriod.week(starting: startOfWeek)
    }

    static func thisMonth() -> DatePeriod {
        return try! DatePeriod.month(containing: Date())
    }

    static func customPeriod() -> DatePeriod {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2024, month: 1, day: 7))!
        return try! DatePeriod(startDate: start, endDate: end)
    }

    static func invalidSample() -> DatePeriod {
        let now = Date()
        let yesterday = now.addingTimeInterval(-24 * 3600)
        return try! DatePeriod(startDate: now, endDate: yesterday) // 这是一个无效的日期周期，用于测试错误处理
    }
}

