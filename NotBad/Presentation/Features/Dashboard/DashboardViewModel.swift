//
//  DashboardViewModel.swift
//  NotBad
//
//  数据看板 ViewModel
//

import SwiftUI
import SwiftData

/// 数据看板 ViewModel
@MainActor
@Observable
final class DashboardViewModel {
    
    // MARK: - Computed Statistics
    
    func masteredCount(from items: [ReviewItem]) -> Int {
        items.filter { $0.mastery == .mastered }.count
    }
    
    func weeklyNewCount(from items: [ReviewItem]) -> Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return items.filter { $0.createdAt >= weekAgo }.count
    }
    
    func totalReviewCount(from items: [ReviewItem]) -> Int {
        items.reduce(0) { $0 + $1.reviewCount }
    }
    
    func masteryData(from items: [ReviewItem]) -> [MasteryData] {
        MasteryLevel.allCases.compactMap { level in
            let count = items.filter { $0.mastery == level }.count
            guard count > 0 else { return nil }
            return MasteryData(level: level.rawValue, label: level.displayName, color: level.color, count: count)
        }
    }
    
    func subjectData(from items: [ReviewItem]) -> [SubjectData] {
        Dictionary(grouping: items, by: { $0.subject })
            .map { SubjectData(subject: $0.key.displayName, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }
}

// MARK: - Data Models (保持与 DashboardView 兼容)

struct MasteryData {
    let level: Int
    let label: String
    let color: Color
    let count: Int
}

struct SubjectData {
    let subject: String
    let count: Int
}
