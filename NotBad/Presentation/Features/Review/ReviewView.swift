//
//  ReviewView.swift
//  NotBad
//
//  复习视图 - iOS 26 现代化设计
//

import SwiftUI
import SwiftData

struct ReviewView: View {
    @Query(sort: \ReviewItem.createdAt, order: .reverse) private var allItems: [ReviewItem]
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ReviewViewModel()
    
    private var reviewItems: [ReviewItem] {
        viewModel.reviewItems(from: allItems)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if reviewItems.isEmpty {
                    emptyStateView
                } else {
                    reviewContentView
                }
            }
            .navigationTitle("复习")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.configure(with: modelContext)
            }
            .alert("复习完成！", isPresented: $viewModel.showCompletionAlert) {
                Button("太棒了！") {
                    viewModel.reset()
                }
            } message: {
                Text("本次复习了 \(viewModel.reviewedCount) 道错题\n继续保持，你会越来越好！")
            }
        }
    }
    
    // MARK: - 空状态
    
    private var emptyStateView: some View {
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
    }
    
    // MARK: - 复习内容
    
    private var reviewContentView: some View {
        VStack(spacing: 0) {
            progressBar
            
            TabView(selection: $viewModel.currentIndex) {
                ForEach(reviewItems.indices, id: \.self) { index in
                    ReviewCard(
                        item: reviewItems[index],
                        onMastered: { handleMastery(index: index, level: .mastered) },
                        onUnclear: { handleMastery(index: index, level: .glimpse) },
                        onFailed: { handleMastery(index: index, level: .none) }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
    
    // MARK: - 进度条
    
    private var progressBar: some View {
        VStack(spacing: 12) {
            HStack {
                Text("复习进度")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(viewModel.currentIndex + 1) / \(reviewItems.count)")
                    .font(.headline)
                    .foregroundStyle(.blue)
            }
            
            ProgressView(value: Double(viewModel.currentIndex + 1), total: Double(reviewItems.count))
                .tint(.blue)
        }
        .padding()
        .background(.background.secondary)
    }
    
    // MARK: - Actions
    
    private func handleMastery(index: Int, level: MasteryLevel) {
        guard index < reviewItems.count else { return }
        
        withAnimation {
            viewModel.handleMasteryUpdate(for: reviewItems[index], level: level)
            viewModel.moveToNext(totalCount: reviewItems.count)
        }
    }
}

// MARK: - 复习卡片

struct ReviewCard: View {
    let item: ReviewItem
    let onMastered: () -> Void
    let onUnclear: () -> Void
    let onFailed: () -> Void
    
    @State private var showAnswer = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 卡片内容
            ScrollView {
                VStack(spacing: 20) {
                    // 学科标签
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
                    
                    // 题目图片
                    if let imageData = item.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    }
                    
                    // 标题
                    VStack(alignment: .leading, spacing: 8) {
                        Text("题目")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(item.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 答案/笔记（点击显示）
                    if !item.note.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
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
                    
                    // 知识点
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
                    
                    // 复习信息
                    HStack {
                        Label("已复习 \(item.reviewCount) 次", systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        MasteryBadge(level: MasteryLevel(rawValue: item.masteryLevel) ?? .none, showDetailText: true)
                    }
                }
                .padding()
            }
            
            // 底部按钮
            actionButtons
        }
        .background(Color(uiColor: .systemBackground))
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Text("这道题你掌握了吗？")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                // 不会
                Button {
                    onFailed()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                        Text("不会")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.red.opacity(0.1))
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                // 模糊
                Button {
                    onUnclear()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title2)
                        Text("模糊")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.orange.opacity(0.1))
                    .foregroundStyle(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                // 掌握
                Button {
                    onMastered()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title2)
                        Text("掌握")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.green.opacity(0.1))
                    .foregroundStyle(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .padding()
        .background(.background.secondary)
    }
}

#Preview {
    ReviewView()
        .modelContainer(for: ReviewItem.self, inMemory: true)
}
