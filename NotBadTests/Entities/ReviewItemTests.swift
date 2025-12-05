//
//  ReviewItemTests.swift
//  NotBadTests
//
//  ReviewItem 实体单元测试
//

import Testing
import Foundation
import UIKit
@testable import NotBad

@Suite("ReviewItem 实体测试")
struct ReviewItemTests {

    // MARK: - 初始化测试

    @Test("默认初始化正确")
    func defaultInitialization() {
        let reviewItem = ReviewItem()

        #expect(reviewItem.title == "未命名错题", "空标题应转为默认标题")
        #expect(reviewItem.note == "", "笔记应为空")
        #expect(reviewItem.subject == .math, "默认学科应为数学")
        #expect(reviewItem.grade == .grade10, "默认年级应为高一")
        #expect(reviewItem.mastery == .none, "默认掌握度应为 none")
        #expect(reviewItem.difficulty == .medium, "默认难度应为中等")
        #expect(reviewItem.reviewCount == 0, "默认复习次数应为 0")
        #expect(reviewItem.imageData == nil, "默认图片应为 nil")
    }

    @Test("自定义初始化正确")
    func customInitialization() {
        let reviewItem = ReviewItem(
            title: "二次函数",
            note: "求极值问题",
            subject: .math,
            grade: .grade11,
            difficulty: .hard
        )

        #expect(reviewItem.title == "二次函数", "标题应保持不变")
        #expect(reviewItem.note == "求极值问题", "笔记应保持不变")
        #expect(reviewItem.subject == .math, "学科应为数学")
        #expect(reviewItem.grade == .grade11, "年级应为高二")
        #expect(reviewItem.difficulty == .hard, "难度应为困难")
    }

    @Test("空标题转为默认标题")
    func emptyTitleConvertsToDefault() {
        // 空字符串转换为默认标题
        let reviewItem = ReviewItem(title: "")
        #expect(reviewItem.title == "未命名错题", "空字符串应转为默认标题")

        // 纯空白字符串也转换为默认标题（normalizeTitle 会 trim）
        let reviewItem2 = ReviewItem(title: "   ")
        #expect(reviewItem2.title == "未命名错题", "纯空白应转为默认标题")
        
        // 正常标题保持不变（但会 trim）
        let reviewItem3 = ReviewItem(title: "  测试标题  ")
        #expect(reviewItem3.title == "测试标题", "标题应被 trim 后保留")
    }

    // MARK: - 值对象访问器测试

    @Test("学科访问器正确")
    func subjectAccessor() {
        let reviewItem = ReviewItem(subject: .physics)
        #expect(reviewItem.subject == .physics)

        reviewItem.subject = .chemistry
        #expect(reviewItem.subject == .chemistry)
        #expect(reviewItem.subjectRaw == "chemistry")
    }

    @Test("年级访问器正确")
    func gradeAccessor() {
        let reviewItem = ReviewItem(grade: .grade7)
        #expect(reviewItem.grade == .grade7)

        reviewItem.grade = .grade9
        #expect(reviewItem.grade == .grade9)
        #expect(reviewItem.gradeRaw == "grade_9")
    }

    @Test("掌握程度访问器正确")
    func masteryAccessor() {
        let reviewItem = ReviewItem(mastery: .partial)
        #expect(reviewItem.mastery == .partial)

        reviewItem.mastery = .good
        #expect(reviewItem.mastery == .good)
        #expect(reviewItem.masteryLevel == MasteryLevel.good.rawValue)
    }

    @Test("知识点访问器正确")
    func knowledgePointsAccessor() {
        let points = KnowledgePoints(from: "二次函数, 极值")
        let reviewItem = ReviewItem(knowledgePoints: points)

        #expect(reviewItem.knowledgePoints.count == 2)
        #expect(reviewItem.knowledgePoints.contains("二次函数"))
        #expect(reviewItem.knowledgePoints.contains("极值"))
    }

    // MARK: - 计算属性测试

    @Test("有图片正确判断")
    func hasImageProperty() {
        let reviewItem1 = ReviewItem()
        #expect(reviewItem1.hasImage == false)

        let reviewItem2 = ReviewItem(imageData: TestImageFactory.createJPEGData(size: .thumbnail))
        #expect(reviewItem2.hasImage == true)

        let reviewItem3 = ReviewItem(imageData: Data())
        #expect(reviewItem3.hasImage == false)
    }

    @Test("hasNote 正确判断")
    func hasNoteProperty() {
        let reviewItem1 = ReviewItem(note: "")
        #expect(reviewItem1.hasNote == false)

        let reviewItem2 = ReviewItem(note: "   ")
        #expect(reviewItem2.hasNote == false)

        let reviewItem3 = ReviewItem(note: "这是笔记")
        #expect(reviewItem3.hasNote == true)
    }

