//
//  NotificationSettingsView.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import UserNotifications

// MARK: - NotificationSettingsView

/// 复习提醒设置视图
///
/// 管理每日复习提醒通知。
struct NotificationSettingsView: View {
    
    // MARK: - State
    
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 20
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @State private var showTimePicker = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showPermissionAlert = false
    
    // MARK: - Body
    
    var body: some View {
        List {
            reminderSection
            timeSection
            tipsSection
        }
        .navigationTitle("复习提醒")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await checkNotificationStatus()
        }
        .alert("notification_permission_required", isPresented: $showPermissionAlert) {
            Button("common_cancel", role: .cancel) {
                reminderEnabled = false
            }
            Button("notification_go_settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("notification_permission_message")
        }
    }
    
    // MARK: - Reminder Section
    
    private var reminderSection: some View {
        Section {
            Toggle(isOn: $reminderEnabled) {
                Label {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("notification_daily_reminder")
                        Text("notification_reminder_description")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(Color.brand.warning)
                }
            }
            .onChange(of: reminderEnabled) { _, newValue in
                if newValue {
                    Task {
                        await handleEnableReminder()
                    }
                } else {
                    cancelReminder()
                }
            }
        } footer: {
            if notificationStatus == .denied {
                Text("notification_permission_denied")
                    .foregroundStyle(Color.brand.error)
            }
        }
    }
    
    // MARK: - Time Section
    
    private var timeSection: some View {
        Section("notification_reminder_time") {
            Button {
                showTimePicker.toggle()
            } label: {
                HStack {
                    Label("notification_time", systemImage: "clock.fill")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(formattedTime)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .disabled(!reminderEnabled)
            .opacity(reminderEnabled ? 1 : 0.5)
            
            if showTimePicker {
                DatePicker(
                    "notification_select_time",
                    selection: timeBinding,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .onChange(of: reminderHour) { _, _ in
                    scheduleReminder()
                }
                .onChange(of: reminderMinute) { _, _ in
                    scheduleReminder()
                }
            }
        }
    }
    
    // MARK: - Tips Section
    
    private var tipsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Label("小贴士", systemImage: "lightbulb.fill")
                    .font(.headline)
                    .foregroundStyle(Color.brand.warning)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    tipRow("建议在晚上 8-9 点复习，记忆效果更好")
                    tipRow("每天坚持复习 10-15 分钟即可")
                    tipRow("及时复习能有效防止遗忘")
                }
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
    }
    
    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.brand.success)
                .font(.caption)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Computed Properties
    
    private var formattedTime: String {
        String(format: "%02d:%02d", reminderHour, reminderMinute)
    }
    
    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = reminderHour
                components.minute = reminderMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                reminderHour = components.hour ?? 20
                reminderMinute = components.minute ?? 0
            }
        )
    }
    
    // MARK: - Methods
    
    private func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            notificationStatus = settings.authorizationStatus
        }
    }
    
    private func handleEnableReminder() async {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                if granted {
                    notificationStatus = .authorized
                    scheduleReminder()
                } else {
                    notificationStatus = .denied
                    reminderEnabled = false
                    showPermissionAlert = true
                }
            }
        } catch {
            await MainActor.run {
                reminderEnabled = false
            }
        }
    }
    
    private func scheduleReminder() {
        guard reminderEnabled else { return }
        
        let center = UNUserNotificationCenter.current()
        
        // 取消现有提醒
        center.removePendingNotificationRequests(withIdentifiers: ["dailyReviewReminder"])
        
        // 创建新提醒
        let content = UNMutableNotificationContent()
        content.title = "📚 复习时间到！"
        content.body = "花几分钟复习一下错题，巩固今天的知识吧！"
        content.sound = .default
        content.badge = 1
        
        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReviewReminder", content: content, trigger: trigger)
        
        center.add(request)
    }
    
    private func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyReviewReminder"])
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
