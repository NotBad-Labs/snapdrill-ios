//
//  ProfileTabView.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//  个人中心功能模块 - 个人设置和账户管理
//

import SwiftUI

/// 个人中心Tab视图 - 个人设置和账户管理功能
struct ProfileTabView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("👤 我的")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text("个人中心，设置管理")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("这里将是我的界面\n• 个人设置\n• 账户管理\n• 数据同步\n• 帮助支持\n• Pro订阅管理")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("我的")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationView {
        ProfileTabView()
    }
}