    @Test("hasKnowledgePoints 正确判断")
    func hasKnowledgePointsProperty() {
        let reviewItem1 = ReviewItem()
        #expect(reviewItem1.hasKnowledgePoints == false)

        let reviewItem2 = ReviewItem(knowledgePoints: KnowledgePoints(from: "函数"))
        #expect(reviewItem2.hasKnowledgePoints == true)
    }

    @Test("needsReview 正确判断")
    func needsReviewProperty() {
        let reviewItem = ReviewItem()
        // 新创建的项目 nextReviewDate == createdAt，应该需要复习
        #expect(reviewItem.needsReview == true)
    }

    @Test("isNew 正确判断")
    func isNewProperty() {
        let reviewItem = ReviewItem()
        #expect(reviewItem.isNew == true)

        reviewItem.reviewCount = 1
        #expect(reviewItem.isNew == false)
    }

    @Test("isMastered 正确判断")
    func isMasteredProperty() {
        let reviewItem = ReviewItem(mastery: .none)
        #expect(reviewItem.isMastered == false)

        reviewItem.mastery = .partial
        #expect(reviewItem.isMastered == false)

        reviewItem.mastery = .good
        #expect(reviewItem.isMastered == true)

        reviewItem.mastery = .mastered
        #expect(reviewItem.isMastered == true)
    }

    // MARK: - 显示属性测试

    @Test("displayTitle 正确处理")
    func displayTitleProperty() {
        let reviewItem1 = ReviewItem(title: "测试题目")
        #expect(reviewItem1.displayTitle == "测试题目")

        // 空白标题应返回默认值
        let reviewItem2 = ReviewItem()
        reviewItem2.title = "   "
        #expect(reviewItem2.displayTitle == "未命名错题")
    }

    @Test("shortDescriptionForUI 格式正确")
    @MainActor
    func shortDescriptionProperty() {
        let reviewItem = ReviewItem(subject: .math, reviewItemType: .calculation)
        let desc = reviewItem.shortDescriptionForUI
        
        // 使用 EducationSystemManager 获取期望的显示名称
        let subjectName = EducationSystemManager.shared.subjectDisplayName(for: reviewItem.subjectRaw)
        
        #expect(desc.contains(subjectName))
        #expect(desc.contains(reviewItem.reviewItemType.displayName))
    }

    @Test("fullDescriptionForUI 格式正确")
    @MainActor
    func fullDescriptionProperty() {
        let reviewItem = ReviewItem(
            subject: .physics,
            grade: .grade11,
            difficulty: .hard,
            reviewItemType: .calculation
        )
        let desc = reviewItem.fullDescriptionForUI

        // 使用 EducationSystemManager 获取期望的显示名称，以避免测试环境本地化问题
        let subjectName = EducationSystemManager.shared.subjectDisplayName(for: reviewItem.subjectRaw)
        let gradeName = EducationSystemManager.shared.gradeDisplayName(for: reviewItem.gradeRaw)

        #expect(desc.contains(subjectName))
        #expect(desc.contains(gradeName))
        #expect(desc.contains(reviewItem.difficulty.displayName))
        #expect(desc.contains(reviewItem.reviewItemType.displayName))
    }

    // MARK: - 复习操作测试

    @Test("recordReview 正确更新状态")
    func recordReviewAction() {
        let reviewItem = ReviewItem()
        let originalCount = reviewItem.reviewCount

        reviewItem.recordReview(newMastery: .partial)

        #expect(reviewItem.reviewCount == originalCount + 1, "复习次数应+1")
        #expect(reviewItem.mastery == .partial, "掌握度应更新为 partial")
        #expect(reviewItem.nextReviewDate > Date(), "下次复习日期应在未来")
    }

    @Test("resetProgress 使用渐进式退阶策略")
    func resetProgressAction() {
        let reviewItem = ReviewItem()
        reviewItem.recordReview(newMastery: .good)
        reviewItem.recordReview(newMastery: .mastered)
        
        // 复习次数现在是 2，掌握度是 mastered
        let originalCount = reviewItem.reviewCount
        
        reviewItem.resetProgress()
        
        // 渐进式退阶：mastered → partial，复习次数减半
        #expect(reviewItem.reviewCount == originalCount / 2, "复习次数应减半，保留学习记录")
        #expect(reviewItem.mastery == .partial, "mastered 应退阶为 partial")
    }
    
    @Test("hardResetProgress 完全重置复习进度")
    func hardResetProgressAction() {
        let reviewItem = ReviewItem()
        reviewItem.recordReview(newMastery: .good)
        reviewItem.recordReview(newMastery: .mastered)
        
        reviewItem.hardResetProgress()
        
        // 完全重置：复习次数归零，掌握度重置为 none
        #expect(reviewItem.reviewCount == 0, "完全重置应将复习次数清零")
        #expect(reviewItem.mastery == .none, "完全重置应将掌握度设为 none")
    }

