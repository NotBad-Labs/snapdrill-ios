//
//  ReviewView.swift
//  NotBad
//
//  复习视图 - iOS 26 现代化设计
//

import SwiftUI
import SwiftData

// MARK: - ReviewView

/// 复习视图
///
/// 提供卡片式复习界面，用户可以通过滑动浏览需要复习的错题，
/// 并根据掌握程度进行自我评估。
///
/// ## 功能特性
///
/// - 卡片式错题浏览
/// - 自我评估（不会/模糊/掌握）
/// - 复习进度追踪
/// - 复习完成统计
///
/// ## 使用示例
///
/// ```swift
/// ReviewView()
///     .modelContainer(for: ReviewItem.self)
/// ```
///
/// ## 复习算法
///
/// 根据用户的自我评估更新掌握度：
/// - 不会：掌握度重置为"未掌握"
/// - 模糊：掌握度设为"一知半解"
/// - 掌握：掌握度提升到"完全掌握"
struct ReviewView: View {
    
    // MARK: - Properties
    
    /// 所有错题数据
    @Query(sort: \ReviewItem.createdAt, order: .reverse)
    private var allItems: [ReviewItem]
    
    /// 数据上下文
    @Environment(\.modelContext) private var modelContext
    
    /// 视图模型
    @State private var viewModel = ReviewViewModel()
    
    // MARK: - Computed Properties
    
    /// 需要复习的错题
    private var reviewItems: [ReviewItem] {
        viewModel.generateReviewQueue(from: allItems)
    }
    
    // MARK: - Body
    
    var body: some View {
        @Bindable var bindableViewModel = viewModel
        
        NavigationStack {
            ZStack {
                if reviewItems.isEmpty {
                    EmptyReviewState()
                } else {
                    ReviewContent(
                        items: reviewItems,
                        currentIndex: $bindableViewModel.currentIndex,
                        onMasteryUpdate: handleMastery
                    )
                }
            }
            .navigationTitle("复习")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.configure(with: modelContext)
            }
            .alert("复习完成！", isPresented: $bindableViewModel.showCompletionAlert) {
                Button("太棒了！") {
                    viewModel.reset()
                }
            } message: {
                Text("本次复习了 \(viewModel.reviewedCount) 道错题\n继续保持，你会越来越好！")
            }
        }
    }
    
    // MARK: - Actions
    
    /// 处理掌握度评估
    private func handleMastery(index: Int, level: MasteryLevel) {
        guard index < reviewItems.count else { return }
        
        withAnimation {
            viewModel.handleMasteryUpdate(for: reviewItems[index], level: level)
            viewModel.moveToNext(totalCount: reviewItems.count)
        }
    }
}

// MARK: - EmptyReviewState

/// 空状态视图
private struct EmptyReviewState: View {
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.bounce)
            
            VStack(spacing: 8) {
                Text("暂无需要复习的错题")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("去录入一些错题吧")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("暂无需要复习的错题，去录入一些错题吧")
    }
}

// MARK: - ReviewContent

/// 复习内容视图
private struct ReviewContent: View {
    
    let items: [ReviewItem]
    @Binding var currentIndex: Int
    let onMasteryUpdate: (Int, MasteryLevel) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ProgressBar(current: currentIndex + 1, total: items.count)
            
            TabView(selection: $currentIndex) {
                ForEach(items.indices, id: \.self) { index in
                    ReviewCard(
                        item: items[index],
                        onMastered: { onMasteryUpdate(index, .mastered) },
                        onUnclear: { onMasteryUpdate(index, .glimpse) },
                        onFailed: { onMasteryUpdate(index, .none) }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}

// MARK: - ProgressBar

/// 进度条组件
private struct ProgressBar: View {
    
    let current: Int
    let total: Int
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("复习进度")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(current) / \(total)")
                    .font(.headline)
                    .foregroundStyle(.blue)
            }
            
            ProgressView(value: Double(current), total: Double(total))
                .tint(.blue)
        }
        .padding()
        .background(.background.secondary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("复习进度：第 \(current) 题，共 \(total) 题")
        .accessibilityValue("\(Int(Double(current) / Double(total) * 100))%")
    }
}

// MARK: - ReviewCard

/// 复习卡片组件
///
/// 展示单道错题的详细信息，支持显示/隐藏答案，
/// 并提供掌握度自评按钮。
///
/// ## 使用示例
///
/// ```swift
/// ReviewCard(
///     item: reviewItem,
///     onMastered: { /* 完全掌握 */ },
///     onUnclear: { /* 一知半解 */ },
///     onFailed: { /* 不会 */ }
/// )
/// ```
struct ReviewCard: View {
    
