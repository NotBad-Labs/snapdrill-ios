//
//  SmartPaperView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/04/08.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  智能组卷配置页 — 选题参数 + PDF 选项 + 预览入口。
//

import SwiftUI
import SnapDrillCore
import SnapDrillData
import SnapDrillUI

/// 智能组卷配置页
///
/// 家长选择学科、难度、数量后一键生成"最需要复习的错题卷"。
/// 选题基于 SM-2 紧迫度排序，复用现有 ExportPreviewView 预览 PDF。
struct SmartPaperView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.repositories) private var repositories

    @State private var viewModel: SmartPaperViewModel?
    @State private var showingPDFPreview = false
    @State private var showProGate = false

    // TODO: 替换为 StoreKit 订阅状态检查（#479 就绪后）
    private var isProUser: Bool { true }

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    smartPaperForm(vm: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(L10n.SmartPaper.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.close) { dismiss() }
                }
            }
            .task {
                if viewModel == nil {
                    // 在 MainActor 上下文中捕获，避免 Task 闭包中跨 actor 访问
                    let repos = repositories
                    let vm = SmartPaperViewModel(repositories: repos)
                    self.viewModel = vm
                    vm.loadInitialData()
                }
            }
            .alert(viewModel?.errorMessage ?? "", isPresented: Binding(
                get: { viewModel?.errorMessage != nil },
                set: { if !$0 { viewModel?.errorMessage = nil } }
            )) {
                Button(L10n.Common.ok, role: .cancel) {}
            }
        }
    }

    // MARK: - Form

    @ViewBuilder
    private func smartPaperForm(vm: SmartPaperViewModel) -> some View {
        List {
            selectionConfigSection(vm: vm)
            pdfOptionsSection(vm: vm)
            selectionResultSection(vm: vm)
            generateButtonSection(vm: vm)
        }
        .onChange(of: vm.questionCount) { _, _ in vm.refreshSelection() }
        .onChange(of: vm.selectedSubjects) { _, _ in vm.refreshSelection() }
        .onChange(of: vm.selectedDifficulties) { _, _ in vm.refreshSelection() }
        .navigationDestination(isPresented: $showingPDFPreview) {
            ExportPreviewView(
                items: vm.selectedItems,
                options: vm.pdfOptions
            )
        }
    }

    // MARK: - 选题配置

    @ViewBuilder
    private func selectionConfigSection(vm: SmartPaperViewModel) -> some View {
        Section {
            Picker(L10n.SmartPaper.questionCount, selection: Bindable(vm).questionCount) {
                Text("5").tag(5)
                Text("10").tag(10)
                Text("15").tag(15)
                Text("20").tag(20)
            }

            NavigationLink {
                subjectSelectionList(vm: vm)
            } label: {
                HStack {
                    Text(L10n.SmartPaper.subjectFilter)
                    Spacer()
                    Text(vm.selectedSubjects.isEmpty
                         ? L10n.SmartPaper.allSubjects
                         : vm.selectedSubjects.joined(separator: ", "))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            NavigationLink {
                difficultySelectionList(vm: vm)
            } label: {
                HStack {
                    Text(L10n.SmartPaper.difficultyFilter)
                    Spacer()
                    Text(vm.selectedDifficulties.isEmpty
                         ? L10n.SmartPaper.allDifficulties
                         : vm.selectedDifficulties.sorted().map { "\($0)" }.joined(separator: ", "))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - PDF 选项

    @ViewBuilder
    private func pdfOptionsSection(vm: SmartPaperViewModel) -> some View {
        Section(L10n.Export.pdfOptions) {
            Toggle(L10n.Export.hideAnswers, isOn: Bindable(vm).hideAnswers)
            if vm.hideAnswers {
                Toggle(L10n.Export.showBlankArea, isOn: Bindable(vm).showBlankAnswerArea)
            }
            Toggle(L10n.Export.showHeader, isOn: Bindable(vm).showHeader)
            Picker(L10n.Export.itemsPerPage, selection: Bindable(vm).itemsPerPage) {
                Text("1").tag(1)
                Text("2").tag(2)
                Text("4").tag(4)
            }
        }
    }

    // MARK: - 选题结果

    @ViewBuilder
    private func selectionResultSection(vm: SmartPaperViewModel) -> some View {
        Section {
            if vm.selectedItems.isEmpty {
                ContentUnavailableView {
                    Label(L10n.SmartPaper.noItemsTitle, systemImage: "doc.questionmark")
                } description: {
                    Text(L10n.SmartPaper.noItemsMessage)
                }
            } else {
                HStack {
                    Spacer()
                    Text(L10n.SmartPaper.selectedCount(vm.selectedItems.count))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }

    // MARK: - 生成按钮

    @ViewBuilder
    private func generateButtonSection(vm: SmartPaperViewModel) -> some View {
        Section {
            Button {
                if isProUser {
                    showingPDFPreview = true
                } else {
                    showProGate = true
                }
            } label: {
                HStack {
                    Spacer()
                    Label(L10n.SmartPaper.generate, systemImage: "doc.richtext")
                        .font(.headline)
                    Spacer()
                }
            }
            .disabled(vm.selectedItems.isEmpty)
        }
        .alert(L10n.SmartPaper.proRequired, isPresented: $showProGate) {
            Button(L10n.Common.ok, role: .cancel) {}
        }
    }

    // MARK: - 学科勾选列表

    private func subjectSelectionList(vm: SmartPaperViewModel) -> some View {
        List {
            Button {
                vm.selectedSubjects.removeAll()
            } label: {
                HStack {
                    Text(L10n.SmartPaper.allSubjects)
                    Spacer()
                    if vm.selectedSubjects.isEmpty {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                }
            }

            ForEach(vm.availableSubjects, id: \.self) { subject in
                Button {
                    if vm.selectedSubjects.contains(subject) {
                        vm.selectedSubjects.remove(subject)
                    } else {
                        vm.selectedSubjects.insert(subject)
                    }
                } label: {
                    HStack {
                        Text(subject)
                        Spacer()
                        if vm.selectedSubjects.contains(subject) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
        }
        .navigationTitle(L10n.SmartPaper.subjectFilter)
    }

    // MARK: - 难度勾选列表

    private func difficultySelectionList(vm: SmartPaperViewModel) -> some View {
        List {
            Button {
                vm.selectedDifficulties.removeAll()
            } label: {
                HStack {
                    Text(L10n.SmartPaper.allDifficulties)
                    Spacer()
                    if vm.selectedDifficulties.isEmpty {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                }
            }

            ForEach(Difficulty.allCases) { difficulty in
                Button {
                    if vm.selectedDifficulties.contains(difficulty.rawValue) {
                        vm.selectedDifficulties.remove(difficulty.rawValue)
                    } else {
                        vm.selectedDifficulties.insert(difficulty.rawValue)
                    }
                } label: {
                    HStack {
                        HStack(spacing: 2) {
                            ForEach(0..<difficulty.starCount, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        Spacer()
                        if vm.selectedDifficulties.contains(difficulty.rawValue) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
                .accessibilityLabel(L10n.SmartPaper.difficultyFilter + " \(difficulty.starCount)")
            }
        }
        .navigationTitle(L10n.SmartPaper.difficultyFilter)
    }
}
