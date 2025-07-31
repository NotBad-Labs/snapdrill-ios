import SwiftUI

// MARK: - StudyPracticeView
// 位置: Presentation/Features/StudyPractice/Views/StudyPracticeView.swift

/// StudyPractice学习练习主视图
/// 负责组合各个StudyPractice组件，处理主要的学习状态管理
struct StudyPracticeView: View {
    
    // MARK: - Properties
    
    @State private var viewModel = StudyPracticeViewModel()
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                
                // 学习状态卡片
                StudyStatusCard(
                    isStudying: viewModel.isStudying,
                    studyTimeSeconds: viewModel.studyTimeSeconds,
                    onStart: {
                        viewModel.startStudy()
                    },
                    onPause: {
                        viewModel.pauseStudy()
                    },
                    onResume: {
                        viewModel.resumeStudy()
                    },
                    onEnd: {
                        viewModel.endStudy()
                    },
                    onReset: {
                        viewModel.resetStudyTime()
                    }
                )
                
                // 学习模式选择
                StudyModeSelectionSection(viewModel: viewModel)
                
                // 学习历史记录
                StudyHistorySection()
                
                // 底部间距，为Tab Bar留出空间
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .navigationTitle("练习")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .refreshable {
            await viewModel.refreshData()
        }
        .overlay {
            // 只在初次加载且没有数据时显示加载界面
            if viewModel.isLoading && !viewModel.hasInitialData {
                StudyPracticeLoadingView()
            }
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .task {
            // 只在首次显示时加载数据
            if !viewModel.hasInitialData {
                await viewModel.refreshData()
            }
        }
    }
}

// MARK: - 临时占位组件
// TODO: 用实际组件替换这些占位视图

/// 学习状态占位视图 - 已替换为StudyStatusCard组件
// private struct StudyStatusPlaceholder: View { ... }

/// 学习模式选择区域组件
private struct StudyModeSelectionSection: View {
    @Bindable var viewModel: StudyPracticeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("学习模式")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(StudyMode.allModes) { mode in
                    StudyModeCard(
                        studyMode: mode,
                        onTap: {
                            viewModel.selectStudyMode(mode)
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

/// 学习模式选择占位视图 - 已替换为StudyModeCard组件
// private struct StudyModeSelectionPlaceholder: View { ... }

/// 学习模式卡片占位视图 - 已替换为StudyModeCard组件
// private struct StudyModePlaceholderCard: View { ... }

/// 学习历史区域组件
private struct StudyHistorySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("最近学习记录")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("查看全部") {
                    // TODO: 导航到完整的学习历史页面
                    print("查看全部学习记录")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                // 只显示前3条记录
                ForEach(StudyHistoryData.mockData.prefix(3)) { historyData in
                    StudyHistoryCard(
                        dateDescription: historyData.dateDescription,
                        duration: historyData.durationDescription,
                        questionCount: historyData.questionCount,
                        score: historyData.score,
                        studyMode: historyData.studyModeDescription,
                        onTap: {
                            handleHistoryTap(historyData)
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    /// 处理历史记录点击
    private func handleHistoryTap(_ history: StudyHistoryData) {
        print("学习记录被点击: \(history.dateDescription) - \(history.score)分")
        // TODO: 导航到学习记录详情页面
    }
}

/// 学习历史占位视图 - 已替换为StudyHistoryCard组件
// private struct StudyHistoryPlaceholder: View { ... }

/// 学习历史卡片占位视图 - 已替换为StudyHistoryCard组件
// private struct StudyHistoryPlaceholderCard: View { ... }

/// StudyPractice加载视图
private struct StudyPracticeLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("加载中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

// MARK: - Preview

#if DEBUG
struct StudyPracticeView_Previews: PreviewProvider {
    static var previews: some View {
        StudyPracticeView()
    }
}
#endif