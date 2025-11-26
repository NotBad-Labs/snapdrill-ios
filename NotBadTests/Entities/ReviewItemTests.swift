//
//  ReviewItemTests.swift
//  NotBadTests
//
//  ReviewItem 实体单元测试
//

import Testing
import Foundation
@testable import NotBad

@Suite("ReviewItem 实体测试")
struct ReviewItemTests {
    
    // MARK: - 初始化测试
    
    @Test("默认初始化正确")
    func defaultInitialization() {
        let item = ReviewItem()
        
        #expect(item.title == "未命名错题")
        #expect(item.note == "")
        #expect(item.subject == .math)
        #expect(item.grade == .grade10)
        #expect(item.mastery == .none)
        #expect(item.difficulty == .medium)
        #expect(item.reviewCount == 0)
        #expect(item.imageData == nil)
    }
    
    @Test("自定义初始化正确")
    func customInitialization() {
        let item = ReviewItem(
            title: "二次函数",
            note: "求极值问题",
            subject: .math,
            grade: .grade11,
            difficulty: .hard
        )
        
        #expect(item.title == "二次函数")
        #expect(item.note == "求极值问题")
        #expect(item.subject == .math)
        #expect(item.grade == .grade11)
        #expect(item.difficulty == .hard)
    }
    
    @Test("空标题转为默认标题")
    func emptyTitleConvertsToDefault() {
        let item = ReviewItem(title: "")
        #expect(item.title == "未命名错题")
        
        let item2 = ReviewItem(title: "   ")
        #expect(item2.title == "   ") // 只有完全空才转换
    }
    
    // MARK: - 值对象访问器测试
    
    @Test("学科访问器正确")
    func subjectAccessor() {
        let item = ReviewItem(subject: .physics)
        #expect(item.subject == .physics)
        
        item.subject = .chemistry
        #expect(item.subject == .chemistry)
        #expect(item.subjectRaw == "化学")
    }
    
    @Test("年级访问器正确")
    func gradeAccessor() {
        let item = ReviewItem(grade: .grade7)
        #expect(item.grade == .grade7)
        
        item.grade = .grade9
        #expect(item.grade == .grade9)
        #expect(item.gradeRaw == "九年级") // rawValue 是全称，不是简称
    }
    
    @Test("掌握程度访问器正确")
    func masteryAccessor() {
        let item = ReviewItem(mastery: .partial)
        #expect(item.mastery == .partial)
        
        item.mastery = .good
        #expect(item.mastery == .good)
        #expect(item.masteryLevel == MasteryLevel.good.rawValue)
    }
    
    @Test("知识点访问器正确")
    func knowledgePointsAccessor() {
        let points = KnowledgePoints(from: "二次函数, 极值")
        let item = ReviewItem(knowledgePoints: points)
        
        #expect(item.knowledgePoints.count == 2)
        #expect(item.knowledgePoints.contains("二次函数"))
        #expect(item.knowledgePoints.contains("极值"))
    }
    
    // MARK: - 计算属性测试
    
    @Test("hasImage 正确判断")
    func hasImageProperty() {
        let item1 = ReviewItem()
        #expect(item1.hasImage == false)
        
        let item2 = ReviewItem(imageData: Data([0x00, 0x01]))
        #expect(item2.hasImage == true)
        
        let item3 = ReviewItem(imageData: Data())
        #expect(item3.hasImage == false)
    }
    
    @Test("hasNote 正确判断")
    func hasNoteProperty() {
        let item1 = ReviewItem(note: "")
        #expect(item1.hasNote == false)
        
        let item2 = ReviewItem(note: "   ")
        #expect(item2.hasNote == false)
        
        let item3 = ReviewItem(note: "这是笔记")
        #expect(item3.hasNote == true)
    }
    
    @Test("hasKnowledgePoints 正确判断")
    func hasKnowledgePointsProperty() {
        let item1 = ReviewItem()
        #expect(item1.hasKnowledgePoints == false)
        
        let item2 = ReviewItem(knowledgePoints: KnowledgePoints(from: "函数"))
        #expect(item2.hasKnowledgePoints == true)
    }
    
    @Test("needsReview 正确判断")
    func needsReviewProperty() {
        let item = ReviewItem()
        // 新创建的项目 nextReviewDate == createdAt，应该需要复习
        #expect(item.needsReview == true)
    }
    
    @Test("isNew 正确判断")
    func isNewProperty() {
        let item = ReviewItem()
        #expect(item.isNew == true)
        
        item.reviewCount = 1
        #expect(item.isNew == false)
    }
    
    @Test("isMastered 正确判断")
    func isMasteredProperty() {
        let item = ReviewItem(mastery: .none)
        #expect(item.isMastered == false)
        
        item.mastery = .partial
        #expect(item.isMastered == false)
        
        item.mastery = .good
        #expect(item.isMastered == true)
        
        item.mastery = .mastered
        #expect(item.isMastered == true)
    }
    
    // MARK: - 显示属性测试
    
