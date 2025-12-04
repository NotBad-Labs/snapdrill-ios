//
//  TestReviewItemFactory.swift
//  NotBadTests
//
//  测试 ReviewItem 工厂 - 创建带真实数据的测试对象
//

import Foundation
import UIKit
@testable import NotBad

/// 测试 ReviewItem 工厂
///
/// 提供创建各种测试场景 ReviewItem 的便捷方法。
///
/// ## 使用示例
///
/// ```swift
/// // 创建带真实图片的 ReviewItem
/// let item = TestReviewItemFactory.createWithImage()
///
/// // 创建批量测试数据
/// let items = TestReviewItemFactory.createBatch(count: 100)
///
/// // 创建特定学科的数据
/// let mathItems = TestReviewItemFactory.createBatch(count: 10, subject: .math)
/// ```
public enum TestReviewItemFactory {
    
    // MARK: - Single Item Creation
    
    /// 创建基础 ReviewItem（无图片）
    public static func create(
        title: String = "测试题目",
        subject: Subject = .math,
        grade: Grade = .grade10,
        mastery: MasteryLevel = .partial,
        difficulty: Difficulty = .medium
    ) -> ReviewItem {
        ReviewItem(
            title: title,
            mastery: mastery,
            subject: subject,
            grade: grade,
            difficulty: difficulty
        )
    }
    
    /// 创建带图片的 ReviewItem
    ///
    /// - Parameters:
    ///   - imageSize: 图片尺寸
    ///   - title: 标题
    ///   - subject: 学科
    /// - Returns: 带真实图片数据的 ReviewItem
    public static func createWithImage(
        imageSize: TestImageFactory.Size = .medium,
        title: String = "测试题目",
        subject: Subject = .math,
        grade: Grade = .grade10,
        mastery: MasteryLevel = .partial
    ) -> ReviewItem {
        let imageData = TestImageFactory.createJPEGData(size: imageSize)
        return ReviewItem(
            imageData: imageData,
            title: title,
            mastery: mastery,
            subject: subject,
            grade: grade
        )
    }
    
    /// 创建带大图片的 ReviewItem（性能测试用）
    public static func createWithLargeImage() -> ReviewItem {
        createWithImage(imageSize: .fullSize, title: "大图片测试")
    }
    
    /// 创建需要复习的 ReviewItem
    public static func createNeedingReview(
        subject: Subject = .math,
        mastery: MasteryLevel = .partial
    ) -> ReviewItem {
        let item = create(subject: subject, mastery: mastery)
        item.nextReviewDate = Date().addingTimeInterval(-86400) // 昨天
        return item
    }
    
    /// 创建已掌握的 ReviewItem
    public static func createMastered(subject: Subject = .math) -> ReviewItem {
        let item = create(subject: subject, mastery: .mastered)
        item.nextReviewDate = Date().addingTimeInterval(86400 * 30) // 30天后
        item.reviewCount = 5
        return item
    }
    
    // MARK: - Batch Creation
    
    /// 创建批量 ReviewItem（无图片）
    ///
    /// - Parameters:
    ///   - count: 数量
    ///   - subject: 可选的固定学科
    /// - Returns: ReviewItem 数组
    public static func createBatch(
        count: Int,
        subject: Subject? = nil
    ) -> [ReviewItem] {
        let subjects = Subject.allCases
        return (0..<count).map { index in
            let itemSubject = subject ?? subjects[index % subjects.count]
            let mastery = MasteryLevel.allCases[index % MasteryLevel.allCases.count]
            return create(
                title: "测试题目 #\(index + 1)",
                subject: itemSubject,
                mastery: mastery
            )
        }
    }
    
    /// 创建带图片的批量 ReviewItem
    ///
    /// - Warning: 这会消耗较多内存，建议 count <= 50
    ///
    /// - Parameters:
    ///   - count: 数量
    ///   - imageSize: 图片尺寸
    /// - Returns: ReviewItem 数组
    public static func createBatchWithImages(
        count: Int,
        imageSize: TestImageFactory.Size = .small
    ) -> [ReviewItem] {
        let subjects = Subject.allCases
        return (0..<count).map { index in
            createWithImage(
                imageSize: imageSize,
                title: "带图测试 #\(index + 1)",
                subject: subjects[index % subjects.count]
            )
        }
    }
    
    /// 创建混合的批量数据（部分有图片）
    ///
    /// - Parameters:
    ///   - count: 总数量
    ///   - imageRatio: 带图片的比例 (0.0 - 1.0)
    /// - Returns: ReviewItem 数组
    public static func createMixedBatch(
        count: Int,
        imageRatio: Double = 0.5
    ) -> [ReviewItem] {
        let imageCount = Int(Double(count) * imageRatio)
        let noImageCount = count - imageCount
        
        var items: [ReviewItem] = []
        items.append(contentsOf: createBatchWithImages(count: imageCount, imageSize: .small))
        items.append(contentsOf: createBatch(count: noImageCount))
        
        return items.shuffled()
    }
    
    // MARK: - Specific Scenarios
    
    /// 创建模拟真实使用场景的数据集
    ///
    /// 包含各种学科、掌握度、有无图片的混合数据
    ///
    /// - Parameter count: 总数量
    /// - Returns: 模拟真实场景的 ReviewItem 数组
    public static func createRealisticDataset(count: Int) -> [ReviewItem] {
        var items: [ReviewItem] = []
        
        for i in 0..<count {
            let hasImage = i % 3 == 0 // 1/3 有图片
            let subject = Subject.allCases[i % Subject.allCases.count]
            let mastery = MasteryLevel.allCases[i % MasteryLevel.allCases.count]
            let needsReview = i % 4 == 0 // 1/4 需要复习
            
            let reviewItem: ReviewItem
            if hasImage {
                reviewItem = createWithImage(
                    imageSize: .small,
                    title: "\(subject.displayName)题目 #\(i + 1)",
                    subject: subject,
                    mastery: mastery
                )
            } else {
                reviewItem = create(
                    title: "\(subject.displayName)题目 #\(i + 1)",
                    subject: subject,
                    mastery: mastery
                )
            }
            
            if needsReview {
                reviewItem.nextReviewDate = Date().addingTimeInterval(-86400 * Double.random(in: 1...7))
            } else {
                reviewItem.nextReviewDate = Date().addingTimeInterval(86400 * Double.random(in: 1...30))
            }
            
            reviewItem.reviewCount = Int.random(in: 0...10)
            items.append(reviewItem)
        }
        
        return items
    }
}

// MARK: - Convenience Extensions

public extension TestReviewItemFactory {
    
    /// 打印数据集统计信息
    static func printStats(for items: [ReviewItem]) {
        let withImage = items.filter { $0.imageData != nil }.count
        let needsReview = items.filter { $0.needsReview }.count
        let totalImageSize = items.compactMap { $0.imageData?.count }.reduce(0, +)
        
        print("""
        📊 数据集统计:
        - 总数: \(items.count)
        - 带图片: \(withImage) (\(withImage * 100 / max(items.count, 1))%)
        - 需要复习: \(needsReview)
        - 图片总大小: \(totalImageSize / 1024) KB
        """)
    }
}
