//
//  NotificationSettingsView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/01/02.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  通知设置页面，配置每日复习提醒的开关与时间。
//

import SwiftUI
import SnapDrillCore

/// 通知设置页面
struct NotificationSettingsView: View {

    // MARK: - Properties

    @Environment(\.services) private var services

    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("notificationHour") private var notificationHour: Int = 20
    @AppStorage("notificationMinute") private var notificationMinute: Int = 0
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("badgeEnabled") private var badgeEnabled = true

    @State private var viewModel: NotificationSettingsViewModel?

    // MARK: - Body

    var body: some View {
        List {
            Section {
                Toggle("启用每日复习提醒", isOn: Binding(
                    get: { notificationsEnabled },
                    set: { newValue in
                        handleToggle(newValue)
                    }
                ))

                if notificationsEnabled {
                    DatePicker(
                        "提醒时间",
                        selection: reminderTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                }
            } header: {
                Text("每日提醒")
            } footer: {
                Text(notificationsEnabled
                    ? "将在每天 \(notificationHour):\(String(format: "%02d", notificationMinute)) 提醒你复习今日题目"
                    : "开启后系统将在固定时间推送复习提醒"
                )
            }

            Section {
                Toggle("声音", isOn: $soundEnabled)
                    .disabled(!notificationsEnabled)
                Toggle("角标", isOn: $badgeEnabled)
                    .disabled(!notificationsEnabled)
            } header: {
                Text("通知样式")
            } footer: {
                Text("声音和角标设置在下次触发通知时生效")
            }
        }
        .navigationTitle("通知与提醒")
        .navigationBarTitleDisplayMode(.inline)
        .alert("通知权限被拒绝", isPresented: Binding(
            get: { viewModel?.isPermissionDenied ?? false },
            set: { newValue in viewModel?.isPermissionDenied = newValue }
        )) {
            Button("去设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("请在「设置 → 通知 → 小本本」中开启通知权限，才能接收每日复习提醒。")
        }
        .onAppear {
            if viewModel == nil {
                viewModel = NotificationSettingsViewModel(notificationService: services.notification)
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
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                notificationHour = comps.hour ?? 20
                notificationMinute = comps.minute ?? 0
                Task { await viewModel?.reschedule(hour: notificationHour, minute: notificationMinute) }
            }
        )
    }

    private func handleToggle(_ newValue: Bool) {
        if newValue {
            Task {
                let granted = await viewModel?.enable(hour: notificationHour, minute: notificationMinute) ?? false
                notificationsEnabled = granted
            }
        } else {
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
