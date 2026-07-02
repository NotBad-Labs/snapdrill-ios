//
//  SmartPaperView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
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
/// 用户选择分类与数量后一键生成资料集。
/// 免费层随机抽取，Pro 层基于 SM-2 紧迫度排序，复用现有 ExportPreviewView 预览 PDF。
struct SmartPaperView: View {

    @Environment(\.repositories) private var repositories
    @Environment(\.services) private var services

    @State private var viewModel: SmartPaperViewModel?
    @State private var showingPDFPreview = false
    @State private var quotaGuidanceMessage: String?

    // TODO: #479 — 替换为 StoreKit 订阅状态检查
    private var isProUser: Bool { services.proEntitlement.isProUser }

    init() {}

    var body: some View {
        Group {
            if let vm = viewModel {
                smartPaperForm(vm: vm)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(L10n.SmartPaper.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                // 在 MainActor 上下文中捕获，避免 Task 闭包中跨 actor 访问
                let repos = repositories
                let vm = SmartPaperViewModel(repositories: repos, deletionScheduler: services.deletionScheduler)
                self.viewModel = vm
                vm.loadInitialData(isProUser: isProUser)
            }
        }
        .alert(viewModel?.errorMessage ?? "", isPresented: Binding(
            get: { viewModel?.errorMessage != nil },
            set: { if !$0 { viewModel?.errorMessage = nil } }
        )) {
            Button(L10n.Common.ok, role: .cancel) {}
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
        .onChange(of: vm.questionCount) { _, _ in vm.refreshSelection(isProUser: isProUser) }
        .onChange(of: vm.selectedCategoryValueIds) { _, _ in vm.refreshSelection(isProUser: isProUser) }
        .navigationDestination(isPresented: $showingPDFPreview) {
            ExportPreviewView(
                items: vm.selectedItems,
                options: vm.pdfOptions,
                onExport: isProUser ? nil : { vm.consumeFreeQuota() }
            )
        }
        .overlay(alignment: .bottom) {
            if let quotaGuidanceMessage {
                SmartPaperQuotaToast(message: quotaGuidanceMessage)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .accessibilityIdentifier("smartPaper.root")
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
                categorySelectionList(vm: vm)
            } label: {
                HStack {
                    Text(L10n.SmartPaper.categoryFilter)
                    Spacer()
                    Text(vm.selectedCategoryValueIds.isEmpty
                         ? L10n.SmartPaper.allCategories
                         : vm.selectedCategoryNames)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
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
                switch vm.prepareGeneration(isProUser: isProUser) {
                case .preview:
                    showingPDFPreview = true
                case .quotaExceeded:
                    showQuotaGuidance()
                case .unavailable:
                    break
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
    }

    private func showQuotaGuidance() {
        let message = L10n.SmartPaper.freeQuotaUsed
        quotaGuidanceMessage = message
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            if quotaGuidanceMessage == message {
                quotaGuidanceMessage = nil
            }
        }
    }

    // MARK: - 分类勾选列表

    private func categorySelectionList(vm: SmartPaperViewModel) -> some View {
        List {
            Button {
                vm.selectedCategoryValueIds.removeAll()
            } label: {
                HStack {
                    Text(L10n.SmartPaper.allCategories)
                    Spacer()
                    if vm.selectedCategoryValueIds.isEmpty {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                }
            }

            ForEach(vm.availableCategories) { value in
                Button {
                    if vm.selectedCategoryValueIds.contains(value.id) {
                        vm.selectedCategoryValueIds.remove(value.id)
                    } else {
                        vm.selectedCategoryValueIds.insert(value.id)
                    }
                } label: {
                    HStack {
                        Text(value.name)
                        Spacer()
                        if vm.selectedCategoryValueIds.contains(value.id) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
        }
        .navigationTitle(L10n.SmartPaper.categoryFilter)
    }
}

private struct SmartPaperQuotaToast: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.black.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 8)
    }
}
