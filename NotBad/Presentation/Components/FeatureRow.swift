//
//  FeatureRow.swift
//  NotBad
//
//  Created by Yiming Liao on 10/7/25.
//

import SwiftUI

/// 特性展示行组件
///
/// 职责：
/// - 单个特性的展示
/// - 可重用的 UI 组件
@MainActor
struct FeatureRow: View {
    
    // MARK: - Properties
    
    let feature: FeatureItem
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: feature.icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    FeatureRow(
        feature: FeatureItem(
            icon: "bolt.fill",
            title: "严格并发",
            description: "Swift 6.2 数据竞争安全"
        )
    )
    .padding()
}
