//
//  StudyPracticeView.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/8/1.
//

import SwiftUI

/// 学习练习模块的视图
///
/// 职责：
/// - 显示学习会话和练习卡片
/// - 提供进入错题练习的入口
/// - 自身不包含复杂业务逻辑，通过 ViewModel (待创建) 获取数据
struct StudyPracticeView: View {
    var body: some View {
        VStack {
            Text("学习练习内容")
                .font(.largeTitle)
                .padding()
            Text("这里将是你的学习空间，可以开始错题练习，或者查看历史学习会话。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .navigationTitle("练习")
    }
}

// MARK: - Preview

#if DEBUG
struct StudyPracticeView_Previews: PreviewProvider {
    static var previews: some View {
        StudyPracticeView()
    }
}
#endif
