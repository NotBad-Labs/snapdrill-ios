//
//  SFSymbolPickerView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  教育图标选择器，提供 ~70 个按学科分类的预设 SF Symbols。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI

/// 教育图标选择器
///
/// 提供约 70 个教育/学科相关的 SF Symbol 预设，按类别分组展示。
/// 支持搜索过滤。不开放全量 SF Symbol 访问——预设已覆盖所有学科场景。
public struct SFSymbolPickerView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var selectedSymbol: String

    @State private var searchText = ""

    public init(selectedSymbol: Binding<String>) {
        self._selectedSymbol = selectedSymbol
    }

    // MARK: - 教育图标预设（按类别分组）

    private struct IconCategory: Identifiable {
        let id = UUID()
        let name: String
        let symbols: [String]
    }

    private let categories: [IconCategory] = [
        IconCategory(name: "学术", symbols: [
            "graduationcap.fill",
            "backpack.fill",
            "studentdesk",
            "brain",
            "lightbulb.fill",
            "sparkles"
        ]),
        IconCategory(name: "书籍/阅读", symbols: [
            "book.fill",
            "books.vertical.fill",
            "book.closed.fill",
            "text.book.closed.fill",
            "magazine.fill",
            "newspaper.fill",
            "bookmark.fill"
        ]),
        IconCategory(name: "书写/文具", symbols: [
            "pencil",
            "pencil.tip",
            "pencil.and.ruler",
            "highlighter",
            "eraser.fill",
            "scribble.variable",
            "square.and.pencil"
        ]),
        IconCategory(name: "数学/逻辑", symbols: [
            "function",
            "x.squareroot",
            "number",
            "percent",
            "chart.bar.fill",
            "chart.pie.fill",
            "chart.line.uptrend.xyaxis"
        ]),
        IconCategory(name: "理化/实验", symbols: [
            "atom",
            "flask.fill",
            "molecule",
            "bolt.fill",
            "flame.fill",
            "thermometer.medium",
            "waveform",
            "gyroscope"
        ]),
        IconCategory(name: "生物/自然", symbols: [
            "leaf.fill",
            "tree.fill",
            "dna",
            "pawprint.fill",
            "bird.fill",
            "fish.fill",
            "ant.fill",
            "hare.fill"
        ]),
        IconCategory(name: "地理/地图", symbols: [
            "globe.asia.australia",
            "globe.americas",
            "globe.europe.africa",
            "map.fill",
            "mappin.circle.fill",
            "mountain.2.fill"
        ]),
        IconCategory(name: "历史/社会", symbols: [
            "clock.fill",
            "building.columns.fill",
            "person.2.fill",
            "flag.fill",
            "scroll.fill"
        ]),
        IconCategory(name: "语言/文字", symbols: [
            "character.textbox",
            "character.book.closed.fill",
            "textformat.abc",
            "text.bubble.fill",
            "mic.fill"
        ]),
        IconCategory(name: "音乐/艺术", symbols: [
            "music.note",
            "music.note.list",
            "paintpalette.fill",
            "paintbrush.fill",
            "theatermasks.fill",
            "camera.fill"
        ]),
        IconCategory(name: "体育/运动", symbols: [
            "figure.run",
            "dumbbell.fill",
            "sportscourt.fill",
            "basketball.fill",
            "soccerball",
            "tennis.racket"
        ]),
        IconCategory(name: "技术/信息", symbols: [
            "cpu",
            "desktopcomputer",
            "keyboard.fill",
            "gearshape.fill",
            "wrench.and.screwdriver.fill",
            "network"
        ]),
        IconCategory(name: "文档/分类", symbols: [
            "doc.text.fill",
            "folder.fill",
            "tray.full.fill",
            "archivebox.fill",
            "tag.fill"
        ]),
        IconCategory(name: "度量/奖励", symbols: [
            "ruler.fill",
            "level.fill",
            "star.fill",
            "medal.fill",
            "trophy.fill"
        ])
    ]

    /// 搜索过滤后的类别（空搜索时返回全部）
    private var filteredCategories: [IconCategory] {
        if searchText.isEmpty {
            return categories
        }
        let query = searchText.lowercased()
        return categories.compactMap { cat in
            let matched = cat.symbols.filter {
                $0.lowercased().contains(query) || cat.name.lowercased().contains(query)
            }
            guard !matched.isEmpty else { return nil }
            return IconCategory(name: cat.name, symbols: matched)
        }
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    TextField(L10n.Library.iconSearch, text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()

                // 分类网格
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(filteredCategories) { category in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(category.name)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 4)

                                LazyVGrid(
                                    columns: [GridItem(.adaptive(minimum: 50))],
                                    spacing: 12
                                ) {
                                    ForEach(category.symbols, id: \.self) { symbol in
                                        symbolButton(symbol)
                                    }
                                }
                            }
                        }
                    }
                    .padding()

                    if filteredCategories.isEmpty {
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
            }
        }
    }

    // MARK: - Components

    @ViewBuilder
    private func symbolButton(_ symbol: String) -> some View {
        Button {
            selectedSymbol = symbol
            dismiss()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                if selectedSymbol == symbol {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 2)
                }

                Image(systemName: symbol)
                    .font(.system(size: 24))
                    .foregroundStyle(.primary)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 30, height: 30)
            }
            .frame(width: 50, height: 50)
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.Accessibility.selectIcon(symbol))
        .accessibilityAddTraits(selectedSymbol == symbol ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var selected = "book.fill"
    SFSymbolPickerView(selectedSymbol: $selected)
}
