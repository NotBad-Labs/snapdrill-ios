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
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                // MARK: - 欢迎和概览
                VStack(alignment: .leading, spacing: 5) {
                    Text("👋 嗨，Yiming!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("今天你又进步了多少？")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // MARK: - 学习概览卡片
                Text("学习概览")
                    .font(.headline)
                    .padding(.horizontal)
                
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        dashboardCard(title: "今日练习", value: "25", unit: "题", color: .blue)
                        dashboardCard(title: "未解决错题", value: "48", unit: "题", color: .red)
                    }
                    HStack(spacing: 10) {
                        dashboardCard(title: "本周正确率", value: "85", unit: "%", color: .green)
                        dashboardCard(title: "累计学习天数", value: "12", unit: "天", color: .orange)
                    }
                }
                .padding(.horizontal)

                // MARK: - 快捷入口卡片
                Text("快捷入口")
                    .font(.headline)
                    .padding(.horizontal)
                
                VStack(spacing: 10) {
                    NavigationLink(destination: StudyPracticeView()) {
                        HStack(spacing: 15) {
                            Label("开始练习", systemImage: "pencil.and.ruler.fill")
                                .font(.body)
                                .foregroundColor(.blue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGroupedBackground))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
                    }
                    
                    NavigationLink(destination: Text("错题分类")) {
                        HStack(spacing: 15) {
                            Label("错题分类", systemImage: "folder.fill")
                                .font(.body)
                                .foregroundColor(.green)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGroupedBackground))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
                    }
                    
                    NavigationLink(destination: Text("添加新题")) {
                        HStack(spacing: 15) {
                            Label("添加新题", systemImage: "plus.circle.fill")
                                .font(.body)
                                .foregroundColor(.purple)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGroupedBackground))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
        .navigationTitle("主页")
    }

    /// 仪表盘中的小卡片
    private func dashboardCard(title: String, value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(color)
        .cornerRadius(15)
        .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 5)
    }
}

// MARK: - Preview

#if DEBUG
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DashboardView()
        }
    }
}
#endif

