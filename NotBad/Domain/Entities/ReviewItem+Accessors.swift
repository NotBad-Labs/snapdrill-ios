//
//  ReviewItem+Accessors.swift
//  NotBad
//
//  值对象访问器扩展
//

import Foundation

// MARK: - ReviewItem Value Object Accessors

extension ReviewItem {

    /// 学科
    var subject: Subject {
        get { Subject(rawValue: subjectRaw) ?? .other }
        set {
            subjectRaw = newValue.rawValue
            markAsUpdated()
        }
    }

    /// 年级
    var grade: Grade {
        get { Grade(rawValue: gradeRaw) ?? .grade10 }
        set {
            gradeRaw = newValue.rawValue
            markAsUpdated()
        }
    }

    /// 掌握程度
    var mastery: MasteryLevel {
        get { MasteryLevel(rawValue: masteryLevel) ?? .none }
        set {
            masteryLevel = newValue.rawValue
            markAsUpdated()
        }
    }

    /// 知识点
    var knowledgePoints: KnowledgePoints {
        get { KnowledgePoints(from: knowledgePointsRaw) }
        set {
            knowledgePointsRaw = newValue.rawValue
            markAsUpdated()
        }
    }

    /// 难度等级
    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .medium }
        set {
            difficultyRaw = newValue.rawValue
            markAsUpdated()
        }
    }

    /// 错误类型
    var errorType: ErrorType {
        get { ErrorType(rawValue: errorTypeRaw) ?? .other }
        set {
            errorTypeRaw = newValue.rawValue
            markAsUpdated()
        }
    }

    /// 题目来源
    var source: Source {
        get { Source(rawValue: sourceRaw) ?? .other }
        set {
            sourceRaw = newValue.rawValue
            markAsUpdated()
        }
    }

    /// 题型
    var reviewItemType: ReviewItemType {
        get { ReviewItemType(rawValue: reviewItemTypeRaw) ?? .other }
        set {
            reviewItemTypeRaw = newValue.rawValue
            markAsUpdated()
        }
    }
}
