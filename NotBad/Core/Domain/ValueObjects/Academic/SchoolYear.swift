//
//  SchoolYear.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainErrors // 包含 AcademicDomainError (或其他通用领域错误)

/// 学术领域错误 (仅为编译目的包含，实际应从 AcademicDomainError.swift 导入)
// Note: In a real project, this would be in its own file: Core/Domain/Errors/AcademicDomainError.swift
enum AcademicDomainError: Error, CustomStringConvertible, LocalizedError {
    case invalidSchoolYearFormat(String) // 学年格式无效
    case invalidSchoolYearRange(Int, Int) // 学年范围无效
    case schoolYearNotFound(String) // 学年未找到

    var description: String {
        switch self {
        case .invalidSchoolYearFormat(let yearString):
            return "学年格式 '\(yearString)' 无效，应为 'YYYY-YYYY' 形式。"
        case .invalidSchoolYearRange(let start, let end):
            return "学年范围无效，开始年份 '\(start)' 必须小于结束年份 '\(end)'，且两者相差一年。"
        case .schoolYearNotFound(let name):
            return "未找到名为 '\(name)' 的学年。"
        }
    }

    var errorDescription: String? {
        return description
    }
}


/// 学年值对象
/// 封装了教育体系中的一个学年，通常表示为“开始年份-结束年份”。
/// 这是一个不可变的值对象，内部包含自验证逻辑，确保学年值的有效性。
///
/// 遵循 `Codable`, `Hashable`, `Sendable` 协议，以支持序列化、哈希和并发安全。
struct SchoolYear: Codable, Sendable, Hashable {
    let startYear: Int // 学年的开始年份
    let endYear: Int // 学年的结束年份

    /// 初始化 SchoolYear
    /// - Parameters:
    ///   - startYear: 学年的开始年份
    ///   - endYear: 学年的结束年份
    /// - Throws: AcademicDomainError 如果学年范围无效
    init(startYear: Int, endYear: Int) throws {
        // 验证：结束年份必须比开始年份大一年
        guard endYear == startYear + 1 else {
            throw AcademicDomainError.invalidSchoolYearRange(startYear, endYear)
        }
        self.startYear = startYear
        self.endYear = endYear
    }

    /// 从字符串初始化 SchoolYear (例如 "2023-2024")
    /// - Parameter yearString: 学年字符串，格式为 "YYYY-YYYY"
    /// - Throws: AcademicDomainError 如果字符串格式无效或学年范围无效
    init(fromString yearString: String) throws {
        let components = yearString.split(separator: "-").map { String($0) }
        guard components.count == 2,
              let start = Int(components[0]),
              let end = Int(components[1]) else {
            throw AcademicDomainError.invalidSchoolYearFormat(yearString)
        }
        try self.init(startYear: start, endYear: end)
    }

    /// 获取学年的字符串表示 (例如 "2023-2024")
    var stringValue: String {
        "\(startYear)-\(endYear)"
    }

    /// 获取下一个学年
    /// - Returns: 下一个学年的值对象
    func next() -> SchoolYear {
        return try! SchoolYear(startYear: startYear + 1, endYear: endYear + 1)
    }

    /// 获取上一个学年
    /// - Returns: 上一个学年的值对象
    func previous() -> SchoolYear {
        return try! SchoolYear(startYear: startYear - 1, endYear: endYear - 1)
    }

    /// 判断当前日期是否属于此学年
    /// - Parameter date: 要检查的日期，默认为当前日期
    /// - Returns: true 如果日期在此学年内，否则为 false
    func contains(date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: date)
        let currentMonth = calendar.component(.month, from: date)

        // 假设学年从9月开始，到次年8月结束
        if currentMonth >= 9 { // 当前月份在9月或之后，属于当前学年的开始年份
            return currentYear == startYear
        } else { // 当前月份在9月之前，属于当前学年的结束年份
            return currentYear == endYear
        }
    }

    /// 获取当前学年
    /// - Returns: 当前学年的值对象
    static func current() -> SchoolYear {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())

        if currentMonth >= 9 { // 如果是9月或之后，学年从当前年份开始
            return try! SchoolYear(startYear: currentYear, endYear: currentYear + 1)
        } else { // 如果是9月之前，学年从去年开始
            return try! SchoolYear(startYear: currentYear - 1, endYear: currentYear)
        }
    }
}

// MARK: - Comparable (使学年可比较大小)
extension SchoolYear: Comparable {
    static func < (lhs: SchoolYear, rhs: SchoolYear) -> Bool {
        return lhs.startYear < rhs.startYear
    }
}

// MARK: - CustomStringConvertible (用于调试和日志)
extension SchoolYear: CustomStringConvertible {
    var description: String {
        stringValue
    }
}

// MARK: - Sample Data for Testing
extension SchoolYear {
    static func sample() -> SchoolYear {
        return try! SchoolYear(startYear: 2023, endYear: 2024)
    }

    static func nextSample() -> SchoolYear {
        return try! SchoolYear(startYear: 2024, endYear: 2025)
    }

    static func previousSample() -> SchoolYear {
        return try! SchoolYear(startYear: 2022, endYear: 2023)
    }

    static func invalidRangeSample() -> SchoolYear {
        return try! SchoolYear(startYear: 2023, endYear: 2023) // 这是一个无效的学年，用于测试错误处理
    }

    static func invalidFormatSample() -> SchoolYear {
        return try! SchoolYear(fromString: "2023/2024") // 这是一个无效的格式，用于测试错误处理
    }
}

