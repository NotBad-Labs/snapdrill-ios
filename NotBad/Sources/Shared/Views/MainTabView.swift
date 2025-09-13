//
//  MainTabView.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//  主界面TabView - 底部导航容器
//

import SwiftUI

/// 主界面 - 底部TabView容器
struct MainTabView: View {
    // 依赖注入 - 从AppCoordinator传递
    let createReviewItemUseCase: CreateReviewItemUseCase
    
    var body: some View {
                TabView {
                    // Tab 1: 首页
                    NavigationView {
                        HomeTabView()
                    }
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("首页")
                    }

                    // Tab 2: 题库
                    NavigationView {
                        QuestionBankTabView()
                    }
                    .tabItem {
                        Image(systemName: "book.fill")
                        Text("题库")
                    }

                    // Tab 3: 录入
                    NavigationView {
                        CaptureTabView(createReviewItemUseCase: createReviewItemUseCase)
                    }
                    .tabItem {
                        Image(systemName: "camera.fill")
                        Text("录入")
                    }

                    // Tab 4: 发现
                    NavigationView {
                        DiscoverTabView()
                    }
                    .tabItem {
                        Image(systemName: "lightbulb.fill")
                        Text("发现")
                    }

                    // Tab 5: 我的
                    NavigationView {
                        ProfileTabView()
                    }
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("我的")
                    }
                }
        .accentColor(.blue) // 设置Tab选中颜色
    }
}

#Preview {
    // 创建一个模拟的UseCase用于预览
    let mockUseCase = CreateReviewItemUseCaseImpl(repository: MockReviewItemRepository())
    return MainTabView(createReviewItemUseCase: mockUseCase)
}

// 临时的Mock实现用于预览
final class MockReviewItemRepository: ReviewItemRepository {
    func createReviewItem(_ content: ReviewContent, metadata: ReviewItemMetadata) async throws -> ReviewItem {
        return ReviewItem(content: content, metadata: metadata)
    }
    
    func getReviewItems(predicate: Predicate<ReviewItem>?, sortBy: [SortDescriptor<ReviewItem>]) async throws -> [ReviewItem] {
        return []
    }
    
    func updateReviewItem(_ item: ReviewItem) async throws {
        // Mock implementation
    }
    
    func deleteReviewItem(id: UUID) async throws {
        // Mock implementation
    }
    
    func getReviewItem(id: UUID) async throws -> ReviewItem? {
        return nil
    }
}
