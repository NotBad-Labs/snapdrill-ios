//
//  EditProfileView.swift
//  NotBadFeatureSettings
//
//  Created by NotBad Labs on 2026/01/01.
//

import SwiftUI
import PhotosUI
import NotBadCore

/// 用户资料编辑页面 - 专注学习场景
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userName") private var userName: String = "同学"
    @AppStorage("userMotto") private var userMotto: String = "" // Formerly bio
    @AppStorage("dailyReviewGoal") private var dailyReviewGoal: Int = 20
    @AppStorage("userAvatar") private var userAvatar: String = "person.crop.circle.fill"
    @AppStorage("userAvatarColorIndex") private var userAvatarColorIndex: Int = 0
    
    // Custom Avatar Handling
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingPhotoOptions = false
    @State private var showingSymbolPicker = false
    private let imageStorage = ImageStorage()
    
    // Gradient presets
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
    
    var body: some View {
        List {
            // Avatar Section - Clean & Focused
            Section {
                VStack(spacing: 16) {
                    // Large Centered Avatar
                    Group {
                        if userAvatar.contains("images/"), let image = imageStorage.loadImage(path: userAvatar) {
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
                    
                    // Set Profile Photo Button
                    Button {
                        showingPhotoOptions = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16))
                            Text(L10n.EditProfile.setAvatar)
                                .font(.body)
                        }
                        .foregroundStyle(.blue)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .listRowBackground(Color.clear)
            }
            
            // Basic Info Section
            Section {
                // Name Field
                HStack {
                    Text(L10n.EditProfile.nickname)
                        .foregroundStyle(.primary)
                        .frame(width: 80, alignment: .leading)
                    TextField(L10n.EditProfile.nicknamePlaceholder, text: $userName)
                        .multilineTextAlignment(.trailing)
                }
                
                // Study Goal
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
            
            // Motto Section (Replaces generic Bio)
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
            
            // Icon Theme Section (only if using SF Symbol)
            if !userAvatar.contains("images/") {
                Section(L10n.EditProfile.themeColor) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<gradients.count, id: \.self) { index in
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
                                    .onTapGesture {
                                        withAnimation {
                                            userAvatarColorIndex = index
                                        }
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
        }
        .navigationTitle(L10n.EditProfile.title)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(L10n.EditProfile.chooseAvatarSource, isPresented: $showingPhotoOptions) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
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
        .sheet(isPresented: $showingSymbolPicker) {
            SFSymbolPickerView(selectedSymbol: $userAvatar)
        }
        .onChange(of: selectedItem) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    do {
                        let path = try await imageStorage.saveImage(image)
                        await MainActor.run {
                            userAvatar = path
                        }
                    } catch {
                        NotBadLogger.generic.info("Failed to save avatar: \(error)")
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView()
    }
}
