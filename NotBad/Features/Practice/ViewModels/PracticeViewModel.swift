//
//  PracticeViewModel.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/17/25.
//

import Foundation
import SwiftUI

@MainActor @Observable
class PracticeViewModel {
    
    // MARK: - Properties
    var isLoading = false
    var selectedPracticeMode: PracticeMode = .mistakeBook
    var mistakeBookStats = MistakeBookStats()
    var tagStats: [TagStat] = []
    var testHistory: [TestRecord] = []
    
    // MARK: - Initialization
    init() {
        loadInitialData()
    }
    
    // MARK: - Public Methods
    
    /// 刷新练习数据
    func refresh() async {
        isLoading = true
        
        await loadMistakeBookStats()
        await loadTagStats()
        await loadTestHistory()
        
        isLoading = false
    }
    
    /// 选择练习模式
    func selectPracticeMode(_ mode: PracticeMode) {
        selectedPracticeMode = mode
    }
    
    /// 开始错题练习
    func startMistakePractice() {
        // 启动错题练习流程
        print("开始错题练习")
    }
    
    /// 开始标签练习
    func startTagPractice(tag: String) {
        // 启动标签练习流程
        print("开始标签练习: \(tag)")
    }
    
    /// 开始随机测验
    func startRandomTest() {
        // 启动随机测验流程
        print("开始随机测验")
    }
    
    // MARK: - Private Methods
    
    private func loadInitialData() {
        mistakeBookStats = MistakeBookStats(
            totalMistakes: 23,
            needReview: 15,
            mastered: 8
        )
        
        tagStats = [
            TagStat(name: "数学", count: 45, accuracy: 0.72),
            TagStat(name: "物理", count: 32, accuracy: 0.68),
            TagStat(name: "化学", count: 28, accuracy: 0.81),
            TagStat(name: "语文", count: 51, accuracy: 0.85)
        ]
        
        testHistory = [
            TestRecord(date: Date(), questionsCount: 10, correctCount: 8, duration: 450),
            TestRecord(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, questionsCount: 15, correctCount: 12, duration: 680),
            TestRecord(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, questionsCount: 20, correctCount: 14, duration: 890)
        ]
    }
    
    private func loadMistakeBookStats() async {
        // 模拟网络请求
        try? await Task.sleep(for: .milliseconds(400))
        mistakeBookStats = MistakeBookStats(
            totalMistakes: Int.random(in: 15...30),
            needReview: Int.random(in: 8...20),
            mastered: Int.random(in: 5...15)
        )
    }
    
    private func loadTagStats() async {
        // 模拟网络请求
        try? await Task.sleep(for: .milliseconds(500))
        tagStats = [
            TagStat(name: "数学", count: Int.random(in: 30...50), accuracy: Double.random(in: 0.6...0.9)),
            TagStat(name: "物理", count: Int.random(in: 25...40), accuracy: Double.random(in: 0.6...0.9)),
            TagStat(name: "化学", count: Int.random(in: 20...35), accuracy: Double.random(in: 0.6...0.9)),
            TagStat(name: "语文", count: Int.random(in: 40...60), accuracy: Double.random(in: 0.6...0.9))
        ]
    }
    
    private func loadTestHistory() async {
        // 模拟网络请求
        try? await Task.sleep(for: .milliseconds(300))
        // 保持现有数据，实际应用中会从数据库加载
    }
}

// MARK: - Supporting Types

enum PracticeMode: String, CaseIterable {
    case mistakeBook = "mistake_book"
    case tagBased = "tag_based"
    case randomTest = "random_test"
    
    var title: String {
        switch self {
        case .mistakeBook: return "错题本"
        case .tagBased: return "标签练习"
        case .randomTest: return "随机测验"
        }
    }
    
    var icon: String {
        switch self {
        case .mistakeBook: return "exclamationmark.triangle.fill"
        case .tagBased: return "tag.fill"
        case .randomTest: return "shuffle"
        }
    }
    
    var color: Color {
        switch self {
        case .mistakeBook: return .red
        case .tagBased: return .orange
        case .randomTest: return .purple
        }
    }
}

struct MistakeBookStats {
    let totalMistakes: Int
    let needReview: Int
    let mastered: Int
    
    init(totalMistakes: Int = 0, needReview: Int = 0, mastered: Int = 0) {
        self.totalMistakes = totalMistakes
        self.needReview = needReview
        self.mastered = mastered
    }
}

struct TagStat {
    let name: String
    let count: Int
    let accuracy: Double
    
    init(name: String, count: Int, accuracy: Double) {
        self.name = name
        self.count = count
        self.accuracy = accuracy
    }
}

struct TestRecord {
    let date: Date
    let questionsCount: Int
    let correctCount: Int
    let duration: Int // 秒
    
    var accuracy: Double {
        return Double(correctCount) / Double(questionsCount)
    }
    
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}