import SwiftUI

// MARK: - DashboardView
// 位置: Presentation/Features/Dashboard/Views/DashboardView.swift

/// Dashboard首页视图
/// 负责组合各个Dashboard组件，处理主要的导航和状态管理
struct DashboardView: View {
    
    // MARK: - Properties
    
    @State private var viewModel = DashboardViewModel()
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                
                // 欢迎头部组件
                WelcomeHeader(
                    userInfo: viewModel.userInfo,
                    weatherInfo: WeatherInfo.mockData, // 临时使用mock数据
                    onWeatherTap: {
                        // TODO: 处理天气点击事件
                        print("天气区域被点击")
                    }
                )
                
                // 今日统计组件
                TodayStatsSection()
                
                // 快速操作组件
                QuickActionsSection()
                
                // 今日推荐组件
                TodayRecommendationSection()
                
                // 最近活动组件
                RecentActivitySection()
                
                // 底部间距，为Tab Bar留出空间
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .navigationTitle("首页")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .refreshable {
            await viewModel.refreshData()
        }
        .overlay {
            if viewModel.isLoading && viewModel.userInfo == nil {
                DashboardLoadingView()
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
            await viewModel.refreshData()
        }
    }
}

// MARK: - 临时占位组件
// TODO: 用实际组件替换剩余的占位视图

/// 欢迎头部占位视图 - 已替换为WelcomeHeader组件
// private struct WelcomeHeaderPlaceholder: View { ... }

/// 今日统计区域组件
private struct TodayStatsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("今日统计")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                // 使用真正的StatCard组件和mock数据
                ForEach(StatCardData.mockData) { statData in
                    StatCard(
                        title: statData.title,
                        value: statData.value,
                        trend: statData.trend,
                        icon: statData.icon,
                        color: statData.color,
                        onTap: {
                            // TODO: 处理统计卡片点击事件
                            print("\(statData.title)卡片被点击")
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

/// 今日统计占位视图 - 已替换为StatCard组件
// private struct TodayStatsPlaceholder: View { ... }

/// 快速操作区域组件
private struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("快速操作")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                // 使用真正的QuickActionCard组件和mock数据
                ForEach(QuickActionData.mockData) { actionData in
                    QuickActionCard(
                        title: actionData.title,
                        icon: actionData.icon,
                        color: actionData.color,
                        isEnabled: actionData.isEnabled,
                        onTap: {
                            handleQuickAction(actionData.actionType)
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    /// 处理快速操作点击
    private func handleQuickAction(_ actionType: QuickActionData.ActionType) {
        switch actionType {
        case .captureQuestion:
            print("跳转到拍照录题")
            // TODO: 导航到相机页面
        case .startPractice:
            print("跳转到开始练习")
            // TODO: 导航到练习页面
        case .viewAnalytics:
            print("跳转到查看分析")
            // TODO: 导航到分析页面
        case .reviewMistakes:
            print("跳转到错题复习")
            // TODO: 导航到复习页面
        }
    }
}

/// 快速操作占位视图 - 已替换为QuickActionCard组件
// private struct QuickActionsPlaceholder: View { ... }

/// 快速操作卡片占位视图 - 已替换为QuickActionCard组件
// private struct QuickActionPlaceholderCard: View { ... }

/// 今日推荐区域组件
private struct TodayRecommendationSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏
            HStack {
                Text("今日推荐")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("查看全部") {
                    // TODO: 导航到推荐页面
                    print("查看全部推荐")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            // 推荐卡片列表
            VStack(spacing: 12) {
                ForEach(RecommendationData.mockData) { recommendationData in
                    RecommendationCard(
                        subject: recommendationData.subject,
                        topic: recommendationData.topic,
                        questionCount: recommendationData.questionCount,
                        difficulty: recommendationData.difficulty,
                        estimatedMinutes: recommendationData.estimatedMinutes,
                        onTap: {
                            handleRecommendationTap(recommendationData)
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    /// 处理推荐卡片点击
    private func handleRecommendationTap(_ recommendation: RecommendationData) {
        print("推荐被点击: \(recommendation.subject) - \(recommendation.topic)")
        // TODO: 导航到具体的推荐练习页面
    }
}

/// 今日推荐占位视图 - 已替换为RecommendationCard组件
// private struct TodayRecommendationPlaceholder: View { ... }

/// 推荐卡片占位视图 - 已替换为RecommendationCard组件
// private struct RecommendationPlaceholderCard: View { ... }

/// 最近活动区域组件
private struct RecentActivitySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("最近活动")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(ActivityData.mockData.prefix(3)) { activityData in
                    ActivityCard(
                        activityType: activityData.activityType,
                        subject: activityData.subject,
                        description: activityData.description,
                        timestamp: activityData.timestamp,
                        score: activityData.score,
                        onTap: {
                            handleActivityTap(activityData)
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    /// 处理活动卡片点击
    private func handleActivityTap(_ activity: ActivityData) {
        print("活动被点击: \(activity.subject) - \(activity.description)")
        // TODO: 根据活动类型导航到相应页面
        switch activity.activityType {
        case .questionAdded:
            print("导航到题目详情")
        case .studyCompleted:
            print("导航到学习记录")
        case .achievementUnlocked:
            print("导航到成就页面")
        case .reviewCompleted:
            print("导航到复习记录")
        case .practiceStarted:
            print("导航到练习记录")
        }
    }
}

/// 最近活动占位视图 - 已替换为ActivityCard组件
// private struct RecentActivityPlaceholder: View { ... }

/// 活动卡片占位视图 - 已替换为ActivityCard组件
// private struct ActivityPlaceholderCard: View { ... }

/// 加载视图
private struct DashboardLoadingView: View {
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
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
#endif