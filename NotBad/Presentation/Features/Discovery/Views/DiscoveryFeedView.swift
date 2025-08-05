//
//  DiscoveryFeedView.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/8/1.
//

import SwiftUI

/// 发现模块的内容流视图
///
/// 职责：
/// - 显示推荐的错题集、学习动态等内容卡片
/// - 列表中的每一项都可以跳转到详情页 (待创建)
struct DiscoveryFeedView: View {
    var body: some View {
        List {
            ForEach(0..<10) { index in
                NavigationLink(destination: Text("详情页 \(index + 1)")) {
                    HStack(spacing: 15) {
                        Image(systemName: "books.vertical.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.purple)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("推荐错题集：主题 \(index + 1)")
                                .font(.headline)
                            Text("这里将展示由社区用户分享的精彩内容。")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("发现")
    }
}

// MARK: - Preview

#if DEBUG
struct DiscoveryFeedView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DiscoveryFeedView()
        }
    }
}
#endif

