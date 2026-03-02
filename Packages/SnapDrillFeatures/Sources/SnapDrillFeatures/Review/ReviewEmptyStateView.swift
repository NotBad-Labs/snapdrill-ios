//
//  ReviewEmptyStateView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  无复习任务时的空状态视图。
//

import SwiftUI

/// 当没有复习任务或任务完成时的空状态视图
struct ReviewEmptyStateView: View {
    
    // MARK: - Properties
    
    /// 图标名称
    let icon: String
    /// 标题
    let title: String
    /// 副标题或描述
    let subtitle: String
    /// 按钮标题（可选）
    let actionTitle: String?
    /// 按钮点击回调（可选）
    let action: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
                .symbolEffect(.bounce, value: true)
            
            Text(title)
                .font(.title2.bold())
            
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ReviewEmptyStateView(
        icon: "checkmark.seal.fill",
        title: "今日复习完成",
        subtitle: "太棒了！休息一下，明天继续。",
        actionTitle: "好的",
        action: {}
    )
}
