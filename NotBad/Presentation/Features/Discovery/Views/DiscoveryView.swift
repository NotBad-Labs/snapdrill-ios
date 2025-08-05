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
        VStack {
            Text("发现内容")
                .font(.largeTitle)
                .padding()
            Text("在这里，你可以探索其他用户的分享，发现有趣的错题集和学习方法。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .navigationTitle("发现")
    }
}

// MARK: - Preview

#if DEBUG
struct DiscoveryView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoveryView()
    }
}
#endif
