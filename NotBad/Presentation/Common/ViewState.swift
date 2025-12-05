//
//  ViewState.swift
//  NotBad
//
//  ViewModel 统一状态机类型
//

import Foundation

// MARK: - ViewState

/// ViewModel 统一状态类型
///
/// 表示视图的加载状态，用于 ViewModel 状态管理。
///
/// ## 使用示例
///
/// ```swift
/// @Observable
/// final class ListViewModel {
///     var state: ViewState<[Item]> = .idle
///
///     func load() async {
///         state = .loading
///         do {
///             let items = try await fetchItems()
///             state = .loaded(items)
///         } catch {
///             state = .error(error)
///         }
///     }
/// }
/// ```
///
/// ## SwiftUI 集成
///
/// ```swift
/// var body: some View {
///     switch viewModel.state {
///     case .idle:
///         EmptyView()
///     case .loading:
///         ProgressView()
///     case .loaded(let items):
///         List(items) { ... }
///     case .error(let error):
///         ErrorView(error: error)
///     }
/// }
/// ```
enum ViewState<T: Sendable>: Sendable {
    
    /// 初始状态，尚未加载
    case idle
    
    /// 加载中
    case loading
    
    /// 加载成功
    case loaded(T)
    
    /// 加载失败
    case error(Error)
    
    // MARK: - Convenience Properties
    
    /// 是否正在加载
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    /// 是否已加载数据
    var isLoaded: Bool {
        if case .loaded = self { return true }
        return false
    }
    
    /// 是否有错误
    var isError: Bool {
        if case .error = self { return true }
        return false
    }
    
    /// 获取加载的数据（如果有）
    var data: T? {
        if case .loaded(let data) = self { return data }
        return nil
    }
    
    /// 获取错误（如果有）
    var error: Error? {
        if case .error(let error) = self { return error }
        return nil
    }
}

// MARK: - ViewState + Equatable (for T: Equatable)

extension ViewState: Equatable where T: Equatable {
    static func == (lhs: ViewState<T>, rhs: ViewState<T>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case (.loaded(let lhsData), .loaded(let rhsData)):
            return lhsData == rhsData
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - AsyncViewState

/// 支持刷新状态的视图状态
///
/// 在 `ViewState` 基础上增加了刷新状态，适用于支持下拉刷新的列表。
enum AsyncViewState<T: Sendable>: Sendable {
    
    /// 初始状态
    case idle
    
    /// 首次加载
    case loading
    
    /// 加载成功
    case loaded(T)
    
    /// 刷新中（已有数据，正在刷新）
    case refreshing(T)
    
    /// 加载更多（分页）
    case loadingMore(T)
    
    /// 加载失败
    case error(Error)
    
    // MARK: - Convenience Properties
    
    /// 当前数据（无论什么状态）
    var data: T? {
        switch self {
        case .loaded(let data), .refreshing(let data), .loadingMore(let data):
            return data
        default:
            return nil
        }
    }
    
    /// 是否正在进行任何加载操作
    var isLoading: Bool {
        switch self {
        case .loading, .refreshing, .loadingMore:
            return true
        default:
            return false
        }
    }
    
    /// 是否首次加载
    var isInitialLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

// MARK: - FormState

/// 表单状态
///
/// 用于表单提交场景的状态管理。
enum FormState: Sendable {
    
    /// 待提交
    case idle
    
    /// 验证中
    case validating
    
    /// 提交中
    case submitting
    
    /// 提交成功
    case success
    
    /// 提交失败
    case failure(Error)
    
    /// 是否可以提交
    var canSubmit: Bool {
        if case .idle = self { return true }
        if case .failure = self { return true }
        return false
    }
    
    /// 是否正在处理
    var isProcessing: Bool {
        switch self {
        case .validating, .submitting:
            return true
        default:
            return false
        }
    }
}
