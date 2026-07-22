//
//  PrivacySettingsView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  隐私设置页面，管理数据收集与隐私选项。
//

import SwiftUI
import SnapDrillCore
import SnapDrillData
import UniformTypeIdentifiers

/// 隐私设置页面
struct PrivacySettingsView: View {

    // MARK: - Properties

    @Environment(\.repositories) private var repositories
    @Environment(\.services) private var services

    @State private var showingExportOptions = false
    @State private var viewModel: PrivacySettingsViewModel?

    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.tint)
                        .frame(width: 28, height: 28)
                        .background {
                            Circle()
                                .fill(Color.accentColor.opacity(0.12))
                        }
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.Settings.diagnosticsLocalOnly)
                            .font(.body.weight(.medium))
                        Text(L10n.Settings.dataCollectionFooter)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
                    .accessibilityHint(L10n.Accessibility.analyticsToggleHint)
            } header: {
                Text(L10n.Settings.dataCollection)
            }

            Section {
                Button {
                    showingExportOptions = true
                } label: {
                    HStack {
                        if viewModel?.isExporting == true {
                            ProgressView()
                                .controlSize(.small)
                            Text(L10n.Settings.exporting)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(L10n.Settings.exportMyData)
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.tint)
                        }
                    }
                }
                .disabled(viewModel?.isExporting == true)
                .accessibilityIdentifier("settings.privacyExport.exportButton")
                .accessibilityHint(L10n.Accessibility.exportDataHint)
                .confirmationDialog(L10n.Settings.chooseExportFormat, isPresented: $showingExportOptions, titleVisibility: .visible) {
                    Button(L10n.Settings.jsonFormat) {
                        viewModel?.startExport(format: .json)
                    }
                    Button(L10n.Settings.csvFormat) {
                        viewModel?.startExport(format: .csv)
                    }
                    Button(L10n.Common.cancel, role: .cancel) {}
                }
            } header: {
                Text(L10n.Settings.dataManagement)
            } footer: {
                Text(L10n.Settings.exportDataFooter)
            }

            if let error = viewModel?.exportError {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .listStyle(.insetGrouped)
        .accessibilityIdentifier("settings.privacyExport.root")
        .navigationTitle(L10n.Settings.privacyAndSecurity)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: Binding(
            get: { viewModel?.showingShareSheet ?? false },
            set: { viewModel?.showingShareSheet = $0 }
        )) {
            if let url = viewModel?.exportedFileURL {
                ShareSheet(items: [url])
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = PrivacySettingsViewModel(
                    repositories: repositories,
                    analyticsService: services.analytics
                )
            }
        }
        .onDisappear {
            viewModel?.cancelExport()
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
    .environment(\.services, MockServiceContainer())
}
#endif
