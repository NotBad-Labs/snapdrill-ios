//
//  AddQuestionViewModel.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/17/25.
//

import Foundation
import SwiftUI
import UIKit

@MainActor @Observable
class AddQuestionViewModel {
    
    // MARK: - Properties
    var isLoading = false
    var selectedInputMethod: InputMethod = .camera
    var recentQuestions: [RecentQuestion] = []
    
    // OCR相关状态
    var ocrState: OCRState = .idle
    var ocrResult: OCRResult?
    var ocrError: String?
    
    // 手动输入状态
    var questionContent = ""
    var answerContent = ""
    var wrongReason = ""
    var selectedTags: [String] = []
    var selectedDifficulty: Difficulty = .中等
    
    // MARK: - Initialization
    init() {
        loadRecentQuestions()
    }
    
    // MARK: - Public Methods
    
    /// 选择输入方式
    func selectInputMethod(_ method: InputMethod) {
        selectedInputMethod = method
    }
    
    /// 处理拍照结果
    func processCameraImage(_ image: UIImage) async {
        ocrState = .processing
        ocrError = nil
        
        do {
            let result = try await performOCR(on: image)
            ocrResult = result
            ocrState = .completed
            
            // 自动填充识别结果
            if let content = result.questionContent {
                questionContent = content
            }
            if let answer = result.answerContent {
                answerContent = answer
            }
            
        } catch {
            ocrError = error.localizedDescription
            ocrState = .failed
        }
    }
    
    /// 保存题目
    func saveQuestion() async -> Bool {
        guard !questionContent.isEmpty else {
            return false
        }
        
        isLoading = true
        
        // 模拟保存过程
        try? await Task.sleep(for: .milliseconds(800))
        
        // 创建新的Question对象（这里需要实际的数据层实现）
        let newQuestion = Question(
            content: questionContent,
            answer: answerContent,
            tags: selectedTags,
            wrongReason: wrongReason.isEmpty ? nil : wrongReason,
            difficulty: selectedDifficulty,
            isOCRGenerated: selectedInputMethod == .camera,
            ocrRawText: ocrResult?.rawText
        )
        
        // TODO: 保存到数据库
        print("保存题目: \(newQuestion.content)")
        
        // 重置状态
        resetInputState()
        
        isLoading = false
        return true
    }
    
    /// 重置输入状态
    func resetInputState() {
        questionContent = ""
        answerContent = ""
        wrongReason = ""
        selectedTags = []
        selectedDifficulty = .中等
        ocrResult = nil
        ocrState = .idle
        ocrError = nil
    }
    
    /// 重试OCR
    func retryOCR() async {
        guard let result = ocrResult else { return }
        
        ocrState = .processing
        ocrError = nil
        
        // 重新处理OCR结果
        try? await Task.sleep(for: .milliseconds(500))
        ocrState = .completed
    }
    
    // MARK: - Private Methods
    
    private func loadRecentQuestions() {
        // 模拟最近添加的题目
        recentQuestions = [
            RecentQuestion(id: UUID(), title: "解方程：x² + 2x - 3 = 0", timeAgo: "2小时前"),
            RecentQuestion(id: UUID(), title: "求导数：f(x) = x³ + 2x", timeAgo: "昨天"),
            RecentQuestion(id: UUID(), title: "化简：√(x² + 4x + 4)", timeAgo: "3天前"),
            RecentQuestion(id: UUID(), title: "计算极限：lim(x→0) sinx/x", timeAgo: "1周前")
        ]
    }
    
    private func performOCR(on image: UIImage) async throws -> OCRResult {
        // 模拟OCR处理
        try await Task.sleep(for: .milliseconds(2000))
        
        // 模拟OCR结果
        return OCRResult(
            rawText: "解方程：x² + 2x - 3 = 0\n答案：x = 1 或 x = -3\n解析：使用因式分解法",
            questionContent: "解方程：x² + 2x - 3 = 0",
            answerContent: "x = 1 或 x = -3",
            confidence: 0.85,
            hasFormulas: true,
            hasCharts: false
        )
    }
}

// MARK: - Supporting Types

enum InputMethod: String, CaseIterable {
    case camera = "camera"
    case manual = "manual"
    
    var title: String {
        switch self {
        case .camera: return "拍照识别"
        case .manual: return "手动录入"
        }
    }
    
    var icon: String {
        switch self {
        case .camera: return "camera.fill"
        case .manual: return "square.and.pencil"
        }
    }
}

enum OCRState {
    case idle
    case processing
    case completed
    case failed
    
    var isProcessing: Bool {
        return self == .processing
    }
}

struct OCRResult {
    let rawText: String
    let questionContent: String?
    let answerContent: String?
    let confidence: Double
    let hasFormulas: Bool
    let hasCharts: Bool
    
    var needsReview: Bool {
        return confidence < 0.8
    }
}

struct RecentQuestion {
    let id: UUID
    let title: String
    let timeAgo: String
}