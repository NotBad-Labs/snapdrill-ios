//
//  NotificationSettingsView.swift
//  SnapDrillFeatures
//
//  Created by SnapDrill Labs on 2026/01/02.
//

import SwiftUI

/// 通知设置页面
struct NotificationSettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("badgeEnabled") private var badgeEnabled = true
    @AppStorage("notificationPreview") private var notificationPreview = 0 // 0=Full, 1=Name Only, 2=None
    
    var body: some View {
        List {
            Section {
                Toggle("启用通知", isOn: $notificationsEnabled)
                Toggle("声音", isOn: $soundEnabled)
                    .disabled(!notificationsEnabled)
                Toggle("角标", isOn: $badgeEnabled)
                    .disabled(!notificationsEnabled)
            } header: {
                Text("通知")
            } footer: {
                Text("接收学习提醒和复习通知")
            }
            
            Section("预览样式") {
                Picker("消息预览", selection: $notificationPreview) {
                    Text("完整内容").tag(0)
                    Text("仅显示名称").tag(1)
                    Text("不显示").tag(2)
                }
                .disabled(!notificationsEnabled)
            }
        }
        .navigationTitle("通知与声音")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
