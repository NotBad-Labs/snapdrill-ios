//
//  StudySessionViewModel.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/8/1.
//


//
//  StudySessionViewModel.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/8/1.
//

import Foundation
import SwiftUI

/// 学习会话视图模型
///
/// 职责：
/// - 管理学习会话中的所有数据和业务逻辑
/// - 负责题目的加载、进度的更新、答案的显示和反馈处理
/// - 作为一个 ObservableObject，向 View 发布状态变化
@MainActor
final class StudySessionViewModel: ObservableObject {
    
    // MARK: - 发布状态
    
    /// 当前练习的题目索引
    @Published var currentQuestionIndex: Int = 0
    
    /// 总题目数
    @Published var totalQuestions: Int = 10
    
    /// 当前题目的内容（模拟）
    @Published var questionText: String = "这里是题目内容。我们将在这里展示具体的错题，例如：\n\n“下面哪个选项是正确的？\n\nA. 选项A\nB. 选项B\nC. 选项C\nD. 选项D”\n\n这个问题很长，所以我们需要确保这里可以滚动，以便用户能够看到完整内容。"
    
    /// 当前题目的答案和解析（模拟）
    @Published var answerText: String = "这里是答案内容和详细解析。当用户点击“显示答案”后，我们会在这里展示正确选项和解题思路。"
    
    /// 答案是否已显示
    @Published var isAnswerShown: Bool = false
    
    // MARK: - 初始化
    
    init() {
        // 在 ViewModel 初始化时，可以进行一些数据加载或准备工作
        startSession()
    }
    
    // MARK: - 公共方法
    
    /// 开始一个新的练习会话
    func startSession() {
        // TODO: 从服务层获取题目列表并加载第一题
        self.currentQuestionIndex = 0
        self.totalQuestions = 10 // 模拟总题目数
        self.isAnswerShown = false
        // ... 加载第一题的题目和答案
    }
    
    /// 切换到下一题
    private func nextQuestion() {
        guard currentQuestionIndex < totalQuestions - 1 else {
            // TODO: 处理会话结束的逻辑
            return
        }
        
        withAnimation(.easeInOut) {
            currentQuestionIndex += 1
            isAnswerShown = false
            // TODO: 加载下一题的题目和答案
        }
    }
    
    /// 切换答案的显示状态
    func showAnswer() {
        guard !isAnswerShown else { return }
        withAnimation(.easeInOut) {
            isAnswerShown = true
        }
    }
    
    /// 用户标记为答对
    func markAsCorrect() {
        // TODO: 调用服务层记录答题结果（正确）
        nextQuestion()
    }
    
    /// 用户标记为答错
    func markAsIncorrect() {
        // TODO: 调用服务层记录答题结果（错误）
        nextQuestion()
    }
}
