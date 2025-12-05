//
//  AsyncButton.swift
//  NotBad
//
//  支持异步操作的按钮，自动显示加载状态
//

import SwiftUI

// MARK: - AsyncButton

/// 异步操作按钮
///
/// 在执行异步操作时自动显示加载指示器，并禁用按钮防止重复点击。
///
/// ## 使用示例
///
/// ```swift
/// AsyncButton("保存") {
///     try await viewModel.save()
/// }
///
/// AsyncButton {
///     try await viewModel.delete()
/// } label: {
///     Label("删除", systemImage: "trash")
/// }
/// ```
struct AsyncButton<Label: View>: View {
    
    let action: () async throws -> Void
    let label: () -> Label
    
    @State private var isLoading = false
    @State private var error: Error?
    
    var showErrorAlert: Bool = true
    
    init(
        action: @escaping () async throws -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.action = action
        self.label = label
    }
    
    var body: some View {
        Button {
            Task {
                isLoading = true
                defer { isLoading = false }
                
                do {
                    try await action()
                } catch {
                    self.error = error
                }
            }
        } label: {
            ZStack {
                label()
                    .opacity(isLoading ? 0 : 1)
                
                if isLoading {
                    ProgressView()
                }
            }
        }
        .disabled(isLoading)
        .alert("操作失败", isPresented: .init(
            get: { showErrorAlert && error != nil },
            set: { if !$0 { error = nil } }
        )) {
            Button("确定", role: .cancel) {
                error = nil
            }
        } message: {
            if let error {
                Text(error.localizedDescription)
            }
        }
    }
}

// MARK: - Convenience Initializers

extension AsyncButton where Label == Text {
    
    /// 使用文本标签创建异步按钮
    init(_ title: String, action: @escaping () async throws -> Void) {
        self.init(action: action) {
            Text(title)
        }
    }
}

extension AsyncButton where Label == SwiftUI.Label<Text, Image> {
    
    /// 使用系统图标和文本创建异步按钮
    init(
        _ title: String,
        systemImage: String,
        action: @escaping () async throws -> Void
    ) {
        self.init(action: action) {
            SwiftUI.Label(title, systemImage: systemImage)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        AsyncButton("保存") {
            try await Task.sleep(for: .seconds(2))
        }
        .buttonStyle(.borderedProminent)
        
        AsyncButton("删除", systemImage: "trash") {
            try await Task.sleep(for: .seconds(1))
            throw AppError.deleteFailed(reason: "测试错误")
        }
        .buttonStyle(.bordered)
        .tint(.red)
    }
    .padding()
}
