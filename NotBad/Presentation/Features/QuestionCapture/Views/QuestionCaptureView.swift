//
//  QuestionCaptureView.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/8/1.
//

import SwiftUI

/// 录题模块的视图
///
/// 职责：
/// - 显示用于录入错题的界面
/// - 提供 OCR、拍照、手动输入等功能入口
/// - 自身不包含复杂业务逻辑，通过 ViewModel (待创建) 获取数据
struct QuestionCaptureView: View {
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                // MARK: - 欢迎和概览
                VStack(alignment: .leading, spacing: 5) {
                    Text("开始整理你的错题集")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("选择最适合你的方式，轻松录入题目。")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // MARK: - 功能卡片
                VStack(spacing: 15) {
                    // 拍照录题卡片
                    NavigationLink(destination: QuestionCaptureOptionsView()) {
                        captureCard(
                            icon: "camera.on.rectangle.fill",
                            title: "拍照录题",
                            description: "使用摄像头智能识别，快速录入题目",
                            color: .blue
                        )
                    }
                    
                    // 文件导入卡片
                    NavigationLink(destination: QuestionCaptureOptionsView()) {
                        captureCard(
                            icon: "doc.text.image.fill",
                            title: "文件导入",
                            description: "从图片或PDF文件中提取，批量整理错题",
                            color: .green
                        )
                    }
                    
                    // 手动输入卡片
                    NavigationLink(destination: QuestionCaptureOptionsView()) {
                        captureCard(
                            icon: "keyboard.fill",
                            title: "手动输入",
                            description: "亲自输入题目和解析，定制你的错题",
                            color: .orange
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
        .navigationTitle("录题")
    }
    
    /// 录题功能的小卡片
    private func captureCard(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(description)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
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

// MARK: - Preview

#if DEBUG
struct QuestionCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            QuestionCaptureView()
        }
    }
}
#endif

