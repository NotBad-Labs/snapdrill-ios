//
//  ReviewItemModel.swift
//  NotBad
//
//  ⚠️ 已迁移到 ReviewKit Package
//
//  这个文件已迁移到 Packages/ReviewKit/Sources/ReviewKit/Models/
//  待 Xcode 添加 ReviewKit 依赖后删除此文件。
//
//  迁移步骤：
//  1. 在 Xcode 中，选择 NotBad project
//  2. 点击 "Package Dependencies"
//  3. 添加本地 Package: Packages/ReviewKit
//  4. 在 NotBad target 的 "Frameworks, Libraries..." 中添加 ReviewKit
//  5. 删除此文件和 NotBad/Models/ValueObjects.swift
//  6. 在需要的地方添加 `import ReviewKit`
//

import Foundation
import SwiftData

// MARK: - 临时过渡层（编译兼容）

typealias ReviewItem = ReviewItemModel

@Model
final class ReviewItemModel {

    var id: UUID
    var imagePath: String?
    var title: String
    var note: String
    var createdAt: Date
    var updatedAt: Date
    var masteryLevel: Int
    var nextReviewDate: Date
    var reviewCount: Int
    var subjectRaw: String
    var gradeRaw: String
    var knowledgePointsRaw: String
    var difficultyRaw: Int
    var errorTypeRaw: String
    var sourceRaw: String
    var reviewItemTypeRaw: String
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        imagePath: String? = nil,
        title: String = "",
        note: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        masteryLevel: Int = 0,
        nextReviewDate: Date = Date(),
        reviewCount: Int = 0,
        subjectRaw: String = "math",
        gradeRaw: String = "grade_10",
        knowledgePointsRaw: String = "",
        difficultyRaw: Int = 2,
        errorTypeRaw: String = "other",
        sourceRaw: String = "other",
        reviewItemTypeRaw: String = "other",
        isFavorite: Bool = false
    ) {
        self.id = id
        self.imagePath = imagePath
        self.title = title
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.masteryLevel = masteryLevel
        self.nextReviewDate = nextReviewDate
        self.reviewCount = reviewCount
        self.subjectRaw = subjectRaw
        self.gradeRaw = gradeRaw
        self.knowledgePointsRaw = knowledgePointsRaw
        self.difficultyRaw = difficultyRaw
        self.errorTypeRaw = errorTypeRaw
        self.sourceRaw = sourceRaw
        self.reviewItemTypeRaw = reviewItemTypeRaw
        self.isFavorite = isFavorite
    }
    
    var hasImage: Bool {
        imagePath != nil && !imagePath!.isEmpty
    }
    
    var needsReview: Bool {
        nextReviewDate <= Date()
    }
    
    var isMastered: Bool {
        masteryLevel >= 3
    }
    
    var isOverdue: Bool {
        nextReviewDate < Calendar.current.startOfDay(for: Date())
    }
    
    var knowledgePoints: [String] {
        get {
            knowledgePointsRaw.isEmpty ? [] : knowledgePointsRaw.components(separatedBy: ",")
        }
        set {
            knowledgePointsRaw = newValue.joined(separator: ",")
        }
    }
    
    var displayTitle: String {
        title.isEmpty ? String(localized: "未命名错题") : title
    }
    
    var subject: Subject {
        get { Subject(rawValue: subjectRaw) ?? .other }
        set { subjectRaw = newValue.rawValue }
    }
    
    var grade: Grade {
        get { Grade(rawValue: gradeRaw) ?? .grade10 }
        set { gradeRaw = newValue.rawValue }
    }
    
    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .medium }
        set { difficultyRaw = newValue.rawValue }
    }
    
    var errorType: ErrorType {
        get { ErrorType(rawValue: errorTypeRaw) ?? .other }
        set { errorTypeRaw = newValue.rawValue }
    }
    
    var source: Source {
        get { Source(rawValue: sourceRaw) ?? .other }
        set { sourceRaw = newValue.rawValue }
    }
    
    var reviewItemType: ReviewItemType {
        get { ReviewItemType(rawValue: reviewItemTypeRaw) ?? .other }
        set { reviewItemTypeRaw = newValue.rawValue }
    }
    
    var mastery: MasteryLevel {
        get { MasteryLevel(rawValue: masteryLevel) ?? .none }
        set { masteryLevel = newValue.rawValue }
    }
    
    func recordReview(performance: Int) {
        let clampedPerformance = max(0, min(3, performance))
        masteryLevel = clampedPerformance
        reviewCount += 1
        updatedAt = Date()
        nextReviewDate = ReviewScheduler.calculateNextReviewDate(
            currentMastery: clampedPerformance,
            reviewCount: reviewCount
        )
    }
    
    func resetProgress() {
        masteryLevel = 0
        reviewCount = 0
        nextReviewDate = Date()
        updatedAt = Date()
    }
    
    func markAsUpdated() {
        updatedAt = Date()
    }
}

enum ReviewScheduler {
    static func calculateNextReviewDate(currentMastery: Int, reviewCount: Int) -> Date {
        let calendar = Calendar.current
        let today = Date()
        let baseIntervals: [Int] = [1, 2, 4, 7, 14, 30, 60]
        let masteryMultiplier: Double = switch currentMastery {
        case 0: 0.5
        case 1: 0.75
        case 2: 1.0
        case 3: 1.5
        default: 1.0
        }
        let index = min(reviewCount, baseIntervals.count - 1)
        let baseInterval = baseIntervals[index]
        let actualInterval = max(1, Int(Double(baseInterval) * masteryMultiplier))
        return calendar.date(byAdding: .day, value: actualInterval, to: today) ?? today
    }
}
