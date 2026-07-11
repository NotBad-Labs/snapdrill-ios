//
//  NotificationSettingsView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  通知设置页面，配置每日回顾提醒的开关与时间。
//

import SwiftUI
import SnapDrillCore
import SnapDrillData

/// 通知设置页面
struct NotificationSettingsView: View {

    // MARK: - Properties

    @Environment(\.services) private var services

    @AppStorage(UDKey.notificationsEnabled) private var notificationsEnabled = false
    @AppStorage(UDKey.notificationHour) private var notificationHour: Int = 20
    @AppStorage(UDKey.notificationMinute) private var notificationMinute: Int = 0
    @AppStorage(UDKey.soundEnabled) private var soundEnabled = true

    @State private var viewModel: NotificationSettingsViewModel?
    @State private var enableTask: Task<Void, Never>?
    @State private var rescheduleTask: Task<Void, Never>?

    // MARK: - Body

    var body: some View {
        List {
            Section {
                Toggle(L10n.Settings.enableDailyReminder, isOn: Binding(
                    get: { notificationsEnabled },
                    set: { newValue in
                        handleToggle(newValue)
                    }
                ))
                .disabled(viewModel?.isRequesting ?? false)
                .accessibilityIdentifier("settings.notifications.enableToggle")
                .accessibilityHint(L10n.Accessibility.enableReminderHint)

                if notificationsEnabled {
                    DatePicker(
                        L10n.Settings.reminderTime,
                        selection: reminderTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .accessibilityIdentifier("settings.notifications.timePicker")
                }
            } header: {
                Text(L10n.Settings.dailyReminderSection)
            } footer: {
                Text(notificationsEnabled
                    ? L10n.Settings.reminderEnabledFooter(notificationHour, String(format: "%02d", notificationMinute))
                    : L10n.Settings.reminderDisabledFooter
                )
            }

            if notificationsEnabled {
                Section {
                    Toggle(L10n.Settings.sound, isOn: $soundEnabled)
                        .accessibilityIdentifier("settings.notifications.soundToggle")
                        .accessibilityHint(L10n.Accessibility.soundToggleHint)
                } header: {
                    Text(L10n.Settings.notificationStyle)
                } footer: {
                    Text(L10n.Settings.notificationStyleFooter)
                }
            }
        }
        .listStyle(.insetGrouped)
        .accessibilityIdentifier("settings.notifications.root")
        .navigationTitle(L10n.Settings.notificationAndReminder)
        .navigationBarTitleDisplayMode(.inline)
        .alert(L10n.Settings.permissionDeniedTitle, isPresented: Binding(
            get: { viewModel?.isPermissionDenied ?? false },
            set: { newValue in viewModel?.isPermissionDenied = newValue }
        )) {
            Button(L10n.Settings.goToSettings) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(L10n.Common.cancel, role: .cancel) { }
        } message: {
            Text(L10n.Settings.permissionDeniedMessage)
        }
        .alert(L10n.Settings.rescheduleFailedTitle, isPresented: Binding(
            get: { viewModel?.rescheduleError != nil },
            set: { if !$0 { viewModel?.rescheduleError = nil } }
        )) {
            Button(L10n.Common.ok, role: .cancel) { viewModel?.rescheduleError = nil }
        } message: {
            if let errorMessage = viewModel?.rescheduleError {
                Text(errorMessage)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = NotificationSettingsViewModel(
                    notificationService: services.notification
                )
            }
        }
    }

    // MARK: - Private Helpers

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: notificationHour,
                    minute: notificationMinute,
                    second: 0,
                    of: Date()
                ) ?? Date()
            },
            set: { newDate in
                let previousHour = notificationHour
                let previousMinute = notificationMinute
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                let newHour = comps.hour ?? 20
                let newMinute = comps.minute ?? 0
                rescheduleTask?.cancel()
                rescheduleTask = Task {
                    let didReschedule = await viewModel?.reschedule(hour: newHour, minute: newMinute) ?? false
                    if didReschedule {
                        notificationHour = newHour
                        notificationMinute = newMinute
                    } else {
                        notificationHour = previousHour
                        notificationMinute = previousMinute
                    }
                }
            }
        )
    }

    private func handleToggle(_ newValue: Bool) {
        if newValue {
            enableTask?.cancel()
            enableTask = Task {
                let granted = await viewModel?.enable(hour: notificationHour, minute: notificationMinute) ?? false
                notificationsEnabled = granted
            }
        } else {
            enableTask?.cancel()
            enableTask = nil
            viewModel?.disable()
            notificationsEnabled = false
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
