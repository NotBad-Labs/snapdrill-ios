//
//  EditProfileView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/01/01.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  用户信息编辑页面。
//

import SwiftUI
import PhotosUI
import SnapDrillCore
import SnapDrillUI
import SnapDrillFeatureLibrary

/// 用户资料编辑页面 - 专注学习场景
struct EditProfileView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @AppStorage(UDKey.userName) private var userName: String = "同学"
    @AppStorage(UDKey.userMotto) private var userMotto: String = "" // Formerly bio
    @AppStorage(UDKey.dailyReviewGoal) private var dailyReviewGoal: Int = 20
    @AppStorage(UDKey.userAvatar) private var userAvatar: String = "person.crop.circle.fill"
    @AppStorage(UDKey.userAvatarColorIndex) private var userAvatarColorIndex: Int = 0
    
    // 自定义头像处理
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingPhotoOptions = false
    @State private var showingPhotosPicker = false
    @State private var showingSymbolPicker = false
    @State private var imageLoadTask: Task<Void, Never>?
    @State private var avatarImage: UIImage?
    @Environment(\.profileManager) private var profileManager
    private var imageStorage: ImageStorage { profileManager.activeImageStorage }
    
    // 渐变色预设
    private let gradients: [[Color]] = [
        [.blue, .purple],       // 0: Default
        [.orange, .red],        // 1: Warm
        [.green, .teal],        // 2: Nature
        [.pink, .indigo],       // 3: Vivid
        [.gray, .black],        // 4: Dark
        [.yellow, .orange]      // 5: Sunny
    ]
    
    private var currentGradient: LinearGradient {
        let colors = gradients[userAvatarColorIndex < gradients.count ? userAvatarColorIndex : 0]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    // MARK: - Body
    
    var body: some View {
        List {
            // 头像区域
            Section {
                VStack(spacing: 16) {
                    // 居中大头像
                    Group {
                        if let image = avatarImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        } else {
                            Image(systemName: userAvatar)
                                .font(.system(size: 60))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(currentGradient)
                                .frame(width: 100, height: 100)
                                .background(Circle().fill(.ultraThinMaterial))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        }
                    }
                    
                    // 设置头像按钮
                    Button {
                        showingPhotoOptions = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16))
                                .accessibilityHidden(true)
                            Text(L10n.EditProfile.setAvatar)
                                .font(.body)
                        }
                        .foregroundStyle(.blue)
                    }
                    .accessibilityHint(L10n.Accessibility.setAvatarHint)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .listRowBackground(Color.clear)
            }
            
            // 基本信息
            Section {
                // 昵称
                HStack {
                    Text(L10n.EditProfile.nickname)
                        .foregroundStyle(.primary)
                        .frame(width: 80, alignment: .leading)
                    TextField(L10n.EditProfile.nicknamePlaceholder, text: $userName)
                        .multilineTextAlignment(.trailing)
                }
                
                // 每日目标
                HStack {
                    Text(L10n.EditProfile.dailyGoal)
                        .foregroundStyle(.primary)
                        .frame(width: 80, alignment: .leading)
                    
                    Spacer()
                    
                    Stepper("\(dailyReviewGoal) \(L10n.EditProfile.cardsCount)", value: $dailyReviewGoal, in: 5...100, step: 5)
                        .labelsHidden()
                    Text("\(dailyReviewGoal) \(L10n.EditProfile.cardsCount)")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(L10n.EditProfile.title)
            }
            
            // 座右铭
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.EditProfile.motto)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    TextField(L10n.EditProfile.mottoPlaceholder, text: $userMotto, axis: .vertical)
                        .lineLimit(2...4)
                }
                .padding(.vertical, 4)
            } footer: {
                    Text(L10n.EditProfile.mottoFooter)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // 图标主题色（仅使用 SF Symbol 时显示）
            if !userAvatar.contains("images/") {
                Section(L10n.EditProfile.themeColor) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<gradients.count, id: \.self) { index in
                                Button {
                                    withAnimation {
                                        userAvatarColorIndex = index
                                    }
                                } label: {
                                    Circle()
                                        .fill(LinearGradient(
                                            colors: gradients[index],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primary, lineWidth: userAvatarColorIndex == index ? 3 : 0)
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(L10n.Accessibility.avatarColorName(index))
                                .accessibilityAddTraits(userAvatarColorIndex == index ? .isSelected : [])
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.EditProfile.title)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(L10n.EditProfile.chooseAvatarSource, isPresented: $showingPhotoOptions) {
            // PhotosPicker 不能嵌入 confirmationDialog action builder（不可靠），
            // 改为 plain Button 触发 .photosPicker(isPresented:) modifier
            Button {
                showingPhotosPicker = true
            } label: {
                Label(L10n.EditProfile.fromPhotoLibrary, systemImage: "photo.on.rectangle")
            }

            Button {
                showingSymbolPicker = true
            } label: {
                Label(L10n.EditProfile.systemIcon, systemImage: "star.circle")
            }

            if userAvatar.contains("images/") {
                Button(L10n.EditProfile.removeAvatar, role: .destructive) {
                    userAvatar = "person.crop.circle.fill"
                }
            }
        }
        .photosPicker(isPresented: $showingPhotosPicker, selection: $selectedItem, matching: .images)
        .sheet(isPresented: $showingSymbolPicker) {
            SFSymbolPickerView(selectedSymbol: $userAvatar)
        }
        .onChange(of: selectedItem) { _, newValue in
            imageLoadTask?.cancel()
            imageLoadTask = Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    do {
                        let path = try await imageStorage.saveImage(image)
                        await MainActor.run {
                            userAvatar = path
                        }
                    } catch {
                        SnapDrillLogger.generic.error("Failed to save avatar: \(error.localizedDescription)")
                    }
                }
            }
        }
        .onDisappear {
            imageLoadTask?.cancel()
        }
        .task(id: userAvatar) {
            if userAvatar.contains("images/") {
                let storage = imageStorage
                let path = userAvatar
                avatarImage = await Task.detached {
                    storage.loadImage(path: path)
                }.value
            } else {
                avatarImage = nil
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView()
    }
}