    @Test("displayTitle 正确处理")
    func displayTitleProperty() {
        let item1 = ReviewItem(title: "测试题目")
        #expect(item1.displayTitle == "测试题目")
        
        // 空白标题应返回默认值
        let item2 = ReviewItem()
        item2.title = "   "
        #expect(item2.displayTitle == "未命名错题")
    }
    
    @Test("shortDescription 格式正确")
    func shortDescriptionProperty() {
        let item = ReviewItem(subject: .math, questionType: .calculation)
        #expect(item.shortDescription.contains("数学"))
        #expect(item.shortDescription.contains("计算题"))
    }
    
    @Test("fullDescription 格式正确")
    func fullDescriptionProperty() {
        let item = ReviewItem(
            subject: .physics,
            grade: .grade11,
            difficulty: .hard,
            questionType: .calculation
        )
        let desc = item.fullDescription
        #expect(desc.contains("物理"))
        #expect(desc.contains("高二"))
        #expect(desc.contains("困难"))
        #expect(desc.contains("计算题"))
    }
    
    // MARK: - 复习操作测试
    
    @Test("recordReview 正确更新状态")
    func recordReviewAction() {
        let item = ReviewItem()
        let originalCount = item.reviewCount
        
        item.recordReview(newMastery: .partial)
        
        #expect(item.reviewCount == originalCount + 1)
        #expect(item.mastery == .partial)
        #expect(item.nextReviewDate > Date())
    }
    
    @Test("resetProgress 正确重置")
    func resetProgressAction() {
        let item = ReviewItem()
        item.recordReview(newMastery: .good)
        item.recordReview(newMastery: .mastered)
        
        item.resetProgress()
        
        #expect(item.reviewCount == 0)
        #expect(item.mastery == .none)
    }
    
    @Test("addKnowledgePoint 正确添加")
    func addKnowledgePointAction() {
        let item = ReviewItem()
        item.addKnowledgePoint("函数")
        item.addKnowledgePoint("极值")
        
        #expect(item.knowledgePoints.count == 2)
        #expect(item.knowledgePoints.contains("函数"))
        #expect(item.knowledgePoints.contains("极值"))
    }
    
    @Test("removeKnowledgePoint 正确移除")
    func removeKnowledgePointAction() {
        let item = ReviewItem(knowledgePoints: KnowledgePoints(from: "函数, 极值"))
        item.removeKnowledgePoint("函数")
        
        #expect(item.knowledgePoints.count == 1)
        #expect(!item.knowledgePoints.contains("函数"))
        #expect(item.knowledgePoints.contains("极值"))
    }
    
    @Test("updateNote 正确更新")
    func updateNoteAction() {
        let item = ReviewItem()
        let originalDate = item.updatedAt
        
        // 短暂等待以确保时间差异
        Thread.sleep(forTimeInterval: 0.01)
        item.updateNote("新笔记")
        
        #expect(item.note == "新笔记")
        #expect(item.updatedAt > originalDate)
    }
    
    @Test("updateTitle 正确更新")
    func updateTitleAction() {
        let item = ReviewItem()
        item.updateTitle("新标题")
        #expect(item.title == "新标题")
        
        item.updateTitle("")
        #expect(item.title == "未命名错题")
    }
    
    // MARK: - 验证测试
    
    @Test("validate 返回正确结果")
    func validateMethod() {
        let item = ReviewItem(
            imageData: Data([0x00]),
            title: "测试",
            knowledgePoints: KnowledgePoints(from: "知识点")
        )
        
        let (isValid, issues) = item.validate()
        #expect(isValid == true)
        #expect(issues.isEmpty)
    }
    
    @Test("validate 检测缺失内容")
    func validateDetectsMissingContent() {
        let item = ReviewItem(title: "   ")
        let (_, issues) = item.validate()
        
        #expect(issues.contains { $0.contains("标题") })
    }
    
    @Test("isComplete 正确判断")
    func isCompleteProperty() {
        let item1 = ReviewItem()
        #expect(item1.isComplete == false)
        
        let item2 = ReviewItem(
            imageData: Data([0x00]),
            title: "测试",
            knowledgePoints: KnowledgePoints(from: "知识点")
        )
        #expect(item2.isComplete == true)
    }
    
    // MARK: - Comparable 测试
    
    @Test("Comparable 按 nextReviewDate 排序")
    func comparableConformance() {
        let item1 = ReviewItem()
        item1.nextReviewDate = Date().addingTimeInterval(-3600) // 1小时前
        
        let item2 = ReviewItem()
        item2.nextReviewDate = Date().addingTimeInterval(3600) // 1小时后
        
        #expect(item1 < item2)
    }
    
    // MARK: - 综合难度测试
    
    @Test("overallDifficultyScore 计算正确")
    func overallDifficultyScoreCalculation() {
        let item = ReviewItem(difficulty: .hard, questionType: .calculation)
        
        // hard = 3, calculation 是主观题权重 1.5
        let expectedScore = 3.0 * 1.5
        #expect(item.overallDifficultyScore == expectedScore)
    }
}
