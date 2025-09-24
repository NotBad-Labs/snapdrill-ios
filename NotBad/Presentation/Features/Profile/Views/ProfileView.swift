//
//  ProfileView.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import SwiftUI

/// 个人中心视图
/// 显示用户信息、设置等
struct ProfileView: View {
    /// 个人中心内容类型
    enum Content {
        case main
    }

    /// 协调器引用
    @ObservedObject var coordinator: ProfileCoordinator

    init(coordinator: ProfileCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            ProfileContentView(coordinator: coordinator)
                .navigationTitle("我的")
                .accessibilityIdentifier("screen_profile")
                .navigationDestination(for: ProfileCoordinator.ProfileRoute.self) { route in
                    switch route {
                    case .settings:
                        ProfileSettingsView(coordinator: coordinator)
                    case .about:
                        AboutView(coordinator: coordinator)
                    case .detail(let id):
                        ProfileDetailView(itemId: id, coordinator: coordinator)
                    }
                }
        }
    }
}

/// 个人中心内容视图
struct ProfileContentView: View {
    let coordinator: ProfileCoordinator

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ProfileHeaderSection()
                ProfileStatsSection()
                ProfileMenuSection(coordinator: coordinator)
            }
        }
    }
}

/// 用户信息区域
struct ProfileHeaderSection: View {
    var body: some View {
        VStack(spacing: 15) {
            // 头像
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("NotBad 用户")
                .font(.title2)
                .fontWeight(.medium)

            Text("开始你的学习之旅")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

/// 学习统计区域
struct ProfileStatsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("学习统计")
                .font(.headline)
                .padding(.horizontal)

            HStack(spacing: 20) {
                ProfileStatCard(title: "学习天数", value: "0", color: .blue)
                ProfileStatCard(title: "练习题数", value: "0", color: .green)
                ProfileStatCard(title: "正确率", value: "0%", color: .orange)
            }
            .padding(.horizontal)
        }
    }
}

/// 功能菜单区域
struct ProfileMenuSection: View {
    let coordinator: ProfileCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("功能设置")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ProfileMenuItem(icon: "gear", title: "应用设置", color: .gray) {
                    coordinator.coordinate(to: .settings)
                }
                .accessibilityIdentifier("profile_menu_settings")
                Divider().padding(.leading, 50)
                ProfileMenuItem(icon: "bell", title: "通知设置", color: .orange) {
                    // TODO: 通知设置
                }
                .accessibilityIdentifier("profile_menu_notifications")
                Divider().padding(.leading, 50)
                ProfileMenuItem(icon: "shield", title: "隐私设置", color: .blue) {
                    // TODO: 隐私设置 - 可使用 coordinator.coordinate(to: .detail(module: "profile", id: "privacy"))
                }
                .accessibilityIdentifier("profile_menu_privacy")
                Divider().padding(.leading, 50)
                ProfileMenuItem(icon: "questionmark.circle", title: "帮助反馈", color: .green) {
                    // TODO: 帮助反馈 - 可使用 coordinator.coordinate(to: .detail(module: "profile", id: "help"))
                }
                .accessibilityIdentifier("profile_menu_help")
                Divider().padding(.leading, 50)
                ProfileMenuItem(icon: "info.circle", title: "关于我们", color: .purple) {
                    coordinator.coordinate(to: .about)
                }
                .accessibilityIdentifier("profile_menu_about")
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
            .padding(.horizontal)
        }
    }
}

/// 个人统计卡片
struct ProfileStatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

/// 个人菜单项
struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)

            Text(title)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}

#Preview {
    ProfileView(coordinator: ProfileCoordinator())
}

// MARK: - 占位视图：设置
struct ProfileSettingsView: View {
    let coordinator: ProfileCoordinator

    var body: some View {
        Form {
            Section(header: Text("通用")) {
                Toggle("启用通知", isOn: .constant(true))
                Toggle("使用蜂窝数据", isOn: .constant(false))
            }

            Section(header: Text("外观")) {
                Picker("主题", selection: .constant(0)) {
                    Text("跟随系统").tag(0)
                    Text("浅色").tag(1)
                    Text("深色").tag(2)
                }
            }
        }
        .navigationTitle("设置")
        .accessibilityIdentifier("screen_profile_settings")
    }
}

// MARK: - 占位视图：关于
struct AboutView: View {
    let coordinator: ProfileCoordinator

    var body: some View {
        VStack(spacing: 16) {
            Text("关于 NotBad")
                .font(.title2)
                .fontWeight(.semibold)
            Text("一个帮助你高效学习的开源应用。")
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
        .navigationTitle("关于")
        .accessibilityIdentifier("screen_profile_about")
    }
}

// MARK: - 占位视图：通用详情
struct ProfileDetailView: View {
    let itemId: String
    let coordinator: ProfileCoordinator

    var body: some View {
        VStack(spacing: 16) {
            Text("详情")
                .font(.title2)
                .fontWeight(.semibold)
            Text("ID: \(itemId)")
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
        .navigationTitle("详情")
    }
}
