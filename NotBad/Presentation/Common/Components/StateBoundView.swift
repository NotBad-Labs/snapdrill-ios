//
//  StateBoundView.swift
//  NotBad
//
//  根据 ViewState 自动切换显示内容的容器视图
//

import SwiftUI

// MARK: - StateBoundView

/// 根据 ViewState 自动切换显示内容
///
/// 自动处理 idle、loading、loaded、error 四种状态的 UI 切换。
///
/// ## 使用示例
///
/// ```swift
/// StateBoundView(state: viewModel.state) { items in
///     List(items) { item in
///         ItemRow(item: item)
///     }
/// }
/// ```
struct StateBoundView<T: Sendable, Content: View>: View {
    
    let state: ViewState<T>
    let content: (T) -> Content
    var onRetry: (() async -> Void)?
    
    init(
        state: ViewState<T>,
        onRetry: (() async -> Void)? = nil,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self.state = state
        self.onRetry = onRetry
        self.content = content
    }
    
    var body: some View {
        switch state {
        case .idle:
            Color.clear
            
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        case .loaded(let data):
            content(data)
            
        case .error(let error):
            errorView(error)
        }
    }
    
    @ViewBuilder
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("加载失败")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if let retry = onRetry {
                Button("重试") {
                    Task {
                        await retry()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("Loaded") {
    StateBoundView(state: ViewState.loaded(["Item 1", "Item 2", "Item 3"])) { items in
        List(items, id: \.self) { item in
            Text(item)
        }
    }
}

#Preview("Loading") {
    StateBoundView(state: ViewState<[String]>.loading) { items in
        List(items, id: \.self) { item in
            Text(item)
        }
    }
}

#Preview("Error") {
    StateBoundView(
        state: ViewState<[String]>.error(AppError.loadFailed(reason: "网络连接失败")),
        onRetry: { }
    ) { items in
        List(items, id: \.self) { item in
            Text(item)
        }
    }
}
