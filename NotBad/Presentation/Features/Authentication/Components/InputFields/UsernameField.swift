import SwiftUI

/// 用户名输入字段组件 - 优化版本
/// 位置: Presentation/Features/Authentication/Components/InputFields/UsernameField.swift
struct UsernameField: View {
    @Binding var text: String
    let placeholder: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // 用户图标 - 带动画
            Image(systemName: "person")
                .foregroundColor(isFocused ? .blue : .secondary)
                .frame(width: 20)
                .scaleEffect(isFocused ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
            
            // 用户名输入框
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .focused($isFocused)
                .onSubmit {
                    // 可以添加提交逻辑
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isFocused ? Color.blue.opacity(0.6) : Color(.separator),
                    lineWidth: isFocused ? 2 : 1
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(
                            color: isFocused ? .blue.opacity(0.1) : .clear,
                            radius: isFocused ? 4 : 0,
                            x: 0,
                            y: 0
                        )
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFocused)
    }
}

// MARK: - 预览
#Preview {
    VStack(spacing: 20) {
        UsernameField(
            text: .constant("john_doe"),
            placeholder: "请输入用户名"
        )
        
        UsernameField(
            text: .constant(""),
            placeholder: "请输入用户名"
        )
    }
    .padding()
}