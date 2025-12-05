//
//  ConfirmationButton.swift
//  NotBad
//
//  需要确认的操作按钮（如删除）
//

import SwiftUI

// MARK: - ConfirmationButton

/// 需要确认的操作按钮
///
/// 点击后显示确认对话框，确认后才执行操作。适用于删除等危险操作。
///
/// ## 使用示例
///
/// ```swift
/// ConfirmationButton(
///     title: "删除错题",
///     message: "确定要删除这道错题吗？此操作不可撤销。",
///     confirmTitle: "删除",
///     role: .destructive
/// ) {
///     try await viewModel.delete(item)
/// } label: {
///     Label("删除", systemImage: "trash")
/// }
/// ```
struct ConfirmationButton<Label: View>: View {
    
    let title: String
    let message: String?
    let confirmTitle: String
    let confirmRole: ButtonRole?
    let action: () async throws -> Void
    let label: () -> Label
    
    @State private var showConfirmation = false
    @State private var isLoading = false
    @State private var error: Error?
    
    init(
        title: String,
        message: String? = nil,
        confirmTitle: String = "确定",
        role: ButtonRole? = nil,
        action: @escaping () async throws -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.confirmRole = role
        self.action = action
        self.label = label
    }
    
    var body: some View {
        Button {
            showConfirmation = true
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
        .confirmationDialog(title, isPresented: $showConfirmation, titleVisibility: .visible) {
            Button(confirmTitle, role: confirmRole) {
                Task {
                    isLoading = true
                    defer { isLoading = false }
                    
                    do {
                        try await action()
                    } catch {
                        self.error = error
                    }
                }
            }
            
            Button("取消", role: .cancel) { }
        } message: {
            if let message {
                Text(message)
            }
        }
        .alert("操作失败", isPresented: .init(
            get: { error != nil },
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

extension ConfirmationButton where Label == SwiftUI.Label<Text, Image> {
    
    /// 创建删除确认按钮
    static func delete(
        title: String = "删除",
        message: String = "确定要删除吗？此操作不可撤销。",
        action: @escaping () async throws -> Void
    ) -> ConfirmationButton {
        ConfirmationButton(
            title: title,
            message: message,
            confirmTitle: "删除",
            role: .destructive,
            action: action
        ) {
            SwiftUI.Label("删除", systemImage: "trash")
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ConfirmationButton(
            title: "删除错题",
            message: "确定要删除这道错题吗？此操作不可撤销。",
            confirmTitle: "删除",
            role: .destructive
        ) {
            try await Task.sleep(for: .seconds(1))
        } label: {
            Label("删除", systemImage: "trash")
        }
        .buttonStyle(.bordered)
        .tint(.red)
        
        ConfirmationButton.delete {
            try await Task.sleep(for: .seconds(1))
        }
        .buttonStyle(.bordered)
        .tint(.red)
    }
    .padding()
}
