//
//  OnboardingView.swift
//  SnapDrillUI
//
//  Created by SnapDrill Labs on 2026/01/03.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  用户引导视图
//

import SwiftUI
import SnapDrillCore

/// 引导页面数据模型
public struct OnboardingPage: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let imageName: String
    public let systemImage: String?
    
    public init(title: String, description: String, imageName: String = "", systemImage: String? = nil) {
        self.title = title
        self.description = description
        self.imageName = imageName
        self.systemImage = systemImage
    }
}

/// 引导视图
public struct OnboardingView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    let pages: [OnboardingPage]
    let onComplete: () -> Void
    
    public init(pages: [OnboardingPage], onComplete: @escaping () -> Void) {
        self.pages = pages
        self.onComplete = onComplete
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 0) {
            // 跳过按钮
            HStack {
                Spacer()
                Button("跳过") {
                    completeOnboarding()
                }
                .foregroundStyle(.secondary)
                .padding()
            }
            
            // 页面内容
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            // 底部按钮
            HStack(spacing: 16) {
                if currentPage > 0 {
                    Button("上一页") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                Button(currentPage == pages.count - 1 ? "开始使用" : "下一页") {
                    if currentPage == pages.count - 1 {
                        completeOnboarding()
                    } else {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .accessibleGroup(label: "欢迎引导")
    }
    
    private func completeOnboarding() {
        onComplete()
        dismiss()
    }
}

/// 单个引导页面视图
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 图片或图标
            if let systemImage = page.systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 100))
                    .foregroundStyle(.blue)
                    .accessibleImage(label: page.title)
            } else if !page.imageName.isEmpty {
                Image(page.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .accessibleImage(label: page.title)
            }
            
            // 标题
            Text(page.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .accessibleHeader(page.title)
            
            // 描述
            Text(page.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .accessible(label: page.description)
            
            Spacer()
        }
        .padding()
    }
}

/// 功能提示气泡
public struct FeatureTooltip: View {
    let title: String
    let message: String
    let onDismiss: () -> Void
    
    public init(title: String, message: String, onDismiss: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .accessibleHeader(title)
                
                Spacer()
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibleButton(label: "关闭提示")
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessible(label: message)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
        .padding()
    }
}

/// 引导管理器
@MainActor
public final class OnboardingManager: ObservableObject {
    public static let shared = OnboardingManager()
    
    @Published public var shouldShowOnboarding: Bool
    @Published public var shouldShowFeatureTooltip: [String: Bool] = [:]
    
    private init() {
        self.shouldShowOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    /// 完成引导
    public func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        shouldShowOnboarding = false
    }
    
    /// 检查是否应该显示功能提示
    public func shouldShowTooltip(for feature: String) -> Bool {
        if let cached = shouldShowFeatureTooltip[feature] {
            return cached
        }
        
        let hasShown = UserDefaults.standard.bool(forKey: "hasShownTooltip_\(feature)")
        shouldShowFeatureTooltip[feature] = !hasShown
        return !hasShown
    }
    
    /// 标记功能提示已显示
    public func markTooltipShown(for feature: String) {
        UserDefaults.standard.set(true, forKey: "hasShownTooltip_\(feature)")
        shouldShowFeatureTooltip[feature] = false
    }
    
    /// 重置所有引导状态
    public func resetAll() {
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        shouldShowOnboarding = true
        shouldShowFeatureTooltip.removeAll()
        
        // 清除所有提示记录
        let keys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in keys where key.hasPrefix("hasShownTooltip_") {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

/// 默认引导页面
public extension OnboardingPage {
    static let defaultPages: [OnboardingPage] = [
        OnboardingPage(
            title: "欢迎使用 SnapDrill",
            description: "智能错题管理，让学习更高效",
            systemImage: "book.fill"
        ),
        OnboardingPage(
            title: "智能拍摄",
            description: "使用相机快速捕捉错题，自动识别文字内容",
            systemImage: "camera.fill"
        ),
        OnboardingPage(
            title: "科学复习",
            description: "基于艾宾浩斯遗忘曲线，智能安排复习计划",
            systemImage: "calendar.badge.clock"
        ),
        OnboardingPage(
            title: "云端同步",
            description: "使用 iCloud 自动同步，多设备无缝切换",
            systemImage: "icloud.fill"
        ),
        OnboardingPage(
            title: "数据导出",
            description: "支持导出为 PDF、CSV 等格式，方便分享和打印",
            systemImage: "square.and.arrow.up.fill"
        )
    ]
}

// MARK: - Preview

#Preview {
    OnboardingView(pages: OnboardingPage.defaultPages) {
        SnapDrillLogger.generic.info("Onboarding completed")
    }
}
