import SwiftUI

/// 分割线视图组件
/// 位置: Presentation/Features/Authentication/Components/DividerView.swift
struct DividerView: View {
    let text: String
    
    init(text: String = "或") {
        self.text = text
    }
    
    var body: some View {
        HStack {
            // 左侧线条
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 1)
            
            // 中间文字
            Text(text)
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
            
            // 右侧线条
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 1)
        }
    }
}

// MARK: - 预览
#Preview {
    VStack(spacing: 20) {
        DividerView()
        DividerView(text: "或者")
        DividerView(text: "其他方式")
    }
    .padding()
}