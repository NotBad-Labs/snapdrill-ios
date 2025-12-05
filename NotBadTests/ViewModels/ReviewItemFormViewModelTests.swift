//
//  ReviewItemFormViewModelTests.swift
//  NotBadTests
//
//  ReviewItemFormViewModel 单元测试
//

import Testing
import Foundation
@testable import NotBad

@Suite("ReviewItemFormViewModel 测试")
@MainActor
struct ReviewItemFormViewModelTests {

    // MARK: - 初始化测试

    @Test("初始状态正确")
    func initialState() {
        let viewModel = ReviewItemFormViewModel()
        let expectedGrade = ReviewItemFormViewModel.getUserDefaultGrade()

        #expect(viewModel.title == "")
        #expect(viewModel.note == "")
        #expect(viewModel.subject == .math)
        #expect(viewModel.grade == expectedGrade)
        #expect(viewModel.knowledgePointsInput == "")
        #expect(viewModel.difficulty == .medium)
        #expect(viewModel.errorType == .other)
        #expect(viewModel.source == .other)
        #expect(viewModel.reviewItemType == .other)
        #expect(viewModel.isAnalyzing == false)
    }

    // MARK: - 知识点测试

    @Test("添加知识点")
    func addKnowledgePoint() {
        let viewModel = ReviewItemFormViewModel()
        
        viewModel.addKnowledgePoint("函数")
        #expect(viewModel.knowledgePointsInput == "函数")
        
        viewModel.addKnowledgePoint("导数")
        #expect(viewModel.knowledgePointsInput == "函数, 导数")
        
        // 测试空值过滤
        viewModel.addKnowledgePoint("  ")
        #expect(viewModel.knowledgePointsInput == "函数, 导数")
    }
    
    @Test("解析知识点")
    func parsedKnowledgePoints() {
        let viewModel = ReviewItemFormViewModel()
        viewModel.knowledgePointsInput = "函数, 导数"
        
        let points = viewModel.parsedKnowledgePoints
        #expect(points.count == 2)
        #expect(points.items.contains("函数"))
        #expect(points.items.contains("导数"))
    }

    // MARK: - 自动填充测试

    @Test("自动填充标题")
    func autoFillTitle() {
        let viewModel = ReviewItemFormViewModel()
        let ocrText = "这是一行标题\n这是正文内容"
        
        viewModel.autoFill(with: ocrText)
        
        #expect(viewModel.title == "这是一行标题")
    }
    
    @Test("重置表单")
    func resetForm() {
        let viewModel = ReviewItemFormViewModel()
        viewModel.title = "测试标题"
        viewModel.subject = .english
        
        viewModel.reset()
        
        #expect(viewModel.title == "")
        #expect(viewModel.subject == .math)
    }
}
