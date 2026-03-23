//
//  SourceManagerView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/01/01.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  来源管理视图，允许用户添加、删除或重命名来源。
//

import SwiftUI
import SnapDrillCore
import SnapDrillData
import SnapDrillUI

public struct SourceManagerView: View {

    // MARK: - Properties

    @Environment(\.repositories) private var repositories

    @State private var viewModel: SourceManagerViewModel?

    @State private var showingAddSheet = false
    @State private var editingSource: SourceModel?

    public init() {}

    // MARK: - Body

    public var body: some View {
        List {
                if let vm = viewModel {
                    ForEach(vm.sources) { source in
                        Button {
                            editingSource = source
                        } label: {
                            HStack {
                                Image(systemName: source.icon)
                                    .foregroundStyle(Color(hex: source.colorHex))
                                    .frame(width: 24)
                                Text(source.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                        }
                    }
                    .onDelete(perform: { offsets in vm.delete(at: offsets) })
                }
            }
            .alert(L10n.Library.cannotDeleteInUse, isPresented: Binding(
                get: { viewModel?.isDeletingInUse ?? false },
                set: { newValue in viewModel?.isDeletingInUse = newValue }
            )) {
                Button(L10n.Common.ok, role: .cancel) { }
            } message: {
                Text(L10n.Library.sourceHasItems(viewModel?.pendingDeletionName ?? ""))
            }
            .navigationTitle(L10n.Library.sourceManager)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSheet = true }, label: {
                        Image(systemName: "plus")
                    })
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                EditSourceView(source: nil, viewModel: viewModel)
            }
            .sheet(item: $editingSource) { source in
                EditSourceView(source: source, viewModel: viewModel)
            }
            .task {
                if viewModel == nil {
                    viewModel = SourceManagerViewModel(repositories: repositories)
                }
                viewModel?.loadData()
            }
    }
}

struct EditSourceView: View {
    @Environment(\.dismiss) private var dismiss

    /// 如果为 nil，则为添加模式；否则为编辑模式
    let source: SourceModel?
    let viewModel: SourceManagerViewModel?

    @State private var name: String = ""
    @State private var selectedIcon: String = "doc.text"
    @State private var selectedColorHex: String = "#808080"
    @State private var customColor: Color = .gray
    @State private var useCustomColor: Bool = false
    @State private var showSymbolPicker: Bool = false

    let colors = ["#E57373", "#4FC3F7", "#AED581", "#7986CB", "#F06292", "#FFB74D", "#9575CD", "#90A4AE", "#808080"]

    private var isEditing: Bool { source != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.Library.name) {
                    TextField(L10n.Library.namePlaceholder, text: $name)
                }

                Section(L10n.Library.icon) {
                    Button {
                        showSymbolPicker = true
                    } label: {
                        HStack {
                            Image(systemName: selectedIcon)
                                .font(.title2)
                                .frame(width: 32, height: 32)
                                .foregroundStyle(useCustomColor ? customColor : Color(hex: selectedColorHex))

                            Text(selectedIcon)
                                .foregroundStyle(.primary)

                            Spacer()

                            Text(L10n.Library.iconPicker)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section(L10n.Library.color) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                        ForEach(colors, id: \.self) { hex in
                            Button {
                                selectedColorHex = hex
                                useCustomColor = false
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: (!useCustomColor && selectedColorHex == hex) ? 2 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(L10n.Library.color)
                        }
                    }
                    .padding(.vertical, 8)

                    HStack {
                        Text(L10n.Library.customColor)
                        Spacer()
                        ColorPicker("", selection: $customColor, supportsOpacity: false)
                            .labelsHidden()
                            .onChange(of: customColor) { _, _ in
                                useCustomColor = true
                            }

                        if useCustomColor {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? L10n.Library.editSource : L10n.Library.addSource)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.save) {
                        if saveSource() {
                            dismiss()
                        }
                    }
                    .disabled(!canSave)
                }
            }
            .alert(L10n.Library.duplicateName, isPresented: Binding(
                get: { viewModel?.isDuplicateName ?? false },
                set: { newValue in viewModel?.isDuplicateName = newValue }
            )) {
                Button(L10n.Common.ok, role: .cancel) { }
            } message: {
                Text(L10n.Library.duplicateNameMessage(viewModel?.duplicateNameValue ?? ""))
            }
            .sheet(isPresented: $showSymbolPicker) {
                SFSymbolPickerView(selectedSymbol: $selectedIcon)
            }
            .onAppear {
                if let source {
                    name = source.name
                    selectedIcon = source.icon
                    selectedColorHex = source.colorHex

                    if !colors.contains(source.colorHex) {
                        customColor = Color(hex: source.colorHex)
                        useCustomColor = true
                    }
                    if source.colorHex.isEmpty {
                        selectedColorHex = "#808080"
                    }
                }
            }
        }
    }

    private var finalColorHex: String {
        if useCustomColor {
            return customColor.toHex() ?? "#808080"
        } else {
            return selectedColorHex
        }
    }

    @discardableResult
    func saveSource() -> Bool {
        viewModel?.saveSource(
            source: source,
            name: name.trimmingCharacters(in: .whitespaces),
            selectedIcon: selectedIcon,
            finalColorHex: finalColorHex
        ) ?? false
    }
}

#Preview {
    SourceManagerView()
}
