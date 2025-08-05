//
//  StudyPracticeListView.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/8/1.
//

import SwiftUI

/// 学习练习模块的列表视图
///
/// 职责：
/// - 显示一个可滚动的错题列表
/// - 列表中的每一项都可以跳转到错题详情页 (待创建)
/// - 自身不包含业务逻辑，通过 ViewModel (待创建) 获取数据
struct StudyPracticeListView: View {
    var body: some View {
        List {
            ForEach(0..<10) { index in
                VStack(alignment: .leading, spacing: 5) {
                    Text("错题标题 \(index + 1)")
                        .font(.headline)
                    Text("这是一道关于学习进度的示例错题。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("练习列表")
    }
}

// MARK: - Preview

#if DEBUG
struct StudyPracticeListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            StudyPracticeListView()
        }
    }
}
#endif
