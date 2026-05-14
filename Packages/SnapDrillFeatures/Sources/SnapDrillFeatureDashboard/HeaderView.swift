//
//  HeaderView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  首页顶部标题栏视图。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI

/// 仪表盘顶部标题栏，包含日期和应用名称
struct HeaderView: View {

    // MARK: - Properties

    @AppStorage(UDKey.userAvatar) private var userAvatar: String = "person.crop.circle.fill"
    @AppStorage(UDKey.userAvatarColorIndex) private var userAvatarColorIndex: Int = 0
    @AppStorage(UDKey.userName) private var userName: String = L10n.Dashboard.defaultName
    @Environment(\.profileManager) private var profileManager
    @State private var avatarImage: UIImage?

    // 动态问候语
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = userName.isEmpty ? L10n.Dashboard.defaultName : userName

        switch hour {
        case 5..<12: return L10n.Dashboard.greetingMorning(name)
        case 12..<18: return L10n.Dashboard.greetingAfternoon(name)
        case 18..<22: return L10n.Dashboard.greetingEvening(name)
        default: return L10n.Dashboard.greetingNight
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                // 日期显示
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .accessibilityHidden(true)
                    Text(Date().formatted(date: .complete, time: .omitted))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                
                // 问候语
                Text(greeting)
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            // 头像 / 个人资料
            Button {
                // 通过通知跳转到设置页
                NotificationCenter.default.post(name: .switchToSettingsTab, object: nil)
            } label: {
                if userAvatar.contains("images/"), let image = avatarImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                } else {
                    let colors: [[Color]] = [
                        [.blue, .purple],
                        [.orange, .red],
                        [.green, .teal],
                        [.pink, .indigo],
                        [.gray, .black],
                        [.yellow, .orange]
                    ]
                    let selectedColors = colors[userAvatarColorIndex < colors.count ? userAvatarColorIndex : 0]
                    
                    Image(systemName: userAvatar)
                        .font(.system(size: 40))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(LinearGradient(colors: selectedColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .symbolEffect(.pulse, isActive: false) // Potential for interaction
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
            }
            .accessibleButton(label: L10n.Accessibility.profile, hint: L10n.Accessibility.profileHint)
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .task(id: userAvatar) {
            guard userAvatar.contains("images/") else {
                avatarImage = nil
                return
            }
            avatarImage = await profileManager.activeImageStorage.loadImageAsync(path: userAvatar)
        }
    }
}

#Preview {
    HeaderView()
}
