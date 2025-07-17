//
//  ProfileView.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/17/25.
//

import SwiftUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 用户信息卡片
                UserInfoCard()
                
                // 学习数据统计
                StudyStatisticsCard()
                
                // 设置选项
                SettingsOptionsSection()
                
                // 关于应用
                AboutSection()
            }
            .padding()
        }
        .navigationTitle("我的")
        .environment(viewModel)
    }
}

// MARK: - Components

struct UserInfoCard: View {
    var body: some View {
        HStack {
            // 头像
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("学习者")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("已学习 23 天")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Text("编辑")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct StudyStatisticsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习统计")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                StatItem(title: "总题数", value: "156", color: .blue)
                StatItem(title: "正确率", value: "78%", color: .green)
                StatItem(title: "学习天数", value: "23", color: .orange)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SettingsOptionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("设置")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 0) {
                SettingsRow(title: "学习提醒", icon: "bell.fill", color: .orange)
                Divider()
                SettingsRow(title: "数据备份", icon: "icloud.fill", color: .blue)
                Divider()
                SettingsRow(title: "隐私设置", icon: "lock.fill", color: .purple)
                Divider()
                SettingsRow(title: "帮助反馈", icon: "questionmark.circle.fill", color: .green)
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
        }
    }
}

struct AboutSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("关于")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 0) {
                SettingsRow(title: "版本信息", icon: "info.circle.fill", color: .blue)
                Divider()
                SettingsRow(title: "用户协议", icon: "doc.text.fill", color: .gray)
                Divider()
                SettingsRow(title: "隐私政策", icon: "shield.fill", color: .gray)
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}