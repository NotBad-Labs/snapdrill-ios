//
//  TimeRange.swift
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
    case invalidTimeRange(String) // 无效的时间范围

    var description: String {
        switch self {
        case .invalidTimeRange(let reason):
            return "时间范围无效: \(reason)。"
        }
    }

    var errorDescription: String? {
        return description
    }
}


/// 时间范围值对象
/// 封装了一个由开始日期和结束日期定义的时间段。
/// 这是一个不可变的值对象，内部包含自验证逻辑，确保时间范围的有效性。
///
/// 遵循 `Codable`, `Hashable`, `Sendable` 协议，以支持序列化、哈希和并发安全。
struct TimeRange: Codable, Sendable, Hashable {
    let start: Date // 时间范围的开始日期
    let end: Date // 时间范围的结束日期

    /// 初始化 TimeRange
    /// - Parameters:
    ///   - start: 时间范围的开始日期
    ///   - end: 时间范围的结束日期
    /// - Throws: SystemDomainError 如果开始日期晚于或等于结束日期
    init(start: Date, end: Date) throws {
        // 验证：结束日期必须晚于开始日期
        guard end > start else {
            throw SystemDomainError.invalidTimeRange("结束日期必须晚于开始日期。")
        }
        self.start = start
        self.end = end
    }

    /// 计算时间范围的持续时间（秒）
    var duration: TimeInterval {
        return end.timeIntervalSince(start)
    }

    /// 判断一个日期是否在此时间范围内
    /// - Parameter date: 要检查的日期
    /// - Returns: true 如果日期在范围内（包含开始但不包含结束），否则为 false
    func contains(_ date: Date) -> Bool {
        return date >= start && date < end
    }

    /// 判断此时间范围是否与另一个时间范围重叠
    /// - Parameter other: 另一个时间范围
    /// - Returns: true 如果重叠，否则为 false
    func overlaps(with other: TimeRange) -> Bool {
        return self.start < other.end && self.end > other.start
    }

    /// 判断此时间范围是否完全包含另一个时间范围
    /// - Parameter other: 另一个时间范围
    /// - Returns: true 如果完全包含，否则为 false
    func includes(_ other: TimeRange) -> Bool {
        return self.start <= other.start && self.end >= other.end
    }

    /// 获取两个时间范围的交集
    /// - Parameter other: 另一个时间范围
    /// - Returns: 交集的时间范围，如果无交集则为 nil
    func intersection(with other: TimeRange) -> TimeRange? {
        let intersectionStart = max(self.start, other.start)
        let intersectionEnd = min(self.end, other.end)

        guard intersectionStart < intersectionEnd else {
            return nil // 无交集
        }

        return try? TimeRange(start: intersectionStart, end: intersectionEnd)
    }
}

// MARK: - CustomStringConvertible (用于调试和日志)
extension TimeRange: CustomStringConvertible {
    var description: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return "从 \(formatter.string(from: start)) 到 \(formatter.string(from: end))"
    }
}

// MARK: - Sample Data for Testing
extension TimeRange {
    static func today() -> TimeRange {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        return try! TimeRange(start: startOfDay, end: endOfDay)
    }

    static func nextHour() -> TimeRange {
        let now = Date()
        let oneHourLater = now.addingTimeInterval(3600)
        return try! TimeRange(start: now, end: oneHourLater)
    }

    static func pastWeek() -> TimeRange {
        let now = Date()
        let oneWeekAgo = now.addingTimeInterval(-7 * 24 * 3600)
        return try! TimeRange(start: oneWeekAgo, end: now)
    }

    static func invalidSample() -> TimeRange {
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        return try! TimeRange(start: now, end: oneHourAgo) // 这是一个无效的时间范围，用于测试错误处理
    }
}

