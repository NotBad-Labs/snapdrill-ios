//
//  ReviewTabView.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//  复习功能模块 - 错题复习和重做
//

import SwiftUI

/// 复习Tab视图 - 错题复习和重做功能
struct ReviewTabView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("📚 复习")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text("智能复习，高效学习")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("这里将是复习界面\n• 错题卡片\n• 智能提醒\n• 复习进度")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("复习")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationView {
        ReviewTabView()
    }
}
