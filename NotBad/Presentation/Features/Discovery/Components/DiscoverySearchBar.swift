//
//  DiscoverySearchBar.swift
//  NotBad
//
//  位置: Presentation/Features/Discovery/Components/DiscoverySearchBar.swift
//  职责: Discovery页面搜索栏组件
//

import SwiftUI

// MARK: - DiscoverySearchBar

/// Discovery搜索栏组件
/// 
/// 企业级特性：
/// - 防抖搜索：避免频繁API调用
/// - 键盘管理：智能焦点控制和提交处理
/// - 状态反馈：清晰的加载和错误状态
/// - 无障碍支持：语音标签和辅助功能
/// - 性能优化：合理的状态更新和渲染控制
/// 
/// 使用示例：
/// ```swift
/// DiscoverySearchBar(viewModel: viewModel)
/// ```
struct DiscoverySearchBar: View {
    /// 绑定到ViewModel，实现双向数据绑定
    @Bindable var viewModel: DiscoveryViewModel
    
    /// 键盘焦点状态管理
    @FocusState private var isSearchFocused: Bool
    
    /// 防抖计时器：防止用户快速输入时频繁触发搜索
    @State private var searchDebounceTimer: Timer?
    
    /// 搜索历史建议（企业级功能预留）
    @State private var showSearchSuggestions: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 主搜索栏
            searchBarContent
            
            // 搜索建议下拉（预留扩展功能）
            if showSearchSuggestions && isSearchFocused {
                searchSuggestionsView
            }
        }
    }
    
    /// 主搜索栏内容
    private var searchBarContent: some View {
        HStack(spacing: 12) {
            // 搜索图标
            searchIcon
            
            // 搜索输入框
            searchTextField
            
            // 清除/取消按钮
            actionButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(searchBarBackground)
        .cornerRadius(12)
        .overlay(searchLoadingOverlay)
        .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
    }
    
    /// 搜索图标
    private var searchIcon: some View {
        Image(systemName: "magnifyingglass")
            .foregroundColor(isSearchFocused ? .accentColor : .secondary)
            .font(.subheadline)
            .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
    }
    
    /// 搜索输入框
    private var searchTextField: some View {
        TextField("搜索题目、用户或话题...", text: $viewModel.searchText)
            .textFieldStyle(PlainTextFieldStyle())
            .focused($isSearchFocused)
            .onSubmit {
                performSearch()
            }
            .onChange(of: viewModel.searchText) { oldValue, newValue in
                handleSearchTextChange(newValue)
            }
            .submitLabel(.search)
            // 无障碍支持
            .accessibilityLabel("搜索输入框")
            .accessibilityHint("输入关键词搜索内容")
    }
    
    /// 操作按钮（清除/取消）
    private var actionButton: some View {
        Group {
            if !viewModel.searchText.isEmpty {
                // 清除按钮
                Button(action: clearSearch) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .accessibilityLabel("清除搜索")
                .transition(.scale.combined(with: .opacity))
            } else if isSearchFocused {
                // 取消按钮
                Button("取消") {
                    cancelSearch()
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.searchText.isEmpty)
        .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
    }
    
    /// 搜索栏背景
    private var searchBarBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSearchFocused ? Color(.systemBackground) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSearchFocused ? Color.accentColor : Color.clear, lineWidth: 1)
            )
    }
    
    /// 搜索加载覆盖层
    private var searchLoadingOverlay: some View {
        Group {
            if viewModel.isLoading && !viewModel.searchText.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.trailing, 8)
                }
            }
        }
    }
    
    /// 搜索建议视图（企业级功能预留）
    private var searchSuggestionsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // TODO: 实现搜索历史和热门搜索建议
            ForEach(["数学", "英语", "物理"], id: \.self) { suggestion in
                Button(action: {
                    selectSuggestion(suggestion)
                }) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        
                        Text(suggestion)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                
                if suggestion != "物理" {
                    Divider()
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.top, 4)
    }
    
    // MARK: - Actions
    
    /// 执行搜索
    private func performSearch() {
        // 取消键盘焦点
        isSearchFocused = false
        showSearchSuggestions = false
        
        // 执行搜索（如果有内容）
        if !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Task {
                await viewModel.searchContent()
            }
        }
    }
    
    /// 清除搜索
    private func clearSearch() {
        viewModel.searchText = ""
        
        // 轻微触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    /// 取消搜索
    private func cancelSearch() {
        isSearchFocused = false
        showSearchSuggestions = false
        viewModel.searchText = ""
    }
    
    /// 选择搜索建议
    private func selectSuggestion(_ suggestion: String) {
        viewModel.searchText = suggestion
        performSearch()
    }
    
    /// 处理搜索文本变化（防抖）
    private func handleSearchTextChange(_ newValue: String) {
        // 取消之前的计时器
        searchDebounceTimer?.invalidate()
        
        // 如果输入不为空，显示搜索建议
        showSearchSuggestions = !newValue.isEmpty && isSearchFocused
        
        // 防抖搜索：500ms后执行搜索
        if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                Task { @MainActor in
                    await viewModel.searchContent()
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct DiscoverySearchBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            DiscoverySearchBar(viewModel: DiscoveryViewModel())
            Spacer()
        }
        .padding()
    }
}
#endif