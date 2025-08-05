//
//  DashboardView.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/8/1.
//

import SwiftUI

/// 仪表盘模块的视图
///
/// 职责：
/// - 显示用户的概览数据，如学习进度、错题统计等
/// - 提供快速访问其他功能的入口
/// - 自身不包含复杂业务逻辑，通过 ViewModel (待创建) 获取数据
struct DashboardView: View {
    var body: some View {
        VStack {
            Text("主页内容")
                .font(.largeTitle)
                .padding()
            Text("仪表盘是应用的核心，它能帮助你一览所有重要的学习数据。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .navigationTitle("主页")
    }
}

// MARK: - Preview

#if DEBUG
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
#endif
