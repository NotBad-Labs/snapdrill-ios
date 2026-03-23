//
//  ProgressLoadingView.swift
//  SnapDrillUI
//
//  Created by NotBad Labs on 2026/01/03.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  带进度的加载视图组件
//

import SwiftUI

/// 带进度指示的加载视图
///
/// 用于显示带有进度百分比的加载状态，适用于导出、同步等长时间操作。
public struct ProgressLoadingView: View {
    
    // MARK: - Properties
    
    let message: String
    let progress: Double?
    
    /// 创建进度加载视图
    /// - Parameters:
    ///   - message: 加载提示文本
    ///   - progress: 进度值（0.0–1.0）；为 `nil` 时显示不确定进度指示器
    public init(message: String, progress: Double? = nil) {
        self.message = message
        self.progress = progress
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 20) {
            if let progress = progress {
                VStack(spacing: 12) {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(.linear)
                        .frame(width: 200)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            } else {
                ProgressView()
                    .controlSize(.large)
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 骨架屏加载视图
///
/// 用于列表加载时显示占位内容，提供更好的用户体验。
public struct SkeletonLoadingView: View {
    let itemCount: Int
    
    /// 创建骨架屏加载视图
    /// - Parameter itemCount: 占位行数，默认 5
    public init(itemCount: Int = 5) {
        self.itemCount = itemCount
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(0..<itemCount, id: \.self) { _ in
                    SkeletonItemView()
                }
            }
            .padding()
        }
    }
}

/// 单个骨架屏项目
private struct SkeletonItemView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题骨架
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 20)
                .frame(maxWidth: .infinity)
            
            // 副标题骨架
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 16)
                .frame(width: 200)
            
            // 内容骨架
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 14)
                .frame(maxWidth: .infinity)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 14)
                .frame(width: 150)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview("Progress Loading") {
    ProgressLoadingView(message: "正在导出 PDF...", progress: 0.65)
}

#Preview("Indeterminate Loading") {
    ProgressLoadingView(message: "正在同步数据...")
}

#Preview("Skeleton Loading") {
    SkeletonLoadingView(itemCount: 5)
}
