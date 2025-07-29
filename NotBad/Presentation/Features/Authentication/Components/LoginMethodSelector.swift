import SwiftUI

/// 登录方式选择器组件 - 优化版本
/// 位置: Presentation/Features/Authentication/Components/LoginMethodSelector.swift
struct LoginMethodSelector: View {
    @Binding var selectedMethod: LoginMethod
    @Namespace private var selectionNamespace
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(LoginMethod.allCases, id: \.self) { method in
                methodButton(for: method)
            }
        }
        .padding(4)
        .background(containerBackground)
    }
    
    // MARK: - 方法按钮
    private func methodButton(for method: LoginMethod) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                selectedMethod = method
            }
        }) {
            Text(method.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(selectedMethod == method ? .blue : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    ZStack {
                        if selectedMethod == method {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(
                                    color: .black.opacity(0.08),
                                    radius: 8,
                                    x: 0,
                                    y: 2
                                )
                                .shadow(
                                    color: .black.opacity(0.04),
                                    radius: 2,
                                    x: 0,
                                    y: 1
                                )
                                .matchedGeometryEffect(
                                    id: "selectedBackground",
                                    in: selectionNamespace
                                )
                        }
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 容器背景
    private var containerBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.separator), lineWidth: 0.5)
                    .opacity(0.3)
            )
    }
}

// MARK: - 预览
#Preview {
    VStack(spacing: 30) {
        // 不同状态的预览
        LoginMethodSelector(selectedMethod: .constant(.email))
        LoginMethodSelector(selectedMethod: .constant(.phone))
        LoginMethodSelector(selectedMethod: .constant(.username))
        
        // 交互式预览
        InteractivePreview()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

// MARK: - 交互式预览
private struct InteractivePreview: View {
    @State private var selectedMethod: LoginMethod = .email
    
    var body: some View {
        VStack(spacing: 20) {
            Text("交互式测试")
                .font(.headline)
            
            LoginMethodSelector(selectedMethod: $selectedMethod)
            
            Text("当前选择: \(selectedMethod.title)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}