//
//  HomeViewModel.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/17/25.
//

import Foundation
import SwiftUI

@MainActor @Observable
class HomeViewModel {
    
    // MARK: - Properties
    var isLoading = false
    var greetingMessage = ""
    var todayProgress: Double = 0.0
    var quickStats = QuickStats()
    
    // MARK: - Initialization
    init() {
        loadInitialData()
    }
    
    // MARK: - Public Methods
    
    /// 刷新首页数据
    func refresh() async {
        isLoading = true
        
        // 模拟异步数据加载
        await loadGreetingMessage()
        await loadTodayProgress()
        await loadQuickStats()
        
        isLoading = false
    }
    
    /// 获取问候消息
    func getGreetingMessage() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 6..<12:
            return "早上好，开始新的学习吧！"
        case 12..<18:
            return "下午好，继续努力学习！"
        case 18..<22:
            return "晚上好，复习一下今天的内容吧！"
        default:
            return "夜深了，早点休息哦！"
        }
    }
    
    // MARK: - Private Methods
    
    private func loadInitialData() {
        greetingMessage = getGreetingMessage()
        todayProgress = 0.65 // 示例数据
        quickStats = QuickStats(
            totalQuestions: 156,
            reviewedToday: 12,
            correctRate: 0.78,
            streakDays: 23
        )
    }
    
    private func loadGreetingMessage() async {
        // 模拟网络请求
        try? await Task.sleep(for: .milliseconds(500))
        greetingMessage = getGreetingMessage()
    }
    
    private func loadTodayProgress() async {
        // 模拟网络请求
        try? await Task.sleep(for: .milliseconds(300))
        todayProgress = Double.random(in: 0.4...0.9)
    }
    
    private func loadQuickStats() async {
        // 模拟网络请求
        try? await Task.sleep(for: .milliseconds(400))
        quickStats = QuickStats(
            totalQuestions: Int.random(in: 100...200),
            reviewedToday: Int.random(in: 5...20),
            correctRate: Double.random(in: 0.6...0.95),
            streakDays: Int.random(in: 1...50)
        )
    }
}

// MARK: - Supporting Types

struct QuickStats {
    let totalQuestions: Int
    let reviewedToday: Int
    let correctRate: Double
    let streakDays: Int
    
    init(totalQuestions: Int = 0, reviewedToday: Int = 0, correctRate: Double = 0.0, streakDays: Int = 0) {
        self.totalQuestions = totalQuestions
        self.reviewedToday = reviewedToday
        self.correctRate = correctRate
        self.streakDays = streakDays
    }
}