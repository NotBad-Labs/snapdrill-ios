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
        VStack {
            Text("录题内容")
                .font(.largeTitle)
                .padding()
            Text("这里将是你的录题界面，你可以使用相机或相册将错题录入应用。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .navigationTitle("录题")
    }
}

// MARK: - Preview

#if DEBUG
struct QuestionCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionCaptureView()
    }
}
#endif
