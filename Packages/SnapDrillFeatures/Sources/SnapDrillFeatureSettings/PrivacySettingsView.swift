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
    @Environment(\.analyticsService) private var analyticsService

    @State private var showingExportOptions = false
    @State private var telemetryEnabled = TelemetryGate.isGranted
    @State private var viewModel: PrivacySettingsViewModel?

    var body: some View {
        List {
            Section {
                Toggle(L10n.Settings.telemetryEnabled, isOn: telemetryBinding)
                    .accessibilityHint(L10n.Accessibility.analyticsToggleHint)
            } header: {
                Text(L10n.Settings.dataCollection)
            } footer: {
                Text(L10n.Settings.dataCollectionFooter)
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
            telemetryEnabled = TelemetryGate.isGranted
            if viewModel == nil {
                viewModel = PrivacySettingsViewModel(
                    repositories: repositories,
                    analyticsService: analyticsService
                )
            }
        }
        .onDisappear {
            viewModel?.cancelExport()
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: TelemetryGate.didChangeNotification) {
                telemetryEnabled = TelemetryGate.isGranted
            }
        }
    }

    private var telemetryBinding: Binding<Bool> {
        Binding(
            get: { telemetryEnabled },
            set: { newValue in
                telemetryEnabled = newValue
                TelemetryGate.setGranted(newValue)
            }
        )
    }
}

#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
}
