//
//  ReviewItemFormViewModel.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import Foundation
import Observation

// MARK: - ReviewItemFormViewModel

/// 错题表单视图模型
///
/// 负责管理表单字段、数据校验和智能填充。
@MainActor
@Observable
final class ReviewItemFormViewModel {
    
    // MARK: - Form Fields
    
    var title: String = ""
    var note: String = ""
    var subject: Subject = .math
    var grade: Grade = .grade10 // 默认值，稍后会从 UserDefaults 读取
    var knowledgePointsInput: String = ""
    var difficulty: Difficulty = .medium
    var errorType: ErrorType = .other
    var source: Source = .other
    var reviewItemType: ReviewItemType = .other
    
    // MARK: - Smart Analysis State
    
    var isAnalyzing: Bool = false
    var smartAnalysisAvailable: Bool = false
    var suggestedSubject: Subject?
    var subjectWasAutoSelected: Bool = false
    
    // MARK: - Dependencies
    
    private let smartAnalysisService = SmartAnalysisService.shared
    
    // MARK: - Initialization
    
    init() {
        self.grade = Self.getUserDefaultGrade()
        self.smartAnalysisAvailable = smartAnalysisService.isAvailable
    }
    
    // MARK: - Actions
    
    /// 自动填充表单（基于 OCR 文本）
    func autoFill(with text: String) {
        // 1. 简单的标题提取（取第一行）
        let lines = text.components(separatedBy: .newlines)
        if let firstLine = lines.first(where: { !$0.isEmpty }) {
            // 限制标题长度
            self.title = String(firstLine.prefix(50))
        }
        
        // 2. 智能分析（如果可用）
        if smartAnalysisAvailable {
            analyzeText(text)
        }
    }
    
    /// 执行智能分析
    private func analyzeText(_ text: String) {
        isAnalyzing = true
        
        Task {
            // 模拟智能分析延迟
            try? await Task.sleep(for: .milliseconds(500))
            
            // 简单的关键词匹配规则 (Mock AI)
            if text.contains("sin") || text.contains("cos") || text.contains("函数") {
                self.suggestedSubject = .math
                self.subject = .math
                self.subjectWasAutoSelected = true
            } else if text.contains("apple") || text.contains("grammar") {
                self.suggestedSubject = .english
                self.subject = .english
                self.subjectWasAutoSelected = true
            }
            
            self.isAnalyzing = false
        }
    }
    
    /// 添加知识点
    func addKnowledgePoint(_ point: String) {
        let trimmed = point.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if knowledgePointsInput.isEmpty {
            knowledgePointsInput = trimmed
        } else {
            knowledgePointsInput += ", \(trimmed)"
        }
    }
    
    /// 重置表单
    func reset() {
        title = ""
        note = ""
        subject = .math
        grade = Self.getUserDefaultGrade()
        knowledgePointsInput = ""
        difficulty = .medium
        errorType = .other
        source = .other
        reviewItemType = .other
        suggestedSubject = nil
        subjectWasAutoSelected = false
    }
    
    // MARK: - Computed Properties
    
    /// 解析的知识点列表
    var parsedKnowledgePoints: KnowledgePoints {
        KnowledgePoints(from: knowledgePointsInput)
    }
    
    /// 知识点数组（用于 UseCase）
    var knowledgePointsArray: [String] {
        parsedKnowledgePoints.items
    }
    
    // MARK: - Helpers
    
    static func getUserDefaultGrade() -> Grade {
        let gradeCode = UserDefaults.standard.string(forKey: "defaultGrade") ?? Grade.grade7.rawValue
        return Grade(rawValue: gradeCode) ?? .grade7
    }
}
