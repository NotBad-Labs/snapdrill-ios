//
//  DiscoveryViewModel.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/7/31.
//


import SwiftUI
import Foundation

// MARK: - DiscoveryViewModel
// 位置: Presentation/Features/Discovery/ViewModels/DiscoveryViewModel.swift

/// Discovery发现页面视图模型
/// 负责管理发现页面的状态和业务逻辑
/// TODO: 架构重构 - 将业务逻辑迁移到Use Cases，数据模型迁移到Domain层
@MainActor
@Observable
class DiscoveryViewModel {
    
    // MARK: - Published Properties
    
    /// 加载状态
    var isLoading: Bool = false
    
    /// 错误信息
    var errorMessage: String?
    
    /// 搜索关键词
    var searchText: String = ""
    
    /// 热门话题列表
    var hotTopics: [HotTopic] = []
    
    /// 推荐内容列表
    var recommendedContent: [FeedItem] = []
    
    /// 是否已有初始数据（避免重复加载）
    var hasInitialData: Bool = false
    
    // MARK: - Dependencies
    // TODO: 架构重构 - 注入Use Cases和Repository
    // private let getDiscoveryDataUseCase: GetDiscoveryDataUseCase
    // private let searchContentUseCase: SearchContentUseCase
    // private let discoveryRepository: DiscoveryRepository
    
    // MARK: - Initialization
    
    init() {
        setupInitialData()
    }
    
    // MARK: - Public Methods
    
    /// 刷新页面数据
    func refreshData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 模拟数据加载
            try await Task.sleep(nanoseconds: 800_000_000) // 0.8秒
            
            // TODO: 架构重构 - 调用GetDiscoveryDataUseCase
            async let topicsTask = loadHotTopics()
            async let contentTask = loadRecommendedContent()
            
            let (topics, content) = await (topicsTask, contentTask)
            hotTopics = topics
            recommendedContent = content
            
            // 标记已有初始数据
            hasInitialData = true
            
        } catch {
            errorMessage = "数据加载失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 搜索内容
    func searchContent() async {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            print("搜索内容为空")
            return
        }
        
        isLoading = true
        print("开始搜索内容: \(trimmedText)")
        
        do {
            // 模拟搜索延迟
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            
            // TODO: 架构重构 - 调用SearchContentUseCase
            print("搜索完成: \(trimmedText)")
            // TODO: 导航到搜索结果页面
            
        } catch {
            errorMessage = "搜索失败: \(error.localizedDescription)"
            print("搜索出错: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// 选择热门话题
    func selectHotTopic(_ topic: HotTopic) {
        print("选择热门话题: \(topic.name)")
        // TODO: 架构重构 - 调用相关用例
        // TODO: 导航到话题详情页面
    }
    
    /// 查看推荐内容详情
    func viewContentDetail(_ item: FeedItem) {
        print("查看内容详情: \(item.title)")
        // TODO: 架构重构 - 调用相关用例
        // TODO: 导航到内容详情页面
    }
    
    /// 点赞内容
    func likeContent(_ item: FeedItem) {
        if let index = recommendedContent.firstIndex(where: { $0.id == item.id }) {
            recommendedContent[index].isLiked.toggle()
            if recommendedContent[index].isLiked {
                recommendedContent[index].likeCount += 1
            } else {
                recommendedContent[index].likeCount -= 1
            }
        }
        
        print("点赞内容: \(item.title), 当前状态: \(item.isLiked)")
        // TODO: 架构重构 - 调用LikeContentUseCase
    }
    
    // MARK: - Private Methods
    
    /// 设置初始数据
    private func setupInitialData() {
        // 设置默认数据，避免空白页面
        hotTopics = HotTopic.mockData
        recommendedContent = FeedItem.mockData
        
        // 标记已有基础数据，避免不必要的加载
        hasInitialData = true
    }
    
    /// 加载热门话题
    private func loadHotTopics() async -> [HotTopic] {
        // TODO: 架构重构 - 通过Repository获取数据
        return HotTopic.mockData
    }
    
    /// 加载推荐内容
    private func loadRecommendedContent() async -> [FeedItem] {
        // TODO: 架构重构 - 通过Repository获取数据
        return FeedItem.mockData
    }
}

// MARK: - 简化的数据模型
// TODO: 架构重构 - 将这些模型迁移到Core/Domain/Entities/

/// 热门话题
struct HotTopic: Identifiable {
    let id = UUID()
    let name: String
    let postCount: Int
    let isFollowing: Bool
    
    static let mockData: [HotTopic] = [
        HotTopic(name: "数学函数", postCount: 1234, isFollowing: false),
        HotTopic(name: "英语语法", postCount: 856, isFollowing: true),
        HotTopic(name: "物理力学", postCount: 692, isFollowing: false),
        HotTopic(name: "化学方程式", postCount: 445, isFollowing: false),
        HotTopic(name: "历史事件", postCount: 328, isFollowing: true),
        HotTopic(name: "地理知识", postCount: 267, isFollowing: false)
    ]
}

/// 动态内容项
struct FeedItem: Identifiable {
    let id = UUID()
    let author: Author
    let title: String
    let content: String
    let tags: [String]
    var likeCount: Int
    let commentCount: Int
    let timestamp: Date
    var isLiked: Bool
    
    struct Author {
        let name: String
        let avatar: String
        let isVerified: Bool
    }
    
    static let mockData: [FeedItem] = [
        FeedItem(
            author: Author(name: "学霸小王", avatar: "👨‍🎓", isVerified: true),
            title: "二次函数解题技巧分享",
            content: "分享一道有趣的数学题：如何用最少的步骤解决这个函数问题。关键在于找到对称轴和顶点坐标...",
            tags: ["数学", "函数"],
            likeCount: 128,
            commentCount: 24,
            timestamp: Date().addingTimeInterval(-2 * 3600), // 2小时前
            isLiked: false
        ),
        FeedItem(
            author: Author(name: "英语达人", avatar: "👩‍🏫", isVerified: true),
            title: "常见英语语法错误总结",
            content: "整理了一些常见的英语语法错误，希望对大家有帮助！包括时态使用、介词搭配、句型结构等...",
            tags: ["英语", "语法"],
            likeCount: 89,
            commentCount: 15,
            timestamp: Date().addingTimeInterval(-4 * 3600), // 4小时前
            isLiked: true
        ),
        FeedItem(
            author: Author(name: "物理爱好者", avatar: "🔬", isVerified: false),
            title: "生活中的物理现象",
            content: "用生活中的例子来理解牛顿定律，原来物理可以这么有趣！比如坐电梯时的失重感...",
            tags: ["物理", "牛顿定律"],
            likeCount: 156,
            commentCount: 32,
            timestamp: Date().addingTimeInterval(-6 * 3600), // 6小时前
            isLiked: false
        ),
        FeedItem(
            author: Author(name: "化学小助手", avatar: "⚗️", isVerified: true),
            title: "有机化学记忆口诀",
            content: "分享一些有机化学的记忆技巧和口诀，让复杂的化学方程式变得简单易记...",
            tags: ["化学", "有机化学"],
            likeCount: 203,
            commentCount: 45,
            timestamp: Date().addingTimeInterval(-12 * 3600), // 12小时前
            isLiked: true
        )
    ]
}