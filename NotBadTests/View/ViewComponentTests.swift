//
//  ViewComponentTests.swift
//  NotBadTests
//
//  View 组件测试
//
//  注意：SwiftUI View 无法直接单元测试渲染结果，
//  这里测试 View 的数据绑定和计算属性是否正确。
//

import XCTest
import SwiftUI
@testable import NotBad

/// View 组件测试
///
/// 测试 View 相关的辅助逻辑和数据绑定
final class ViewComponentTests: XCTestCase {
    
    // MARK: - MasteryLevel Display Tests
    
    /// 测试掌握度颜色
    func testMasteryLevelColors() {
        let levels = MasteryLevel.allCases
        
        for level in levels {
            // 确保每个级别都有颜色
            XCTAssertFalse(level.color.description.isEmpty)
            print("MasteryLevel.\(level): \(level.color.description)")
        }
    }
    
    /// 测试掌握度图标
    func testMasteryLevelIcons() {
        for level in MasteryLevel.allCases {
            XCTAssertFalse(level.icon.isEmpty)
        }
    }
    
    /// 测试掌握度显示名称
    func testMasteryLevelDisplayNames() {
        for level in MasteryLevel.allCases {
            XCTAssertFalse(level.displayName.isEmpty)
        }
    }
    
    // MARK: - Difficulty Display Tests
    
    /// 测试难度颜色
    func testDifficultyColors() {
        for difficulty in Difficulty.allCases {
            XCTAssertFalse(difficulty.color.description.isEmpty)
        }
    }
    
    /// 测试难度图标
    func testDifficultyIcons() {
        for difficulty in Difficulty.allCases {
            XCTAssertFalse(difficulty.icon.isEmpty)
        }
    }
    
    // MARK: - Subject Display Tests
    
    /// 测试学科颜色
    func testSubjectColors() {
        for subject in Subject.allCases {
            XCTAssertFalse(subject.color.description.isEmpty)
        }
    }
    
    /// 测试学科图标
    func testSubjectIcons() {
        for subject in Subject.allCases {
            XCTAssertFalse(subject.icon.isEmpty)
        }
    }
    
    // MARK: - ReviewItem Display Properties Tests
    
    /// 测试 ReviewItem 的显示属性
    @MainActor
    func testReviewItemDisplayProperties() {
        let item = TestReviewItemFactory.createWithImage(
            title: "测试题目",
            subject: .math,
            mastery: .partial
        )
        
        // 验证显示属性
        XCTAssertEqual(item.displayTitle, "测试题目")
        XCTAssertFalse(item.shortDescription.isEmpty)
        XCTAssertFalse(item.fullDescription.isEmpty)
    }
    
    /// 测试空标题的显示处理
    @MainActor
    func testEmptyTitleDisplay() {
        let reviewItem = ReviewItem()
        reviewItem.title = "   " // 空白标题
        
        // displayTitle 应该返回默认值
        XCTAssertEqual(reviewItem.displayTitle, "未命名错题")
    }
    
    // MARK: - FilterChip Logic Tests
    
    /// 测试筛选状态切换逻辑
    func testFilterSelectionToggle() {
        var selectedSubjects: Set<Subject> = []
        
        // 选择
        selectedSubjects.insert(.math)
        XCTAssertTrue(selectedSubjects.contains(.math))
        
        // 再次点击取消选择
        if selectedSubjects.contains(.math) {
            selectedSubjects.remove(.math)
        } else {
            selectedSubjects.insert(.math)
        }
        XCTAssertFalse(selectedSubjects.contains(.math))
    }
    
    // MARK: - Dashboard Card Data Tests
    
    /// 测试仪表盘统计数据格式化
    @MainActor
    func testDashboardStatisticsFormatting() {
        let viewModel = DashboardViewModel()
        let items = TestReviewItemFactory.createRealisticDataset(count: 50)
        
        let stats = viewModel.computeStatistics(from: items)
        
        // 验证数值范围
        XCTAssertGreaterThanOrEqual(stats.totalCount, 0)
        XCTAssertGreaterThanOrEqual(stats.masteryRate, 0)
        XCTAssertLessThanOrEqual(stats.masteryRate, 1)
        XCTAssertGreaterThanOrEqual(stats.weeklyNewCount, 0)
        XCTAssertGreaterThanOrEqual(stats.overdueCount, 0)
    }
    
    // MARK: - Image Thumbnail Tests
    
