//
//  EditProfileView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  个人资料编辑页面。
//

import SwiftUI
import PhotosUI
import UIKit
import SnapDrillCore
import SnapDrillUI
import SnapDrillFeatureLibrary

/// 个人资料编辑页面
struct EditProfileView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @AppStorage(UDKey.userName) private var userName: String = "用户"
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
    /// 头像加载/保存失败时的用户可见提示（修复 #637：失败原本完全静默）
    @State private var avatarLoadError: String?
    @Environment(\.profileManager) private var profileManager
    private var imageStorage: ImageStorage { profileManager.activeImageStorage }
    
    // 头像主题色预设
    private let gradients: [[Color]] = [
        [Color(.systemBlue), Color(.systemCyan)],
        [Color(.systemIndigo), Color(.systemBlue)],
        [Color(.systemGreen), Color(.systemTeal)],
        [Color(.systemPurple), Color(.systemIndigo)],
        [Color(.systemGray), Color(.systemGray2)],
        [Color(.systemOrange), Color(.systemYellow)]
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
                        if showsPhotoAvatar, let image = avatarImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 88, height: 88)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(.separator).opacity(0.25), lineWidth: 1))
                                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
                                .accessibilityIdentifier("settings.editProfile.photoAvatar")
                        } else if showsPhotoAvatar {
                            // 自定义头像加载中占位
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 52))
                                .foregroundStyle(.secondary)
                                .frame(width: 88, height: 88)
                                .background(Circle().fill(.ultraThinMaterial))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(.separator).opacity(0.25), lineWidth: 1))
                                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
                        } else {
                            Image(systemName: userAvatar)
                                .font(.system(size: 52))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(currentGradient)
                                .frame(width: 88, height: 88)
                                .background(Circle().fill(.ultraThinMaterial))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(.separator).opacity(0.25), lineWidth: 1))
                                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
                        }
                    }
                    
                    // 设置头像按钮
                    Button {
                        showingPhotoOptions = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 16, weight: .semibold))
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
                LabeledContent {
                    TextField(L10n.EditProfile.nicknamePlaceholder, text: $userName)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Text(L10n.EditProfile.nickname)
                }
                
                // 每日目标
                LabeledContent {
                    HStack(spacing: 8) {
                        Stepper("\(dailyReviewGoal) \(L10n.EditProfile.cardsCount)", value: $dailyReviewGoal, in: 5...100, step: 5)
                            .labelsHidden()
                        Text("\(dailyReviewGoal) \(L10n.EditProfile.cardsCount)")
                            .foregroundStyle(.secondary)
                    }
                } label: {
                    Text(L10n.EditProfile.dailyGoal)
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
            if !showsPhotoAvatar {
                Section(L10n.EditProfile.themeColor) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<gradients.count, id: \.self) { index in
                                Button {
                                    withAnimation {
                                        userAvatarColorIndex = index
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(
                                                colors: gradients[index],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                            .frame(width: 44, height: 44)

                                        if userAvatarColorIndex == index {
                                            Circle()
                                                .strokeBorder(Color.accentColor, lineWidth: 3)
                                                .frame(width: 52, height: 52)

                                            Image(systemName: "checkmark")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundStyle(.white)
                                                .shadow(color: .black.opacity(0.32), radius: 1, x: 0, y: 1)
                                                .accessibilityHidden(true)
                                        }
                                    }
                                    .frame(width: 56, height: 56)
                                    .contentShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(L10n.Accessibility.avatarColorName(index))
                                .accessibilityIdentifier("settings.editProfile.color.\(index)")
                                .accessibilityAddTraits(userAvatarColorIndex == index ? .isSelected : [])
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
        }
        .listStyle(.insetGrouped)
        .accessibilityIdentifier("settings.editProfile.root")
        .navigationTitle(L10n.EditProfile.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
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

            if showsPhotoAvatar {
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
            guard let newValue else { return } // selectedItem 被复位时不重新触发加载
            let storage = imageStorage // Task 前捕获 computed property（api-pitfalls.md）
            imageLoadTask = Task {
                let data: Data?
                do {
                    data = try await newValue.loadTransferable(type: Data.self)
                } catch is CancellationError {
                    return // 取消属正常行为，不记为错误
                } catch {
                    guard !Task.isCancelled else { return }
                    SnapDrillLogger.generic.error("PhotosPicker 图片加载失败: \(error.localizedDescription)")
                    avatarLoadError = L10n.Errors.imageLoadFailed
                    selectedItem = nil // 失败后复位允许同张照片重选（修复 #637）
                    return
                }
                guard !Task.isCancelled else { return }
                guard let data, let image = UIImage(data: data) else {
                    avatarLoadError = L10n.Errors.imageDecodeFailed
                    selectedItem = nil
                    return
                }
                do {
                    // saveImage 内部走 Task.detached，不继承父 Task 取消，
                    // 恢复后必须显式检查避免写入过期 userAvatar
                    let path = try await storage.saveImage(image)
                    guard !Task.isCancelled else { return }
                    userAvatar = path
                    selectedItem = nil // 成功后也复位以允许同图重选
                } catch {
                    guard !Task.isCancelled else { return }
                    SnapDrillLogger.generic.error("Failed to save avatar: \(error.localizedDescription)")
                    avatarLoadError = L10n.Errors.avatarSaveFailed
                    selectedItem = nil
                }
            }
        }
        .alert(L10n.Common.error, isPresented: .init(
            get: { avatarLoadError != nil },
            set: { if !$0 { avatarLoadError = nil } }
        )) {
            Button(L10n.Common.ok, role: .cancel) {}
        } message: {
            Text(avatarLoadError ?? "")
        }
        .onDisappear {
            imageLoadTask?.cancel()
        }
        .task(id: userAvatar) {
#if DEBUG
            if usesUITestPhotoAvatar {
                avatarImage = Self.makeUITestAvatarImage()
                return
            }
#endif
            if userAvatar.contains("images/") {
                let storage = imageStorage
                avatarImage = await storage.loadImageAsync(path: userAvatar)
            } else {
                avatarImage = nil
            }
        }
    }

    private var showsPhotoAvatar: Bool {
#if DEBUG
        if usesUITestPhotoAvatar {
            return true
        }
#endif
        return userAvatar.contains("images/")
    }

#if DEBUG
    private static let uiTestPhotoAvatarArgument = "--ui-test-edit-profile-photo-avatar"

    private var usesUITestPhotoAvatar: Bool {
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.contains("--uitesting") && arguments.contains(Self.uiTestPhotoAvatarArgument)
    }

    private static func makeUITestAvatarImage() -> UIImage {
        let size = CGSize(width: 160, height: 160)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            UIColor.systemBlue.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 18, y: 18, width: 124, height: 124))

            UIColor.white.withAlphaComponent(0.92).setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 50, y: 42, width: 60, height: 60))
            context.cgContext.fillEllipse(in: CGRect(x: 34, y: 96, width: 92, height: 54))
        }
    }
#endif
}

#Preview {
    NavigationStack {
        EditProfileView()
    }
}
