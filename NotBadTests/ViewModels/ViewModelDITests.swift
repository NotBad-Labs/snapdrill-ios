//
//  ViewModelDITests.swift
//  NotBadTests
//
//  测试 ViewModel 依赖注入功能（Use Case 模式）
//

import Testing
import SwiftData
import Foundation
@testable import NotBad

// MARK: - DashboardViewModel DI Tests

@Suite("DashboardViewModel 依赖注入测试")
struct DashboardViewModelDITests {
    
    @Test("使用默认初始化器")
    @MainActor
    func initWithDefaults() {
        let viewModel = DashboardViewModel()
        
        #expect(viewModel.items.isEmpty)
    }
    
    @Test("初始化后状态正确")
    @MainActor
    func initialStateCorrect() {
        let viewModel = DashboardViewModel()
        
        #expect(viewModel.items.isEmpty)
        #expect(viewModel.selectedTimeRange == .week)
    }
    
    @Test("computeStatistics 计算正确")
    @MainActor
    func computeStatisticsCorrect() {
        let viewModel = DashboardViewModel()
        
        let item1 = ReviewItem(title: "已掌握", subject: .math)
        item1.masteryLevel = MasteryLevel.mastered.rawValue
        let item2 = ReviewItem(title: "学习中", subject: .physics)
        item2.masteryLevel = MasteryLevel.partial.rawValue
        
        let stats = viewModel.computeStatistics(from: [item1, item2])
        
        #expect(stats.totalCount == 2)
        #expect(stats.masteredCount == 1)
    }
}

// MARK: - LibraryViewModel DI Tests

@Suite("LibraryViewModel 依赖注入测试")
struct LibraryViewModelDITests {
    
    @Test("使用默认初始化器")
    @MainActor
    func initWithDefaults() {
        let viewModel = LibraryViewModel()
        
        #expect(viewModel.items.isEmpty)
    }
    
    @Test("初始化后筛选状态正确")
    @MainActor
    func initialFilterStateCorrect() {
        let viewModel = LibraryViewModel()
        
        #expect(viewModel.selectedSubject == nil)
        #expect(viewModel.searchText.isEmpty)
    }
}

// MARK: - ReviewViewModel DI Tests

@Suite("ReviewViewModel 依赖注入测试")
struct ReviewViewModelDITests {
    
    @Test("使用默认初始化器")
    @MainActor
    func initWithDefaults() {
        let viewModel = ReviewViewModel()
        
        #expect(viewModel.items.isEmpty)
    }
    
    @Test("初始化后复习状态正确")
    @MainActor
    func initialReviewStateCorrect() {
        let viewModel = ReviewViewModel()
        
        #expect(viewModel.currentIndex == 0)
        #expect(viewModel.sessionState == .idle)
        #expect(viewModel.reviewedCount == 0)
    }
}

// MARK: - CaptureOrchestrator DI Tests

@Suite("CaptureOrchestrator 依赖注入测试")
struct CaptureOrchestratorDITests {
    
    @Test("初始化后子 ViewModel 可用")
    @MainActor
    func subViewModelsAvailable() {
        let orchestrator = CaptureOrchestrator()
        
        #expect(orchestrator.formVM.title.isEmpty)
        #expect(orchestrator.imageSelectionVM.selectedImage == nil)
    }
    
    @Test("表单 ViewModel 初始状态正确")
    @MainActor
    func formVMInitialState() {
        let orchestrator = CaptureOrchestrator()
        
        // 验证表单 ViewModel 的默认值
        #expect(orchestrator.formVM.subject == .math)
        #expect(orchestrator.formVM.difficulty == .medium)
    }
}
