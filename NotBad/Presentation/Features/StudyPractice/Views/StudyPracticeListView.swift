//
//  StudyPracticeListView.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/8/1.
//

import SwiftUI

/// 学习练习列表视图
///
/// 职责：
/// - 显示不同类型的学习练习模式
/// - 提供进入具体练习会话的入口
/// - 自身不包含复杂业务逻辑，通过 ViewModel (待创建) 获取数据
struct StudyPracticeListView: View {
    var body: some View {
        List {
            // MARK: - 每日练习 Section
            Section {
                NavigationLink(destination: StudySessionView()) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.orange)
                        Text("每日练习")
                    }
                }
            } header: {
                Text("每日任务")
            }
            
            // MARK: - 错题类型 Section
            Section {
                NavigationLink(destination: Text("专项练习：数学")) {
                    Label("数学", systemImage: "x.squareroot")
                        .foregroundColor(.blue)
                }
                
                NavigationLink(destination: Text("专项练习：物理")) {
                    Label("物理", systemImage: "atom")
                        .foregroundColor(.red)
                }
                
                NavigationLink(destination: Text("专项练习：化学")) {
                    Label("化学", systemImage: "flask")
                        .foregroundColor(.green)
                }
            } header: {
                Text("专项练习")
            }
            
            // MARK: - 自定义练习 Section
            Section {
                NavigationLink(destination: Text("自定义练习设置")) {
                    Label("自定义练习", systemImage: "slider.horizontal.3")
                        .foregroundColor(.purple)
                }
            } header: {
                Text("高级")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("开始练习")
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

