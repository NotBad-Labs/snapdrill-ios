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
    
    @State private var currentIndex = 0
    @State private var showCompletionAlert = false
    @State private var reviewedCount = 0
    
    // 过滤出需要复习的错题（优先级：未掌握 > 模糊 > 已掌握）
    private var reviewItems: [ReviewItem] {
        allItems.sorted { item1, item2 in
            // 按掌握度排序：0(不会) > 1(模糊) > 2(熟悉) > 3(掌握)
            if item1.masteryLevel != item2.masteryLevel {
                return item1.masteryLevel < item2.masteryLevel
            }
            // 相同掌握度按复习次数排序（少的优先）
            return item1.reviewCount < item2.reviewCount
        }
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
            .alert("复习完成！", isPresented: $showCompletionAlert) {
                Button("太棒了！") {
                    currentIndex = 0
                    reviewedCount = 0
                }
            } message: {
                Text("本次复习了 \(reviewedCount) 道错题\n继续保持，你会越来越好！")
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
            // 进度条
            progressBar
            
            // 卡片区域
            TabView(selection: $currentIndex) {
                ForEach(reviewItems.indices, id: \.self) { index in
                    ReviewCard(
                        item: reviewItems[index],
                        onMastered: {
                            handleMasteryUpdate(index: index, level: 3)
                        },
                        onUnclear: {
                            handleMasteryUpdate(index: index, level: 1)
                        },
                        onFailed: {
                            handleMasteryUpdate(index: index, level: 0)
                        }
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
                
                Text("\(currentIndex + 1) / \(reviewItems.count)")
                    .font(.headline)
                    .foregroundStyle(.blue)
            }
            
            ProgressView(value: Double(currentIndex + 1), total: Double(reviewItems.count))
                .tint(.blue)
        }
        .padding()
        .background(.background.secondary)
    }
    
    // MARK: - 逻辑处理
    
    private func handleMasteryUpdate(index: Int, level: Int) {
        guard index < reviewItems.count else { return }
        
        let item = reviewItems[index]
        
        withAnimation {
            // 更新掌握度
            item.masteryLevel = level
            
            // 增加复习次数
            item.reviewCount += 1
            
            // 更新复习时间
            item.updatedAt = Date()
            
            // 计算下次复习时间
            let level = MasteryLevel(rawValue: level) ?? .none
            if let nextDate = Calendar.current.date(byAdding: .day, value: level.reviewIntervalDays, to: Date()) {
                item.nextReviewDate = nextDate
            }
            
            // 保存
            try? modelContext.save()
            
            // 增加已复习计数
            reviewedCount += 1
            
            // 移动到下一题
            if currentIndex < reviewItems.count - 1 {
                currentIndex += 1
            } else {
                // 完成所有复习
                showCompletionAlert = true
            }
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
                    
                    // 标签
                    if !item.tags.isEmpty {
                        HStack {
                            Image(systemName: "tag.fill")
                                .font(.caption)
                            Text(item.tags.rawValue)
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
