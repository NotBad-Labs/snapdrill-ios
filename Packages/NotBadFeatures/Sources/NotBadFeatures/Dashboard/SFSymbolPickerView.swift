//
//  SFSymbolPickerView.swift
//  NotBadFeatures
//
//  Created by NotBad Labs on 2026/01/01.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SF Symbols 选择器，提供可搜索的系统图标选择功能。
//

import SwiftUI

/// SF Symbols 选择器视图
///
/// 提供可搜索的网格布局，让用户从常用 SF Symbols 中选择图标。
/// 支持手动输入图标名称以访问完整的 5000+ 图标库。
struct SFSymbolPickerView: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var selectedSymbol: String
    
    @State private var searchText = ""
    @State private var manualInput = ""
    @State private var showManualInput = false
    
    // 常用图标分类
    private let categories: [(name: String, symbols: [String])] = [
        ("学习 & 教育", [
            "book", "book.fill", "books.vertical", "books.vertical.fill",
            "text.book.closed", "text.book.closed.fill", "bookmark", "bookmark.fill",
            "graduationcap", "graduationcap.fill", "pencil", "pencil.circle",
            "highlighter", "note.text", "doc.text", "doc.text.fill"
        ]),
        ("科学 & 数学", [
            "function", "sum", "percent", "plusminus",
            "atom", "atom.fill", "flask", "flask.fill",
            "testtube.2", "brain", "brain.head.profile", "waveform.path.ecg"
        ]),
        ("艺术 & 创意", [
            "paintbrush", "paintbrush.fill", "paintpalette", "paintpalette.fill",
            "pencil.tip", "pencil.tip.crop.circle", "scribble", "scribble.variable",
            "theatermasks", "theatermasks.fill", "music.note", "music.note.list"
        ]),
        ("自然 & 地理", [
            "globe", "globe.americas", "globe.europe.africa", "globe.asia.australia",
            "leaf", "leaf.fill", "tree", "tree.fill",
            "flame", "flame.fill", "drop", "drop.fill"
        ]),
        ("运动 & 健康", [
            "sportscourt", "sportscourt.fill", "figure.run", "figure.walk",
            "figure.basketball", "figure.tennis", "football", "football.fill",
            "basketball", "basketball.fill", "soccerball", "tennisball"
        ]),
        ("科技 & 设备", [
            "desktopcomputer", "laptopcomputer", "iphone", "ipad",
            "gamecontroller", "gamecontroller.fill", "keyboard", "keyboard.fill",
            "cpu", "cpu.fill", "memorychip", "memorychip.fill"
        ]),
        ("符号 & 形状", [
            "star", "star.fill", "heart", "heart.fill",
            "circle", "circle.fill", "square", "square.fill",
            "triangle", "triangle.fill", "diamond", "diamond.fill"
        ]),
        ("箭头 & 导航", [
            "arrow.up", "arrow.down", "arrow.left", "arrow.right",
            "arrow.up.circle", "arrow.down.circle", "chevron.up", "chevron.down",
            "location", "location.fill", "mappin", "mappin.circle"
        ]),
        ("媒体 & 相机", [
            "camera", "camera.fill", "video", "video.fill",
            "photo", "photo.fill", "film", "film.fill",
            "speaker", "speaker.fill", "mic", "mic.fill"
        ]),
        ("通用", [
            "house", "house.fill", "gear", "gear.circle",
            "person", "person.fill", "person.2", "person.2.fill",
            "bell", "bell.fill", "envelope", "envelope.fill",
            "calendar", "calendar.circle", "clock", "clock.fill",
            "folder", "folder.fill", "tag", "tag.fill",
            "flag", "flag.fill", "link", "link.circle"
        ])
    ]
    
    /// 所有图标的扁平列表
    private var allSymbols: [String] {
        categories.flatMap { $0.symbols }
    }
    
    /// 过滤后的图标
    private var filteredSymbols: [String] {
        if searchText.isEmpty {
            return allSymbols
        }
        return allSymbols.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("搜索图标名称 (英文)", text: $searchText)
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
                        Text("手动输入图标名称")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            TextField("例如: book.circle.fill", text: $manualInput)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            
                            // 预览
                            if !manualInput.isEmpty {
                                Image(systemName: manualInput)
                                    .font(.title2)
                                    .frame(width: 32, height: 32)
                            }
                            
                            Button("使用") {
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
                    if searchText.isEmpty && !showManualInput {
                        // 分类显示
                        LazyVStack(alignment: .leading, spacing: 20) {
                            ForEach(categories, id: \.name) { category in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(category.name)
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    LazyVGrid(
                                        columns: [GridItem(.adaptive(minimum: 50))],
                                        spacing: 12
                                    ) {
                                        ForEach(category.symbols, id: \.self) { symbol in
                                            symbolButton(symbol)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    } else {
                        // 搜索结果
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 50))],
                            spacing: 12
                        ) {
                            ForEach(filteredSymbols, id: \.self) { symbol in
                                symbolButton(symbol)
                            }
                        }
                        .padding()
                        
                        if filteredSymbols.isEmpty {
                            ContentUnavailableView(
                                "未找到匹配的图标",
                                systemImage: "magnifyingglass",
                                description: Text("尝试搜索其他关键词，或点击「手动输入」使用完整的 SF Symbols")
                            )
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("选择图标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(showManualInput ? "收起" : "手动输入") {
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
                // Liquid Glass Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                // Selection Highlight
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
