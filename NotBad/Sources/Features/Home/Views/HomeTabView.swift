//
//  HomeTabView.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//

import SwiftUI

/// 首页Tab视图
struct HomeTabView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("🏠 首页")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)

            Text("学习总览，高效复习")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("这里将是首页界面\n• 学习进度总览\n• 今日复习提醒\n• 快速操作入口\n• 学习统计图表")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .navigationTitle("首页")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationView {
        HomeTabView()
    }
}
