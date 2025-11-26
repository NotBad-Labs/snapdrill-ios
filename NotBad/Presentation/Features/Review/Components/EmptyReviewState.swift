//
//  EmptyReviewState.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI

// MARK: - EmptyReviewState

/// 空状态视图
struct EmptyReviewState: View {
    
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

#Preview {
    EmptyReviewState()
}
