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
/// - 在用户选择具体的录题方式后，显示下一步的交互界面
/// - 根据不同的录题方式（如拍照、文件导入），呈现不同的UI和功能
struct QuestionCaptureOptionsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("准备开始录题")
                .font(.title)
                .fontWeight(.bold)
            
            Text("这里是根据你的选择，开始录入题目的页面。\n我们将在这里实现具体的功能。")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("录题选项")
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

