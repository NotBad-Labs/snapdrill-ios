//
//  ErrorMessageView.swift
//  NotBadUI
//
//  Created by NotBad Labs on 2026/01/02.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  通用错误消息视图组件
//

import SwiftUI
import NotBadCore

/// 错误消息视图
///
/// 用于显示友好的错误提示，包含图标、标题、描述和操作按钮。
public struct ErrorMessageView: View {
    let title: String
    let message: String
    let icon: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    public init(
        title: String,
        message: String,
        icon: String = "exclamationmark.triangle.fill",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 加载视图
public struct LoadingView: View {
    let message: String
    
    public init(message: String = "加载中...") {
        self.message = message
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Error") {
    ErrorMessageView(
        title: "加载失败",
        message: "无法加载数据，请检查网络连接后重试",
        actionTitle: "重试"
    ) {
        NotBadLogger.generic.info("Retry tapped")
    }
}

#Preview("Loading") {
    LoadingView(message: "正在加载数据...")
}
