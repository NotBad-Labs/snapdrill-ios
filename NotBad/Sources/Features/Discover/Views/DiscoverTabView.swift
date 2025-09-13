//
//  DiscoverTabView.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//  发现功能模块 - AI智能和学习资源
//

import SwiftUI

/// 发现Tab视图 - AI智能和学习资源功能
struct DiscoverTabView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("💡 发现")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text("AI智能，学习助手")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("这里将是发现界面\n• AI诊断\n• 学习建议\n• 资源推荐")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("发现")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationView {
        DiscoverTabView()
    }
}
