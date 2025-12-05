//
//  ReviewItem+Accessors.swift
//  NotBad
//
//  值对象访问器扩展
//
//  将 SwiftData 存储的原始值转换为类型安全的值对象。
//  所有 setter 都会自动调用 `markAsUpdated()` 更新时间戳。
//

import Foundation

// MARK: - ReviewItem Value Object Accessors

extension ReviewItem {

    /// 学科
    ///
    /// 从 `subjectRaw` 转换。无效值时 fallback 到 `.other`。
    var subject: Subject {
        get { Subject(rawValue: subjectRaw) ?? .other }
        set {
            subjectRaw = newValue.rawValue
            markAsUpdated()
        }
    }

    /// 年级
    ///
    /// 从 `gradeRaw` 转换。无效值时 fallback 到 `.grade10`（高一）。
    var grade: Grade {
        get { Grade(rawValue: gradeRaw) ?? .grade10 }
        set {
            gradeRaw = newValue.rawValue
            markAsUpdated()
        }
    }

    /// 掌握程度
    ///
    /// 从 `masteryLevel` (Int) 转换。无效值时 fallback 到 `.none`。
    var mastery: MasteryLevel {
        get { MasteryLevel(rawValue: masteryLevel) ?? .none }
        set {
            masteryLevel = newValue.rawValue
            markAsUpdated()
        }
    }

    /// 知识点集合
    ///
    /// 从逗号分隔的 `knowledgePointsRaw` 字符串转换。
    var knowledgePoints: KnowledgePoints {
        get { KnowledgePoints(from: knowledgePointsRaw) }
        set {
            knowledgePointsRaw = newValue.rawValue
            markAsUpdated()
        }
    }

    /// 难度等级
    ///
    /// 从 `difficultyRaw` (Int) 转换。无效值时 fallback 到 `.medium`。
    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .medium }
        set {
            difficultyRaw = newValue.rawValue
            markAsUpdated()
        }
    }

    /// 错误类型
    ///
    /// 从 `errorTypeRaw` 转换。无效值时 fallback 到 `.other`。
    var errorType: ErrorType {
        get { ErrorType(rawValue: errorTypeRaw) ?? .other }
        set {
            errorTypeRaw = newValue.rawValue
            markAsUpdated()
        }
    }

    /// 题目来源
    ///
    /// 从 `sourceRaw` 转换。无效值时 fallback 到 `.other`。
    var source: Source {
        get { Source(rawValue: sourceRaw) ?? .other }
        set {
            sourceRaw = newValue.rawValue
            markAsUpdated()
        }
    }

    /// 题型
    ///
    /// 从 `reviewItemTypeRaw` 转换。无效值时 fallback 到 `.other`。
    var reviewItemType: ReviewItemType {
        get { ReviewItemType(rawValue: reviewItemTypeRaw) ?? .other }
        set {
            reviewItemTypeRaw = newValue.rawValue
            markAsUpdated()
        }
    }
}
