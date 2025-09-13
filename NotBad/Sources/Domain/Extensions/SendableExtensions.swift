//
//  SendableExtensions.swift
//  NotBad
//
//  Created by Swift 6 Upgrade Script on 2025/9/13.
//

import Foundation

// MARK: - Sendable协议扩展
// 为Swift 6并发安全提供Sendable协议支持

extension ReviewItem: Sendable {}
extension ReviewContent: Sendable {}
extension ReviewMetadata: Sendable {}
extension StudyRecord: Sendable {}
extension MasteryLevel: Sendable {}
extension DifficultyLevel: Sendable {}
extension ParentShareStatus: Sendable {}
extension ItemSource: Sendable {}

// MARK: - 日期范围结构体
struct DateRange: Sendable {
    let startDate: Date
    let endDate: Date
    
    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
}

// MARK: - 统计信息结构体
struct ReviewItemStatistics: Sendable {
    let totalCount: Int
    let masteryLevelCounts: [MasteryLevel: Int]
    let difficultyLevelCounts: [DifficultyLevel: Int]
    let subjectCounts: [String: Int]
}
