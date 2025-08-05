//
//  QuestionCaptureOptionsView.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/8/1.
//

import SwiftUI

/// 录题选项视图
///
/// 职责：
/// - 显示录题方式选项（拍照/手动输入）
/// - 每个选项都可以跳转到具体的录题界面 (待创建)
struct QuestionCaptureOptionsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("选择录题方式")
                .font(.title)
                .fontWeight(.bold)
            
            Text("你可以通过拍照快速录入，也可以手动输入错题。")
                .font(.body)
                .foregroundColor(.secondary)
            
            // 拍照录题按钮
            Button(action: {
                // TODO: 导航到拍照录题视图
            }) {
                HStack {
                    Image(systemName: "camera.on.rectangle.fill")
                    Text("拍照录题")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            // 手动输入按钮
            Button(action: {
                // TODO: 导航到手动录入视图
            }) {
                HStack {
                    Image(systemName: "square.and.pencil.circle.fill")
                    Text("手动输入")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.secondary)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical, 20)
        .navigationTitle("录题")
    }
}

// MARK: - Preview

#if DEBUG
struct QuestionCaptureOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            QuestionCaptureOptionsView()
        }
    }
}
#endif
