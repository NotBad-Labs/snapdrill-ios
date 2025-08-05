//
//  StudySessionView.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/8/1.
//

import SwiftUI

/// 学习会话主视图
///
/// 职责：
/// - 显示当前题目内容和答案
/// - 提供用户交互控件（显示答案、标记答题结果、切换题目）
/// - 通过 `StudySessionViewModel` 响应式地更新 UI
///
/// 架构说明：
/// - 作为视图层，它只负责展示，不包含业务逻辑
/// - 通过 `@StateObject` 实例化并持有 `ViewModel`
/// - 通过 `@ObservedObject` 监听 `ViewModel` 的状态变化
struct StudySessionView: View {
    
    // MARK: - 依赖注入
    
    /// 学习会话视图模型
    /// `@StateObject` 用于在视图生命周期内创建和持有 ViewModel
    @StateObject private var viewModel = StudySessionViewModel()
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // 背景色
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: Layout.padding) {
                // 进度条和导航栏标题
                progressHeader
                
                // 题目内容区域
                questionContent
                
                // 答案和操作按钮区域
                answerAndControls
            }
            .padding(.horizontal, Layout.padding)
        }
    }
    
    // MARK: - 子视图
    
    /// 进度条和导航栏标题
    private var progressHeader: some View {
        HStack {
            Text("学习会话")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            // 进度文本
            Text("\(viewModel.currentQuestionIndex + 1) / \(viewModel.totalQuestions)")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    /// 题目内容区域
    private var questionContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.padding) {
                // 题目文本
                Text(viewModel.questionText)
                    .font(.system(size: Layout.questionFontSize, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                
                // 答案区域，根据状态显示或隐藏
                if viewModel.isAnswerShown {
                    Text(viewModel.answerText)
                        .font(.system(size: Layout.answerFontSize))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(Layout.buttonCornerRadius)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(Layout.buttonCornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    /// 答案和操作按钮区域
    private var answerAndControls: some View {
        VStack(spacing: Layout.buttonSpacing) {
            if !viewModel.isAnswerShown {
                // 显示答案按钮
                ActionButton(
                    title: "查看答案",
                    icon: "eye.fill",
                    color: .blue
                ) {
                    viewModel.showAnswer()
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                // 答题结果按钮
                HStack(spacing: Layout.buttonSpacing) {
                    // 答错按钮
                    ActionButton(
                        title: "答错了",
                        icon: "xmark.circle.fill",
                        color: .red
                    ) {
                        viewModel.markAsIncorrect()
                    }
                    
                    // 答对按钮
                    ActionButton(
                        title: "答对了",
                        icon: "checkmark.circle.fill",
                        color: .green
                    ) {
                        viewModel.markAsCorrect()
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical)
        .animation(.easeInOut, value: viewModel.isAnswerShown)
    }
}

// MARK: - 辅助视图

/// 布局常量
/// 因为需要被 `StudySessionView` 和 `ActionButton` 两个结构体使用，所以定义为 `fileprivate`
fileprivate struct Layout {
    static let buttonSpacing: CGFloat = 16
    static let buttonHeight: CGFloat = 50
    static let buttonCornerRadius: CGFloat = 12
    static let padding: CGFloat = 20
    static let questionFontSize: CGFloat = 20
    static let answerFontSize: CGFloat = 18
}

/// 自定义操作按钮
private struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Layout.buttonHeight)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(Layout.buttonCornerRadius)
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - 预览
#if DEBUG
struct StudySessionView_Previews: PreviewProvider {
    static var previews: some View {
        StudySessionView()
    }
}
#endif

