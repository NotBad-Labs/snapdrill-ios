//
//  ReviewEmptyStateView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  无回顾任务时的空状态视图。
//

import SwiftUI

/// 当没有回顾任务或任务完成时的空状态视图
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
                .font(.system(size: 52, weight: .regular))
                .foregroundStyle(.secondary)
            
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
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
        title: "今日回顾完成",
        subtitle: "本轮没有需要处理的内容。",
        actionTitle: "完成",
        action: {}
    )
}