    /// 测试缩略图生成
    func testThumbnailGeneration() {
        let originalImage = TestImageFactory.createImage(size: .large)
        let targetSize = CGSize(width: 140, height: 140)
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let thumbnail = renderer.image { _ in
            originalImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        // 缩略图尺寸应该正确
        XCTAssertEqual(thumbnail.size.width, 140)
        XCTAssertEqual(thumbnail.size.height, 140)
    }
    
    /// 测试图片缩放保持宽高比
    func testImageAspectRatioPreservation() {
        // 创建非正方形图片
        let size = CGSize(width: 1600, height: 900) // 16:9
        let image = TestImageFactory.createImage(cgSize: size)
        
        // 缩放到最大 200
        let resized = ImageCompressor.resize(image, maxDimension: 200)
        
        // 验证宽高比保持
        let originalRatio = size.width / size.height
        let resizedRatio = resized.size.width / resized.size.height
        
        XCTAssertEqual(originalRatio, resizedRatio, accuracy: 0.01)
        
        // 最大边应该是 200
        let maxDimension = max(resized.size.width, resized.size.height)
        XCTAssertLessThanOrEqual(maxDimension, 200)
    }
    
    // MARK: - Time Formatting Tests
    
    /// 测试复习统计时间格式化
    /// 注意: ReviewSessionStatistics.formattedDuration 已在 ReviewViewModelTests 中测试
    func testReviewSessionStatisticsFormatting() {
        // 测试 ReviewSessionStatistics 的 formattedDuration
        let stats1 = ReviewSessionStatistics(
            totalReviewed: 10,
            elapsedSeconds: 125, // 2分5秒
            masteryResults: [.mastered: 3, .good: 5, .partial: 2]
        )
        
        // 验证格式化
        XCTAssertTrue(stats1.formattedDuration.contains("2"))
        XCTAssertTrue(stats1.formattedDuration.contains("5"))
        
        let stats2 = ReviewSessionStatistics(
            totalReviewed: 5,
            elapsedSeconds: 45, // 45秒
            masteryResults: [.mastered: 2, .good: 2, .partial: 1]
        )
        
        // 验证格式化
        XCTAssertTrue(stats2.formattedDuration.contains("45"))
    }
    
    // MARK: - Accessibility Tests
    
    /// 测试值对象的可访问性描述
    func testAccessibilityDescriptions() {
        // 所有掌握度都应该有显示名称（用于 VoiceOver）
        for level in MasteryLevel.allCases {
            XCTAssertFalse(level.displayName.isEmpty)
        }
        
        // 所有学科都应该有显示名称
        for subject in Subject.allCases {
            XCTAssertFalse(subject.displayName.isEmpty)
        }
        
        // 所有难度都应该有显示名称
        for difficulty in Difficulty.allCases {
            XCTAssertFalse(difficulty.displayName.isEmpty)
        }
    }
    
    // MARK: - Search Highlight Tests
    
    /// 测试搜索文本匹配
    func testSearchTextMatching() {
        let item = TestReviewItemFactory.create(title: "一元二次方程求解")
        
        // 测试不同搜索词
        XCTAssertTrue(item.title.localizedCaseInsensitiveContains("方程"))
        XCTAssertTrue(item.title.localizedCaseInsensitiveContains("一元"))
        XCTAssertFalse(item.title.localizedCaseInsensitiveContains("函数"))
    }
    
    // MARK: - ItemRow Render Data Tests
    
    /// 测试 ItemRow 所需的所有显示数据
    @MainActor
    func testItemRowDisplayData() {
        let item = TestReviewItemFactory.createWithImage(
            title: "测试：一元二次方程求根公式",
            subject: .math,
            mastery: .partial
        )
        
        // ItemRow 需要的所有显示数据
        XCTAssertFalse(item.displayTitle.isEmpty, "标题不应为空")
        XCTAssertFalse(item.subject.displayName.isEmpty, "学科名称不应为空")
        XCTAssertFalse(item.subject.icon.isEmpty, "学科图标不应为空")
        XCTAssertFalse(item.mastery.displayName.isEmpty, "掌握度名称不应为空")
        XCTAssertFalse(item.mastery.icon.isEmpty, "掌握度图标不应为空")
        XCTAssertFalse(item.difficulty.displayName.isEmpty, "难度名称不应为空")
        
        // 验证有图片数据
        XCTAssertTrue(item.hasImage, "应该有图片")
        XCTAssertNotNil(item.imageData, "图片数据不应为空")
    }
    
    /// 测试 ItemRow 缩略图生成逻辑
    @MainActor
    func testItemRowThumbnailGeneration() {
        let item = TestReviewItemFactory.createWithImage(imageSize: .medium)
        
        guard let imageData = item.imageData,
              let originalImage = UIImage(data: imageData) else {
            XCTFail("应该能解码图片")
            return
        }
        
        // 生成缩略图
        let thumbnail = ImageCompressor.resize(originalImage, maxDimension: 140)
        
        // 验证缩略图尺寸
        let maxDimension = max(thumbnail.size.width, thumbnail.size.height)
        XCTAssertLessThanOrEqual(maxDimension, 140, "缩略图最大边应 <= 140")
    }
    
    /// 测试无图片 ItemRow 的处理
    @MainActor
    func testItemRowWithoutImage() {
        let item = TestReviewItemFactory.create(title: "纯文本题目")
        item.imageData = nil
        
        // 验证无图片时的状态
        XCTAssertFalse(item.hasImage)
        XCTAssertNil(item.imageData)
        
        // 其他显示数据应该仍然正常
        XCTAssertFalse(item.displayTitle.isEmpty)
        XCTAssertFalse(item.subject.displayName.isEmpty)
    }
    
    /// 测试 ItemRow 日期格式化
    @MainActor
    func testItemRowDateFormatting() {
        let item = TestReviewItemFactory.create()
        
        // 验证日期可以格式化
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        let formattedDate = formatter.string(from: item.createdAt)
        
        XCTAssertFalse(formattedDate.isEmpty, "日期格式化不应为空")
    }
    
    /// 测试 ItemRow 复习状态显示
    @MainActor
    func testItemRowReviewStatusDisplay() {
        let needsReviewItem = TestReviewItemFactory.create(mastery: .none)
        let masteredItem = TestReviewItemFactory.create(mastery: .mastered)
        
        // 验证复习状态
        XCTAssertTrue(needsReviewItem.needsReview || !needsReviewItem.isMastered, 
                     "未掌握的题目应该需要复习或未掌握")
        XCTAssertTrue(masteredItem.isMastered, "mastered 级别应该是已掌握")
    }
}
