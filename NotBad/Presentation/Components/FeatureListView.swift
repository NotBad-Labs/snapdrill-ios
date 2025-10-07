//
//  FeatureListView.swift
//  NotBad
//
//  Created by Yiming Liao on 10/7/25.
//

import SwiftUI

/// 特性列表视图
///
/// 职责：
/// - 展示应用主要特性
/// - 可重用的特性展示组件
@MainActor
struct FeatureListView: View {
    
    // MARK: - Properties
    
    private let features: [FeatureItem] = [
        FeatureItem(
            icon: "bolt.fill",
            title: "严格并发",
            description: "Swift 6.2 数据竞争安全"
        ),
        FeatureItem(
            icon: "cylinder.fill",
            title: "SwiftData",
            description: "iOS 26 高级数据管理"
        ),
        FeatureItem(
            icon: "building.columns.fill",
            title: "Clean Architecture",
            description: "分层架构 + MVVM-C"
        )
    ]
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(features) { feature in
                FeatureRow(feature: feature)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview {
    FeatureListView()
        .padding()
}
