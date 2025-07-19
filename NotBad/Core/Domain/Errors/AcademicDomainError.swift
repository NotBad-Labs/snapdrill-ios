//
//  AcademicDomainError.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

/// 学术领域错误
/// 定义了所有与学术概念（如分数、年级、学年）相关的业务逻辑错误。
/// 遵循 `DomainError` 协议，以便提供统一的错误描述和本地化支持。
enum AcademicDomainError: DomainError {
    // MARK: - 分数相关错误
    case invalidScoreValue(Double, Double, Double) // 分数无效，包含值、最小值、最大值
    case scoreCalculationFailed(String) // 分数计算失败，包含具体原因

    // MARK: - 年级相关错误
    case invalidGradeValue(Int) // 年级值无效（例如，超出1-12的范围）
    case invalidGradeRange(Int, Int) // 年级范围无效（例如，最小值大于最大值）
    case gradeNotFound(String) // 年级未找到，包含年级名称或描述

    // MARK: - 学年相关错误
    case invalidSchoolYearFormat(String) // 学年格式无效（例如，不是"YYYY-YYYY"）
    case invalidSchoolYearRange(Int, Int) // 学年范围无效（例如，开始年份不比结束年份小一年）
    case schoolYearNotFound(String) // 学年未找到，包含学年字符串

    // MARK: - 课程/教学相关错误
    case invalidCourseName(String) // 课程名称无效
    case courseNotFound(String) // 课程未找到
    case invalidCurriculumStructure(String) // 课程结构无效

    // MARK: - 通用学术错误
    case genericAcademicError(String) // 通用学术错误，包含具体消息

    // MARK: - CustomStringConvertible 协议实现
    /// 提供错误的字符串描述，用于日志或调试。
    var description: String {
        switch self {
        case .invalidScoreValue(let value, let min, let max):
            return "分数 '\(value)' 无效，必须在 \(min) 到 \(max) 之间。"
        case .scoreCalculationFailed(let reason):
            return "分数计算失败: \(reason)。"
        case .invalidGradeValue(let value):
            return "年级 '\(value)' 无效，必须在 1 到 12 之间。"
        case .invalidGradeRange(let min, let max):
            return "年级范围无效，最小值 '\(min)' 不能大于最大值 '\(max)'。"
        case .gradeNotFound(let name):
            return "未找到名为 '\(name)' 的年级。"
        case .invalidSchoolYearFormat(let yearString):
            return "学年格式 '\(yearString)' 无效，应为 'YYYY-YYYY' 形式。"
        case .invalidSchoolYearRange(let start, let end):
            return "学年范围无效，开始年份 '\(start)' 必须小于结束年份 '\(end)'，且两者相差一年。"
        case .schoolYearNotFound(let name):
            return "未找到名为 '\(name)' 的学年。"
        case .invalidCourseName(let name):
            return "课程名称 '\(name)' 无效。"
        case .courseNotFound(let name):
            return "未找到名为 '\(name)' 的课程。"
        case .invalidCurriculumStructure(let reason):
            return "课程结构无效: \(reason)。"
        case .genericAcademicError(let message):
            return "发生通用学术错误: \(message)。"
        }
    }

    // MARK: - LocalizedError 协议实现
    /// 提供错误的本地化描述，用于向用户展示。
    var errorDescription: String? {
        // 在实际应用中，这里会通过本地化字符串表获取对应的本地化消息。
        return description // 暂时直接返回 description
    }
}

// MARK: - 辅助协议 (为了编译，实际应从其他文件导入)
// 这些协议在实际项目中应有自己的文件，这里仅为编译目的提供简化定义。

/// 领域错误基础协议 (简化版)
protocol DomainError: Error, CustomStringConvertible, LocalizedError { }

