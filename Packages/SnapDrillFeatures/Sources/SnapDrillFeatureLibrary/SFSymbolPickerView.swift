//
//  SFSymbolPickerView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/01/01.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SF Symbols 选择器，提供可搜索的系统图标选择功能。
//

import SwiftUI
import SnapDrillCore

/// SF Symbols 选择器视图
///
/// 提供可搜索的网格布局，让用户从常用 SF Symbols 中选择图标。
/// 支持手动输入图标名称以访问完整的 5000+ 图标库。
public struct SFSymbolPickerView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var selectedSymbol: String

    @State private var searchText = ""
    @State private var manualInput = ""
    @State private var showManualInput = false

    public init(selectedSymbol: Binding<String>) {
        self._selectedSymbol = selectedSymbol
    }
    
    // 预设教育图标集（~20 个，PR§系统字段选项管理定义）
    private let presetIcons: [String] = [
        "function",              // 数学
        "book.fill",             // 语文
        "character.textbox",     // 英语
        "flask.fill",            // 化学
        "atom",                  // 物理
        "leaf.fill",             // 生物
        "globe.asia.australia",  // 地理
        "clock.fill",            // 历史
        "person.2.fill",         // 政治/社会
        "paintpalette.fill",     // 美术
        "music.note",            // 音乐
        "figure.run",            // 体育
        "cpu",                   // 信息技术
        "brain",                 // 科学
        "graduationcap.fill",    // 综合
        "star.fill",             // 通用
        "bookmark.fill",         // 阅读
        "pencil",                // 写作
        "doc.text.fill",         // 试卷
        "folder.fill"            // 其他
    ]
    
    /// 过滤后的图标
    private var filteredIcons: [String] {
        if searchText.isEmpty {
            return presetIcons
        }
        return presetIcons.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField(L10n.Library.iconSearch, text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
                
                // 手动输入区域
                if showManualInput {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.Library.iconManualInput)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            TextField(L10n.Library.iconManualPlaceholder, text: $manualInput)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            
                            // 预览
                            if !manualInput.isEmpty {
                                Image(systemName: manualInput)
                                    .font(.title2)
                                    .frame(width: 32, height: 32)
                            }
                            
                            Button(L10n.Common.ok) {
                                if !manualInput.isEmpty {
                                    selectedSymbol = manualInput
                                    dismiss()
                                }
                            }
                            .disabled(manualInput.isEmpty)
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                
                // 图标网格
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 50))],
                        spacing: 12
                    ) {
                        ForEach(filteredIcons, id: \.self) { symbol in
                            symbolButton(symbol)
                        }
                    }
                    .padding()

                    if filteredIcons.isEmpty {
                        ContentUnavailableView(
                            L10n.Library.noSearchResults,
                            systemImage: "magnifyingglass",
                            description: Text(L10n.Library.noSearchResultsHint)
                        )
                        .padding()
                    }
                }
            }
            .navigationTitle(L10n.Library.iconPicker)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(showManualInput ? L10n.Common.close : L10n.Library.iconManualInput) {
                        withAnimation {
                            showManualInput.toggle()
                        }
                    }
                    .font(.subheadline)
                }
            }
        }
    }
    
    @ViewBuilder
    private func symbolButton(_ symbol: String) -> some View {
        Button {
            selectedSymbol = symbol
            dismiss()
        } label: {
            ZStack {
                // 毛玻璃背景
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                // 选中高亮
                if selectedSymbol == symbol {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 2)
                }
                
                Image(systemName: symbol)
                    .font(.system(size: 24))
                    .foregroundStyle(.primary) // Use primary color for native look
                    .symbolRenderingMode(.hierarchical) // The true "native" system look
                    .frame(width: 30, height: 30)
            }
            .frame(width: 50, height: 50)
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var selected = "book"
    SFSymbolPickerView(selectedSymbol: $selected)
}
