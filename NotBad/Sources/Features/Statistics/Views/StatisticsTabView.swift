//
//  StatisticsTabView.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//  统计功能模块 - 学习数据和分析
//

import SwiftUI

/// 统计Tab视图 - 学习数据和分析功能
struct StatisticsTabView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("📊 统计")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text("学习数据，进步可视")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("这里将是统计界面\n• 学习进度\n• 掌握情况\n• 趋势分析")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("统计")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationView {
        StatisticsTabView()
    }
}
