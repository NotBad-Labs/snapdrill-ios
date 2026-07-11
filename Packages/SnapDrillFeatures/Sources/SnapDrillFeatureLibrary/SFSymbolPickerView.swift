//
//  SFSymbolPickerView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  图标选择器，提供一组适合个人资料和分类的预设 SF Symbols。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI

/// 图标选择器
///
/// 提供一组通用 SF Symbol 预设，按类别分组展示。
/// 支持搜索过滤。不开放全量 SF Symbol 访问，避免图标选择器失焦。
public struct SFSymbolPickerView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var selectedSymbol: String

    @State private var searchText = ""

    public init(selectedSymbol: Binding<String>) {
        self._selectedSymbol = selectedSymbol
    }

    // MARK: - Icon Presets

    private struct IconCategory: Identifiable {
        let id: String
        let name: String
        let symbols: [String]
    }

    private var categories: [IconCategory] {
        [
            IconCategory(id: "common", name: L10n.Library.iconCategoryCommon, symbols: [
                "circle",
                "circle.fill",
                "star.fill",
                "heart.fill",
                "bookmark.fill",
                "tag",
                "tag.fill",
                "flag.fill",
                "pin.fill",
                "checkmark.circle.fill"
            ]),
            IconCategory(id: "documents", name: L10n.Library.iconCategoryDocuments, symbols: [
                "doc.text.fill",
                "folder.fill",
                "tray.full.fill",
                "archivebox.fill",
                "note.text",
                "clipboard.fill",
                "paperclip",
                "book.closed.fill"
            ]),
            IconCategory(id: "work", name: L10n.Library.iconCategoryWork, symbols: [
                "briefcase.fill",
                "calendar",
                "clock.fill",
                "list.bullet.rectangle",
                "checklist",
                "chart.bar.fill",
                "chart.pie.fill",
                "chart.line.uptrend.xyaxis"
            ]),
            IconCategory(id: "ideas", name: L10n.Library.iconCategoryIdeas, symbols: [
                "brain",
                "lightbulb.fill",
                "sparkles",
                "wand.and.stars",
                "paintpalette.fill",
                "camera.fill",
                "music.note",
                "theatermasks.fill"
            ]),
            IconCategory(id: "writing", name: L10n.Library.iconCategoryWriting, symbols: [
                "pencil",
                "pencil.tip",
                "pencil.and.ruler",
                "highlighter",
                "scribble.variable",
                "square.and.pencil",
                "textformat.abc",
                "text.bubble.fill"
            ]),
            IconCategory(id: "places", name: L10n.Library.iconCategoryPlaces, symbols: [
                "globe",
                "map.fill",
                "mappin.circle.fill",
                "house.fill",
                "building.2.fill",
                "car.fill",
                "airplane",
                "location.fill"
            ]),
            IconCategory(id: "people", name: L10n.Library.iconCategoryPeople, symbols: [
                "person.fill",
                "person.2.fill",
                "person.crop.circle.fill",
                "figure.walk",
                "figure.run",
                "hand.raised.fill",
                "message.fill",
                "phone.fill"
            ]),
            IconCategory(id: "nature", name: L10n.Library.iconCategoryNature, symbols: [
                "leaf.fill",
                "tree.fill",
                "sun.max.fill",
                "moon.fill",
                "cloud.fill",
                "drop.fill",
                "flame.fill",
                "snowflake"
            ]),
            IconCategory(id: "tools", name: L10n.Library.iconCategoryTools, symbols: [
                "gearshape.fill",
                "wrench.and.screwdriver.fill",
                "hammer.fill",
                "slider.horizontal.3",
                "cpu",
                "desktopcomputer",
                "keyboard.fill",
                "network"
            ]),
            IconCategory(id: "measurement", name: L10n.Library.iconCategoryMeasurement, symbols: [
                "ruler.fill",
                "level.fill",
                "number",
                "percent",
                "function",
                "waveform",
                "timer",
                "speedometer"
            ])
        ]
    }

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
            return IconCategory(id: cat.id, name: cat.name, symbols: matched)
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
                        .accessibilityIdentifier("symbolPicker.searchField")
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
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color(UIColor.label))
                                    .padding(.horizontal, 4)
                                    .accessibilityIdentifier("symbolPicker.category.\(category.id)")

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
                        .accessibilityIdentifier("symbolPicker.empty")
                    }
                }
            }
            .navigationTitle(L10n.Library.iconPicker)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(L10n.Common.cancel)
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
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                }

                Image(systemName: symbol)
                    .font(.system(size: 24))
                    .foregroundStyle(.primary)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 30, height: 30)

                if selectedSymbol == symbol {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.accentColor, Color(UIColor.systemBackground))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(3)
                        .accessibilityHidden(true)
                }
            }
            .frame(width: 50, height: 50)
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.Accessibility.selectIcon(symbol))
        .accessibilityIdentifier("symbolPicker.symbol.\(symbol)")
        .accessibilityAddTraits(selectedSymbol == symbol ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var selected = "book.fill"
    SFSymbolPickerView(selectedSymbol: $selected)
}
