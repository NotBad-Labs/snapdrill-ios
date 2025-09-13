//
//  AppCoordinator.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//  应用程序协调器 - 管理基本导航和状态，集成SwiftData
//

import SwiftUI
import SwiftData

/// 应用程序协调器 - 负责整个应用的导航流程
@MainActor
class AppCoordinator: ObservableObject {
    
    // MARK: - 应用状态
    @Published var isLoading = true
    @Published var currentFlow: AppFlow = .splash
    
    // MARK: - 数据层
    let modelContainer: ModelContainer
    let repository: ReviewItemRepository
    let createReviewItemUseCase: CreateReviewItemUseCase
    let getReviewItemsUseCase: GetReviewItemsUseCase
    
    init() {
        // 初始化SwiftData容器
        do {
            let schema = Schema([
                ReviewItem.self,
                ReviewContent.self,
                ReviewItemMetadata.self,
                StudyRecord.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            // 初始化仓库和用例
            self.repository = try SwiftDataReviewItemRepository()
            self.createReviewItemUseCase = CreateReviewItemUseCaseImpl(repository: repository)
            self.getReviewItemsUseCase = GetReviewItemsUseCaseImpl(repository: repository)
            
        } catch {
            fatalError("Failed to initialize SwiftData: \(error)")
        }
        
        // 启动应用
        setupApplication()
    }
    
    // MARK: - 应用设置
    private func setupApplication() {
        Task {
            // 模拟启动流程 - 1秒后进入主界面
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                self.isLoading = false
                self.currentFlow = .main
            }
        }
    }
    
    // MARK: - 导航方法
    func navigateToFlow(_ flow: AppFlow) {
        currentFlow = flow
    }
}

/// 应用流程枚举
enum AppFlow {
    case splash      // 启动画面
    case main        // 主界面
}
