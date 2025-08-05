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
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                // MARK: - 欢迎和概览
                VStack(alignment: .leading, spacing: 5) {
                    Text("开始新一轮的挑战")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("你还有 **48 道** 错题待解决。")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // MARK: - 开始练习卡片
                NavigationLink(destination: StudyPracticeListView()) {
                    VStack(spacing: 10) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 40))
                        Text("开始快速练习")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("从你的错题库中随机抽取")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 30)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(15)
                    .shadow(color: Color.purple.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal)
                
                // MARK: - 历史记录卡片
                VStack(alignment: .leading, spacing: 10) {
                    Text("历史记录")
                        .font(.headline)
                    
                    NavigationLink(destination: Text("历史练习记录")) {
                        HStack(spacing: 15) {
                            Label("历史练习记录", systemImage: "clock.fill")
                                .font(.body)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
        .navigationTitle("练习")
    }
}

// MARK: - Preview

#if DEBUG
struct StudyPracticeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            StudyPracticeView()
        }
    }
}
#endif

