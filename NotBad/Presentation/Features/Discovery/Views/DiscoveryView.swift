//
//  DiscoveryView.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/8/1.
//

import SwiftUI

/// 发现模块的视图
///
/// 职责：
/// - 显示推荐的题目、学习社区动态等内容
/// - 提供轻社交和内容探索功能
/// - 自身不包含复杂业务逻辑，通过 ViewModel (待创建) 获取数据
struct DiscoveryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("探索学习新世界")
                .font(.title)
                .fontWeight(.bold)
            
            Text("浏览社区分享的优质错题集、学习经验，与他人共同进步。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: DiscoveryFeedView()) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("开始探索")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.purple)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical, 20)
        .navigationTitle("发现")
    }
}

// MARK: - Preview

#if DEBUG
struct DiscoveryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DiscoveryView()
        }
    }
}
#endif

