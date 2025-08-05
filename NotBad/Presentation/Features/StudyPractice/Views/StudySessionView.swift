//
//  StudySessionView.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/8/1.
//

import SwiftUI

/// 学习会话视图
///
/// 职责：
/// - 显示一个具体的练习会话，包括题目、选项、计时器等
/// - 处理用户的答题交互
/// - 自身不包含复杂业务逻辑，通过 ViewModel (待创建) 获取数据并处理逻辑
struct StudySessionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "pencil.and.outline")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("每日练习会话")
                .font(.title)
                .fontWeight(.bold)
            
            Text("这里是具体的题目展示区域。\n我们将在这里实现计时、答题和统计功能。")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("结束练习") {
                // TODO: 实现结束练习的逻辑，如保存进度和返回
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(15)
        }
        .padding()
        .navigationTitle("练习中")
    }
}

// MARK: - Preview

#if DEBUG
struct StudySessionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            StudySessionView()
        }
    }
}
#endif
