//
//  WelcomeView.swift
//  NotBad
//
//  Created by Yiming Liao on 10/7/25.
//

import SwiftUI

/// 欢迎视图
///
/// 职责：
/// - 展示应用欢迎界面
/// - 显示应用特性
/// - 引导用户开始使用
@MainActor
struct WelcomeView: View {
    
    // MARK: - Properties
    
    @Environment(AppCoordinator.self) private var coordinator
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            // App Icon
            Image(systemName: "book.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .symbolEffect(.bounce, value: true)
                .accessibilityLabel("NotBad 错题本图标")
            
            // Title
            Text("NotBad 错题本")
                .font(.largeTitle)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)
            
            // Subtitle
            Text("Swift 6.2 + iOS 26 现代化开发")
                .font(.title2)
                .foregroundColor(.secondary)
            
            // Features
            FeatureListView()
            
            Spacer()
            
            // 开始使用按钮
            Button {
                coordinator.push(.home)
            } label: {
                Text("开始使用")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            
            // Version Info
            Text("Version 6.0 - 2025")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("欢迎")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    WelcomeView()
}
