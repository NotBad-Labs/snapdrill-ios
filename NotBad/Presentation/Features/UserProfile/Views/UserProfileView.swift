//
//  UserProfileView.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/8/1.
//

import SwiftUI

/// 用户资料模块的视图
///
/// 职责：
/// - 显示用户的个人信息
/// - 提供设置、帮助和关于等入口
/// - 自身不包含复杂业务逻辑，通过 ViewModel (待创建) 获取数据
struct UserProfileView: View {
    var body: some View {
        List {
            // MARK: - 用户信息 Section
            Section {
                HStack(spacing: 15) {
                    // 用户的头像
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Yiming Liao")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("查看个人主页")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color(.systemGroupedBackground))
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            
            // MARK: - 账户设置 Section
            Section {
                NavigationLink(destination: Text("账户设置")) {
                    Label("账户与安全", systemImage: "person.shield.fill")
                        .foregroundColor(.blue)
                }
                
                NavigationLink(destination: Text("通知设置")) {
                    Label("通知设置", systemImage: "bell.fill")
                        .foregroundColor(.red)
                }
                
                NavigationLink(destination: Text("外观设置")) {
                    Label("外观设置", systemImage: "paintpalette.fill")
                        .foregroundColor(.orange)
                }
            } header: {
                Text("账户")
            }
            
            // MARK: - 其他 Section
            Section {
                NavigationLink(destination: Text("帮助与反馈")) {
                    Label("帮助与反馈", systemImage: "questionmark.circle.fill")
                        .foregroundColor(.gray)
                }
                
                NavigationLink(destination: Text("关于")) {
                    Label("关于 NotBad", systemImage: "info.circle.fill")
                        .foregroundColor(.gray)
                }
            } header: {
                Text("其他")
            }
            
            // MARK: - 退出登录 Section
            Section {
                Button(role: .destructive, action: {}) {
                    Label("退出登录", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("我的")
    }
}

// MARK: - Preview

#if DEBUG
struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            UserProfileView()
        }
    }
}
#endif

