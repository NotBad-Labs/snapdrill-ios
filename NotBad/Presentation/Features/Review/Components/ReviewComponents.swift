//
//  ReviewComponents.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI

// MARK: - ReviewContent

/// 复习内容视图
struct ReviewContent: View {
    
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
struct ProgressBar: View {
    
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
