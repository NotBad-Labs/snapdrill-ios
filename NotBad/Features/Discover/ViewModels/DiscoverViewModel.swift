//
//  DiscoverViewModel.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/17/25.
//

import Foundation
import SwiftUI

@MainActor @Observable
class DiscoverViewModel {
    
    // MARK: - Properties
    var isLoading = false
    var recommendedLibraries: [QuestionLibrary] = []
    var communityHighlights: [CommunityContent] = []
    var activities: [Activity] = []
    var teacherRecommendations: [TeacherContent] = []
    
    // 搜索相关
    var searchText = ""
    var searchResults: [SearchResult] = []
    var isSearching = false
    
    // MARK: - Initialization
    init() {
        loadInitialData()
    }
    
    // MARK: - Public Methods
    
    /// 刷新发现页面数据
    func refresh() async {
        isLoading = true
        
        await loadRecommendedLibraries()
        await loadCommunityHighlights()
        await loadActivities()
        await loadTeacherRecommendations()
        
        isLoading = false
    }
    
    /// 搜索内容
    func search(_ query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        searchText = query
        
        // 模拟搜索延迟
        try? await Task.sleep(for: .milliseconds(500))
        
        // 模拟搜索结果
        searchResults = [
            SearchResult(id: UUID(), title: "高等数学题库", subtitle: "包含微积分、线性代数等", type: .library),
            SearchResult(id: UUID(), title: "物理力学专题", subtitle: "经典力学题目集合", type: .library),
            SearchResult(id: UUID(), title: "化学实验题", subtitle: "实验原理与操作", type: .library)
        ].filter { $0.title.contains(query) || $0.subtitle.contains(query) }
        
        isSearching = false
    }
    
    /// 打开题库
    func openLibrary(_ library: QuestionLibrary) {
        // 跳转到题库详情页
        print("打开题库: \(library.title)")
    }
    
    /// 加入活动
    func joinActivity(_ activity: Activity) {
        // 加入活动逻辑
        print("加入活动: \(activity.title)")
    }
    
    /// 关注名师
    func followTeacher(_ teacher: TeacherContent) {
        // 关注名师逻辑
        print("关注名师: \(teacher.name)")
    }
    
    // MARK: - Private Methods
    
    private func loadInitialData() {
        recommendedLibraries = [
            QuestionLibrary(
                id: UUID(),
                title: "高中数学",
                subtitle: "函数与导数",
                questionCount: 234,
                difficulty: .中等,
                color: .blue,
                isPopular: true
            ),
            QuestionLibrary(
                id: UUID(),
                title: "高中物理",
                subtitle: "力学基础",
                questionCount: 189,
                difficulty: .困难,
                color: .green,
                isPopular: false
            ),
            QuestionLibrary(
                id: UUID(),
                title: "高中化学",
                subtitle: "有机化学",
                questionCount: 156,
                difficulty: .简单,
                color: .orange,
                isPopular: true
            )
        ]
        
        // 社区功能暂未实现，保持空数组
        communityHighlights = []
        activities = []
        teacherRecommendations = []
    }
    
    private func loadRecommendedLibraries() async {
        // 模拟网络请求
        try? await Task.sleep(for: .milliseconds(600))
        
        // 更新题库数据
        recommendedLibraries = recommendedLibraries.map { library in
            QuestionLibrary(
                id: library.id,
                title: library.title,
                subtitle: library.subtitle,
                questionCount: Int.random(in: 100...300),
                difficulty: library.difficulty,
                color: library.color,
                isPopular: Bool.random()
            )
        }
    }
    
    private func loadCommunityHighlights() async {
        // 模拟网络请求
        try? await Task.sleep(for: .milliseconds(400))
        
        // 未来社区功能的占位数据
        communityHighlights = [
            CommunityContent(
                id: UUID(),
                title: "今日热门题目",
                content: "这道导数题被很多同学收藏了",
                author: "数学小助手",
                likeCount: 128,
                commentCount: 23
            )
        ]
    }
    
    private func loadActivities() async {
        // 模拟网络请求
        try? await Task.sleep(for: .milliseconds(300))
        
        // 未来活动功能的占位数据
        activities = [
            Activity(
                id: UUID(),
                title: "每日一题挑战",
                description: "连续7天完成每日题目",
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
                participantCount: 1205,
                isActive: true
            )
        ]
    }
    
    private func loadTeacherRecommendations() async {
        // 模拟网络请求
        try? await Task.sleep(for: .milliseconds(500))
        
        // 未来名师功能的占位数据
        teacherRecommendations = [
            TeacherContent(
                id: UUID(),
                name: "张老师",
                subject: "高中数学",
                title: "函数专题讲解",
                followerCount: 2340,
                isVerified: true
            )
        ]
    }
}

// MARK: - Supporting Types

struct QuestionLibrary {
    let id: UUID
    let title: String
    let subtitle: String
    let questionCount: Int
    let difficulty: Difficulty
    let color: Color
    let isPopular: Bool
}

struct CommunityContent {
    let id: UUID
    let title: String
    let content: String
    let author: String
    let likeCount: Int
    let commentCount: Int
}

struct Activity {
    let id: UUID
    let title: String
    let description: String
    let startDate: Date
    let endDate: Date
    let participantCount: Int
    let isActive: Bool
}

struct TeacherContent {
    let id: UUID
    let name: String
    let subject: String
    let title: String
    let followerCount: Int
    let isVerified: Bool
}

struct SearchResult {
    let id: UUID
    let title: String
    let subtitle: String
    let type: SearchResultType
}

enum SearchResultType {
    case library
    case community
    case teacher
    case activity
    
    var icon: String {
        switch self {
        case .library: return "books.vertical.fill"
        case .community: return "person.3.fill"
        case .teacher: return "graduationcap.fill"
        case .activity: return "party.popper.fill"
        }
    }
}