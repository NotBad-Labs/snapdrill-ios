//
//  AuthTextField.swift
//  NotBad
//
//  Created by Gemini on 2025/07/21.
//

import SwiftUI

/// 一个通用的认证文本输入框组件。
/// 适用于登录、注册等场景，提供统一的视觉风格和交互。
struct AuthTextField: View {
    // 使用 @Binding 来双向绑定文本字段的值
    @Binding var text: String
    // 占位符文本，提示用户输入内容
    let placeholder: String
    // 是否是安全输入（如密码），会隐藏输入内容
    var isSecure: Bool = false
    // 键盘类型，例如 .emailAddress, .default, .numberPad
    var keyboardType: UIKeyboardType = .default
    // 自动大写类型，例如 .none, .sentences, .words, .allCharacters
    var autocapitalization: TextAutocapitalization = .never
    // 自动更正类型，例如 .no, .yes
    var autocorrectionDisabled: Bool = true

    var body: some View {
        Group {
            // 根据 isSecure 决定使用 SecureField 还是 TextField
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding() // 内边距
        .background(Color.white) // 背景色
        .cornerRadius(10) // 圆角
        .overlay( // 添加边框
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal) // 左右外边距
        .keyboardType(keyboardType) // 设置键盘类型
        .autocapitalization(autocapitalization) // 设置自动大写
        .autocorrectionDisabled(autocorrectionDisabled) // 禁用自动更正
    }
}

// MARK: - 预览
/// 为 AuthTextField 提供预览，方便在 Xcode Canvas 中查看效果。
struct AuthTextField_Previews: PreviewProvider {
    // 使用 @State 来模拟绑定的文本值
    @State static var username: String = ""
    @State static var password: String = ""

    static var previews: some View {
        VStack(spacing: 20) {
            // 普通文本输入框预览
            AuthTextField(text: $username, placeholder: "用户名")
            // 密码输入框预览
            AuthTextField(text: $password, placeholder: "密码", isSecure: true)
            // 邮箱输入框预览
            AuthTextField(text: $username, placeholder: "邮箱", keyboardType: .emailAddress)
        }
        .previewLayout(.sizeThatFits) // 调整预览布局以适应内容
        .padding()
        .background(Color.gray.opacity(0.1)) // 预览背景，以便看清组件
    }
}
