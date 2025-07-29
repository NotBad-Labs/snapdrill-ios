import SwiftUI

/// 主要认证按钮组件
/// 位置: Presentation/Features/Authentication/Components/AuthButtons/PrimaryAuthButton.swift
struct PrimaryAuthButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    
                    Text("登录中...")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                } else {
                    Text(title)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.8 : 1.0)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 预览
#Preview {
    VStack(spacing: 20) {
        PrimaryAuthButton(
            title: "登录",
            isLoading: false
        ) {
            print("登录按钮点击")
        }
        
        PrimaryAuthButton(
            title: "登录",
            isLoading: true
        ) {
            print("登录按钮点击")
        }
    }
    .padding()
}