//
//  ProfileEditView.swift
//  NotBad
//
//  个人资料编辑视图
//

import SwiftUI

// MARK: - ProfileEditView

/// 个人资料编辑视图
///
/// 允许用户自定义昵称和头像。
struct ProfileEditView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @State private var nickname: String = ""
    @State private var selectedAvatar: String = "person.fill"
    
    // MARK: - Constants
    
    /// 可选的头像图标
    private let avatarOptions: [String] = [
        "person.fill",
        "face.smiling.fill",
        "star.fill",
        "heart.fill",
        "book.fill",
        "graduationcap.fill",
        "pencil.and.ruler.fill",
        "lightbulb.fill",
        "brain.fill",
        "trophy.fill",
        "medal.fill",
        "flag.fill"
    ]
    
    /// 头像背景渐变色选项
    private let gradientOptions: [[Color]] = [
        [Color.brand.primary, Color.brand.secondary],
        [.purple, .pink],
        [.orange, .red],
        [.green, .mint],
        [.blue, .cyan],
        [.indigo, .purple]
    ]
    
    @State private var selectedGradientIndex: Int = 0
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                avatarSection
                nicknameSection
                gradientSection
            }
            .navigationTitle("profile_edit_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common_cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common_save") {
                        saveProfile()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadProfile()
            }
        }
    }
    
    // MARK: - Avatar Section
    
    private var avatarSection: some View {
        Section {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // 当前头像预览
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradientOptions[selectedGradientIndex],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: gradientOptions[selectedGradientIndex][0].opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: selectedAvatar)
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(.white)
                }
                .padding(.vertical, DesignTokens.Spacing.md)
                
                // 头像选择网格
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(avatarOptions, id: \.self) { avatar in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedAvatar = avatar
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(selectedAvatar == avatar ? Color.brand.primary.opacity(0.15) : Color.clear)
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: avatar)
                                    .font(.system(size: 22))
                                    .foregroundStyle(selectedAvatar == avatar ? Color.brand.primary : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        } header: {
            Text("profile_edit_avatar")
        }
    }
    
    // MARK: - Nickname Section
    
    private var nicknameSection: some View {
        Section {
            TextField("profile_edit_nickname_placeholder", text: $nickname)
                .textContentType(.nickname)
                .autocorrectionDisabled()
        } header: {
            Text("profile_edit_nickname")
        } footer: {
            Text("profile_edit_nickname_hint")
        }
    }
    
    // MARK: - Gradient Section
    
    private var gradientSection: some View {
        Section {
            HStack(spacing: 12) {
                ForEach(0..<gradientOptions.count, id: \.self) { index in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedGradientIndex = index
                        }
                    } label: {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: gradientOptions[index],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                            .overlay {
                                if selectedGradientIndex == index {
                                    Circle()
                                        .strokeBorder(.white, lineWidth: 3)
                                }
                            }
                            .shadow(color: gradientOptions[index][0].opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
        } header: {
            Text("profile_edit_color")
        }
    }
    
    // MARK: - Methods
    
    private func loadProfile() {
        nickname = UserProfileManager.shared.nickname
        selectedAvatar = UserProfileManager.shared.avatar
        selectedGradientIndex = UserProfileManager.shared.gradientIndex
    }
    
    private func saveProfile() {
        UserProfileManager.shared.nickname = nickname.isEmpty ? String(localized: "profile_nickname") : nickname
        UserProfileManager.shared.avatar = selectedAvatar
        UserProfileManager.shared.gradientIndex = selectedGradientIndex
    }
}

// MARK: - Preview

#Preview {
    ProfileEditView()
}
