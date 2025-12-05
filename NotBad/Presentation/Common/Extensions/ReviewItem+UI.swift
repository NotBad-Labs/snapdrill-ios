//
//  ReviewItem+UI.swift
//  NotBad
//
//  ReviewItem 的 UI 扩展
//
//  将显示相关的属性从 Domain 层分离到 Presentation 层，
//  确保 Domain 层不依赖 Infrastructure（L10n、EducationSystemManager）。
//

import Foundation

// MARK: - ReviewItem UI Properties

extension ReviewItem {

    /// 简短描述（UI 展示用）
    ///
    /// 格式：「学科 · 题型」
    @MainActor
    var shortDescriptionForUI: String {
        let subjectName = EducationSystemManager.shared.subjectDisplayName(for: subjectRaw)
        return "\(subjectName) · \(reviewItemType.displayName)"
    }

    /// 完整描述（UI 展示用）
    ///
    /// 格式：「学科 · 年级 · 题型 · 难度」
    @MainActor
    var fullDescriptionForUI: String {
        let subjectName = EducationSystemManager.shared.subjectDisplayName(for: subjectRaw)
        let gradeName = EducationSystemManager.shared.gradeDisplayName(for: gradeRaw)
        return "\(subjectName) · \(gradeName) · \(reviewItemType.displayName) · \(difficulty.displayName)"
    }

    /// 复习状态描述（UI 展示用）
    ///
    /// 根据当前复习状态返回本地化的描述文本
    var reviewStatusDescriptionForUI: String {
        if isNew {
            return L10n.ReviewStatus.new
        } else if needsReview {
            if isOverdue {
                return L10n.ReviewStatus.overdue(days: reviewInterval.overdueByDays)
            } else {
                return L10n.ReviewStatus.today
            }
        } else {
            return L10n.ReviewStatus.inDays(daysUntilReview)
        }
    }

    /// 掌握状态描述（UI 展示用）
    var masteryStatusDescriptionForUI: String {
        "\(mastery.displayName) · \(L10n.Review.reviewedTimes(reviewCount))"
    }
}
