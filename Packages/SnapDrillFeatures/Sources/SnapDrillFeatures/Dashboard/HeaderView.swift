//
//  HeaderView.swift
//  SnapDrillFeatureDashboard
//
//  Created by SnapDrill Labs on 2025/12/31.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  首页顶部标题栏视图。
//

import SwiftUI
import SnapDrillCore

/// 仪表盘顶部标题栏，包含日期和应用名称
struct HeaderView: View {
    
    // MARK: - Properties
    
    @AppStorage("userAvatar") private var userAvatar: String = "person.crop.circle.fill"
    @AppStorage("userAvatarColorIndex") private var userAvatarColorIndex: Int = 0
    @AppStorage("userName") private var userName: String = "同学" // Use "同学" as default for new installs
    
    // Dynamic Greeting
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = userName.isEmpty ? "同学" : userName
        
        switch hour {
        case 5..<12: return "早安，\(name)"
        case 12..<18: return "午安，\(name)"
        case 18..<22: return "晚上好，\(name)"
        default: return "夜深了，注意休息"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                // Date & Weather (Privacy Balanced)
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(Date().formatted(date: .complete, time: .omitted))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                
                // Greeting
                Text(greeting)
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            // Avatar / Profile
            Button {
                // Navigate to Settings Tab via Notification
                NotificationCenter.default.post(name: NSNotification.Name("SwitchToSettingsTab"), object: nil)
            } label: {
                if userAvatar.contains("images/"), let image = ImageStorage().loadImage(path: userAvatar) {
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
        }
        .padding(.horizontal)
        .padding(.top, 10) // Slightly adjusted padding
    }
}

#Preview {
    HeaderView()
}