    // MARK: - Properties
    
    /// 错题数据
    let item: ReviewItem
    
    /// 掌握回调
    let onMastered: () -> Void
    
    /// 模糊回调
    let onUnclear: () -> Void
    
    /// 不会回调
    let onFailed: () -> Void
    
    // MARK: - State
    
    /// 是否显示答案
    @State private var showAnswer = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    imageSection
                    titleSection
                    answerSection
                    metadataSection
                }
                .padding()
            }
            
            ActionButtons(
                onFailed: onFailed,
                onUnclear: onUnclear,
                onMastered: onMastered
            )
        }
        .background(Color(uiColor: .systemBackground))
    }
}

// MARK: - ReviewCard Subviews

private extension ReviewCard {
    
    /// 头部区域
    var headerSection: some View {
        HStack {
            Label(item.subject.displayName, systemImage: item.subject.icon)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(item.subject.color.opacity(0.1))
                .foregroundStyle(item.subject.color)
                .clipShape(Capsule())
            
            Spacer()
            
            Text(item.grade.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    /// 图片区域
    @ViewBuilder
    var imageSection: some View {
        if let imageData = item.imageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        }
    }
    
    /// 标题区域
    var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("题目")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(item.title)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// 答案区域
    @ViewBuilder
    var answerSection: some View {
        if !item.note.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                answerToggleButton
                
                if showAnswer {
                    Text(item.note)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.background.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
    
    /// 答案显示/隐藏按钮
    var answerToggleButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showAnswer.toggle()
            }
        } label: {
            HStack {
                Image(systemName: showAnswer ? "eye.slash.fill" : "eye.fill")
                Text(showAnswer ? "隐藏答案" : "查看答案")
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.down")
                    .rotationEffect(.degrees(showAnswer ? 180 : 0))
            }
            .padding()
            .background(.orange.opacity(0.1))
            .foregroundStyle(.orange)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityLabel(showAnswer ? "隐藏答案" : "查看答案")
    }
    
    /// 元数据区域
    var metadataSection: some View {
        VStack(spacing: 12) {
            if !item.knowledgePoints.isEmpty {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                    Text(item.knowledgePoints.rawValue)
                        .font(.caption)
                    Spacer()
                }
                .foregroundStyle(.secondary)
            }
            
            HStack {
                Label("已复习 \(item.reviewCount) 次", systemImage: "clock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                MasteryBadge(
                    level: MasteryLevel(rawValue: item.masteryLevel) ?? .none,
                    showDetailText: true
                )
            }
        }
    }
}

// MARK: - ActionButtons

/// 评估按钮组件
private struct ActionButtons: View {
    
    let onFailed: () -> Void
    let onUnclear: () -> Void
    let onMastered: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("这道题你掌握了吗？")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                MasteryButton(
                    icon: "xmark.circle.fill",
                    title: "不会",
                    color: .red,
                    action: onFailed
                )
                
                MasteryButton(
                    icon: "questionmark.circle.fill",
                    title: "模糊",
                    color: .orange,
                    action: onUnclear
                )
                
                MasteryButton(
                    icon: "checkmark.seal.fill",
                    title: "掌握",
                    color: .green,
                    action: onMastered
                )
            }
        }
        .padding()
        .background(.background.secondary)
    }
}

// MARK: - MasteryButton

/// 单个评估按钮
private struct MasteryButton: View {
    
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .accessibilityLabel(title)
        .accessibilityHint("点击标记为\(title)")
    }
}

// MARK: - Preview

#Preview("Review View") {
    ReviewView()
        .modelContainer(for: ReviewItem.self, inMemory: true)
}

#Preview("Review Card") {
    ReviewCard(
        item: ReviewItem(
            imageData: nil,
            title: "测试错题",
            note: "这是答案和解题思路",
            subject: .math,
            grade: .grade10,
            knowledgePoints: ["函数"]
        ),
        onMastered: {},
        onUnclear: {},
        onFailed: {}
    )
}
