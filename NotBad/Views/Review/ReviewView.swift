//
//  ReviewView.swift
//  NotBad
//
//  复习视图 - 卡片式复习流程
//

import SwiftUI
import SwiftData
import ReviewKit

struct ReviewView: View {
    @Query(sort: \ReviewItemModel.nextReviewDate)
    private var allItems: [ReviewItemModel]
    @Environment(\.modelContext) private var modelContext
    
    @State private var currentIndex = 0
    @State private var showAnswer = false
    @State private var showCompleteBanner = false
    
    private var dueItems: [ReviewItemModel] {
        allItems.filter { $0.needsReview }
    }
    
    private var currentItem: ReviewItemModel? {
        guard currentIndex < dueItems.count else { return nil }
        return dueItems[currentIndex]
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if dueItems.isEmpty {
                    completedView
                } else if let item = currentItem {
                    reviewCardView(item: item)
                } else {
                    completedView
                }
            }
            .navigationTitle("复习")
            .toolbar {
                if !dueItems.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Text("\(currentIndex + 1)/\(dueItems.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("跳过") { goNext() }
                            Button(role: .destructive) {
                                deleteCurrent()
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var completedView: some View {
        ContentUnavailableView(
            "太棒了！",
            systemImage: "checkmark.circle.fill",
            description: Text("所有错题都已复习完成")
        )
        .overlay(alignment: .top) {
            if showCompleteBanner {
                Label("已完成本轮复习", systemImage: "sparkles")
                    .padding(8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private func reviewCardView(item: ReviewItemModel) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // 图片区域
                if let imagePath = item.imagePath,
                   let image = ImageStorageService.shared.load(fileName: imagePath) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 2)
                }
                
                // 标题
                Text(item.displayTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // 笔记（点击显示）
                if showAnswer && !item.note.isEmpty {
                    Text(item.note)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .transition(.opacity.combined(with: .scale))
                }
                
                Spacer(minLength: 20)
                
                // 操作按钮
                if showAnswer {
                    performanceButtons(for: item)
                    nextReviewInfo(for: item)
                } else {
                    showAnswerButton
                }
            }
            .padding()
            .safeAreaInset(edge: .bottom) {
                if !dueItems.isEmpty {
                    HStack {
                        Button("跳过") { goNext() }
                            .buttonStyle(.bordered)
                        Button(role: .destructive) {
                            deleteCurrent()
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        .animation(.spring(duration: 0.3), value: showAnswer)
    }
    
    private var showAnswerButton: some View {
        Button {
            withAnimation { showAnswer = true }
        } label: {
            Text("显示答案")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: showAnswer)
    }

    private func nextReviewInfo(for item: ReviewItemModel) -> some View {
        VStack(spacing: 4) {
            Text("下次复习：")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(item.nextReviewDate.formatted(date: .abbreviated, time: .omitted))
                .font(.headline)
        }
    }
    
    private func performanceButtons(for item: ReviewItemModel) -> some View {
        VStack(spacing: 12) {
            Text("记得多少？")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                performanceButton(
                    title: "忘了",
                    color: .red,
                    performance: 0,
                    item: item
                )
                performanceButton(
                    title: "模糊",
                    color: .orange,
                    performance: 1,
                    item: item
                )
                performanceButton(
                    title: "记得",
                    color: .green,
                    performance: 2,
                    item: item
                )
                performanceButton(
                    title: "简单",
                    color: .blue,
                    performance: 3,
                    item: item
                )
            }
        }
    }
    
    private func performanceButton(
        title: String,
        color: Color,
        performance: Int,
        item: ReviewItemModel
    ) -> some View {
        Button {
            recordAndNext(item: item, performance: performance)
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(color.opacity(0.15))
                .foregroundStyle(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: currentIndex)
    }
    
    // MARK: - Actions
    
    private func recordAndNext(item: ReviewItemModel, performance: Int) {
        // 记录复习（使用充血模型方法）
        item.recordReview(performance: performance)

        goNext()
    }

    private func goNext() {
        withAnimation {
            showAnswer = false
            if currentIndex < dueItems.count - 1 {
                currentIndex += 1
            } else {
                currentIndex = 0
                showCompleteBanner = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showCompleteBanner = false
                }
            }
        }
    }

    private func deleteCurrent() {
        guard let current = currentItem else { return }
        modelContext.delete(current)
        goNext()
    }
}

#Preview {
    ReviewView()
        .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
