//
//  ToastView.swift
//  NotBad
//
//  Toast 提示组件
//

import SwiftUI

/// Toast 类型
enum ToastType {
    case success
    case error
    case warning
    case info
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

/// Toast 数据模型
struct Toast: Equatable {
    let type: ToastType
    let message: String
    var duration: Double = 2.0
    
    static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.message == rhs.message && lhs.duration == rhs.duration
    }
}

/// Toast 视图
struct ToastView: View {
    let toast: Toast
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .font(.title3)
                .foregroundStyle(toast.type.color)
            
            Text(toast.message)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        .padding(.horizontal)
    }
}

/// Toast 修饰器
struct ToastModifier: ViewModifier {
    @Binding var toast: Toast?
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast {
                    ToastView(toast: toast)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                                withAnimation {
                                    self.toast = nil
                                }
                            }
                        }
                        .padding(.top, 50)
                }
            }
            .animation(.spring(response: 0.3), value: toast)
    }
}

extension View {
    /// 添加 Toast 支持
    func toast(_ toast: Binding<Toast?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}

#Preview {
    VStack {
        Text("主内容")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .overlay(alignment: .top) {
        VStack(spacing: 16) {
            ToastView(toast: Toast(type: .success, message: "保存成功！"))
            ToastView(toast: Toast(type: .error, message: "保存失败，请重试"))
            ToastView(toast: Toast(type: .warning, message: "网络不稳定"))
            ToastView(toast: Toast(type: .info, message: "提示：双击可快速复习"))
        }
        .padding(.top, 60)
    }
}