    @Test("addKnowledgePoint 正确添加")
    func addKnowledgePointAction() {
        let reviewItem = ReviewItem()
        reviewItem.addKnowledgePoint("函数")
        reviewItem.addKnowledgePoint("极值")

        #expect(reviewItem.knowledgePoints.count == 2)
        #expect(reviewItem.knowledgePoints.contains("函数"))
        #expect(reviewItem.knowledgePoints.contains("极值"))
    }

    @Test("removeKnowledgePoint 正确移除")
    func removeKnowledgePointAction() {
        let reviewItem = ReviewItem(knowledgePoints: KnowledgePoints(from: "函数, 极值"))
        reviewItem.removeKnowledgePoint("函数")

        #expect(reviewItem.knowledgePoints.count == 1)
        #expect(!reviewItem.knowledgePoints.contains("函数"))
        #expect(reviewItem.knowledgePoints.contains("极值"))
    }

    @Test("updateNote 正确更新")
    func updateNoteAction() {
        let reviewItem = ReviewItem()
        let originalDate = reviewItem.updatedAt

        // 短暂等待以确保时间差异
        Thread.sleep(forTimeInterval: 0.01)
        reviewItem.updateNote("新笔记")

        #expect(reviewItem.note == "新笔记")
        #expect(reviewItem.updatedAt > originalDate)
    }

    @Test("updateTitle 正确更新")
    func updateTitleAction() {
        let reviewItem = ReviewItem()
        reviewItem.updateTitle("新标题")
        #expect(reviewItem.title == "新标题")

        reviewItem.updateTitle("")
        #expect(reviewItem.title == "未命名错题")
    }

    // MARK: - 验证测试

    @Test("validateItem 返回正确结果")
    func validateMethod() {
        let reviewItem = ReviewItem(
            imageData: TestImageFactory.createJPEGData(size: .thumbnail),
            title: "测试",
            knowledgePoints: KnowledgePoints(from: "知识点")
        )

        let result = reviewItem.validateItem()
        #expect(result.isValid == true, "完整数据应验证通过")
        #expect(result.errors.isEmpty, "完整数据不应有错误")
    }

    @Test("validateItem 检测缺失内容")
    func validateDetectsMissingContent() {
        // 创建一个 ReviewItem，然后直接修改 title 为空（绕过 normalizeTitle）
        let reviewItem = ReviewItem(title: "测试")
        reviewItem.title = "   " // 直接设置空白标题
        let result = reviewItem.validateItem()

        #expect(result.errors.contains(.titleRequired))
    }

    @Test("isComplete 正确判断")
    func isCompleteProperty() {
        let reviewItem1 = ReviewItem()
        #expect(reviewItem1.isComplete == false, "空数据应不完整")

        // 有图片 + 知识点 = 完整
        let reviewItem2 = ReviewItem(
            imageData: TestImageFactory.createJPEGData(size: .thumbnail),
            title: "测试",
            knowledgePoints: KnowledgePoints(from: "知识点")
        )
        #expect(reviewItem2.isComplete == true, "有图片+知识点应完整")

        // 有笔记 + 知识点 = 也完整（无需图片）
        let reviewItem3 = ReviewItem(
            title: "测试",
            note: "这是笔记内容",
            knowledgePoints: KnowledgePoints(from: "知识点")
        )
        #expect(reviewItem3.isComplete == true, "有笔记+知识点应完整")

        // 只有知识点，无图片无笔记 = 不完整
        let reviewItem4 = ReviewItem(
            title: "测试",
            knowledgePoints: KnowledgePoints(from: "知识点")
        )
        #expect(reviewItem4.isComplete == false, "无图片无笔记应不完整")
    }

    // MARK: - Comparable 测试

    @Test("Comparable 按 nextReviewDate 排序")
    func comparableConformance() {
        let reviewItem1 = ReviewItem()
        reviewItem1.nextReviewDate = Date().addingTimeInterval(-3600) // 1小时前

        let reviewItem2 = ReviewItem()
        reviewItem2.nextReviewDate = Date().addingTimeInterval(3600) // 1小时后

        #expect(reviewItem1 < reviewItem2)
    }

    // MARK: - 综合难度测试

    @Test("overallDifficultyScore 计算正确")
    func overallDifficultyScoreCalculation() {
        let reviewItem = ReviewItem(difficulty: .hard, reviewItemType: .calculation)

        // hard = 3, calculation 是主观题权重 1.5
        let expectedScore = 3.0 * 1.5
        #expect(reviewItem.overallDifficultyScore == expectedScore)
    }
}
