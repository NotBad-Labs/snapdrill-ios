//
//  EditProfileView.swift
//  NotBadFeatureSettings
//
//  Created by NotBad Architect on 2026/01/01.
//

import SwiftUI

/// 用户资料编辑页面
struct EditProfileView: View {
    @AppStorage("userName") private var userName: String = "Student"
    @AppStorage("userAvatar") private var userAvatar: String = "person.crop.circle.fill"
    @AppStorage("userAvatarColorIndex") private var userAvatarColorIndex: Int = 0
    
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
    
    @State private var showingSymbolPicker = false
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    Button {
                        showingSymbolPicker = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: userAvatar)
                                .font(.system(size: 80))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(currentGradient)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                            
                            Text("更换头像")
                                .font(.footnote)
                                .foregroundStyle(.blue)
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
            
            Section("昵称") {
                TextField("请输入昵称", text: $userName)
            }
            
            Section("头像主题色") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<gradients.count, id: \.self) { index in
                            Circle()
                                .fill(LinearGradient(colors: gradients[index], startPoint: .topLeading, endPoint: .bottomTrailing))
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
            }
        }
        .navigationTitle("个人资料")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSymbolPicker) {
            SFSymbolPickerView(selectedSymbol: $userAvatar)
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView()
    }
}
