import SwiftUI

/// 密码输入字段组件
/// 位置: Presentation/Features/Authentication/Components/InputFields/PasswordField.swift
struct PasswordField: View {
    @Binding var password: String
    @Binding var isVisible: Bool
    let placeholder: String
    
    var body: some View {
        HStack(spacing: 12) {
            // 锁定图标
            Image(systemName: "lock")
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            // 密码输入框
            Group {
                if isVisible {
                    TextField(placeholder, text: $password)
                } else {
                    SecureField(placeholder, text: $password)
                }
            }
            .textFieldStyle(PlainTextFieldStyle())
            
            // 可见性切换按钮
            Button(action: {
                isVisible.toggle()
            }) {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
        )
    }
}

// MARK: - 预览
#Preview {
    VStack {
        PasswordField(
            password: .constant("password123"),
            isVisible: .constant(false),
            placeholder: "请输入密码"
        )
        
        PasswordField(
            password: .constant("password123"),
            isVisible: .constant(true),
            placeholder: "请输入密码"
        )
    }
    .padding()
}