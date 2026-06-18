//
//  OnboardingView.swift
//  SnapDrillUI
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  用户引导视图
//

import SwiftUI
import TipKit
import SnapDrillCore

/// 引导页面数据模型
public struct OnboardingPage: Identifiable, Sendable {
    /// 唯一标识
    public let id = UUID()
    /// 页面标题
    public let title: String
    /// 页面描述文本
    public let description: String
    /// 自定义图片资源名称（优先级低于 `systemImage`）
    public let imageName: String
    /// SF Symbol 名称；若设置，优先显示系统图标而非 `imageName`
    public let systemImage: String?
    
    /// 创建引导页面数据
    /// - Parameters:
    ///   - title: 页面标题
    ///   - description: 页面描述文本
    ///   - imageName: 自定义图片资源名称（低优先级）
    ///   - systemImage: SF Symbol 名称；若设置，优先显示系统图标
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
    @State private var completionFeedbackTrigger = false
    
    let pages: [OnboardingPage]
    let onComplete: () -> Void
    
    /// 创建引导视图
    /// - Parameters:
    ///   - pages: 引导页面列表
    ///   - onComplete: 用户完成引导后的回调
    public init(pages: [OnboardingPage], onComplete: @escaping () -> Void) {
        self.pages = pages
        self.onComplete = onComplete
    }
    
    // MARK: - Body

    public var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                pager
                bottomControls
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .accessibleGroup(label: L10n.Onboarding.accessibilityGroup)
        // HIG：翻页用 light（翻书感），完成引导用 success（正向仪式感）
        .sensoryFeedback(.impact(weight: .light), trigger: currentPage)
        .sensoryFeedback(.success, trigger: completionFeedbackTrigger)
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button(L10n.Onboarding.skip) {
                completeOnboarding()
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .controlSize(.small)
            .tint(.secondary)
        }
        .padding(.bottom, 8)
    }

    private var pager: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                OnboardingPageView(page: page)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var bottomControls: some View {
        VStack(spacing: 16) {
            progressDots

            HStack(spacing: 12) {
                if currentPage > 0 {
                    Button(L10n.Onboarding.previous) {
                        withAnimation(.snappy) {
                            currentPage -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle(radius: 14))
                }

                Button(isLastPage ? L10n.Onboarding.getStarted : L10n.Onboarding.next) {
                    if isLastPage {
                        completeOnboarding()
                    } else {
                        withAnimation(.snappy) {
                            currentPage += 1
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 14))
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 10)
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.25))
                    .frame(width: index == currentPage ? 22 : 7, height: 7)
            }
        }
        .animation(.snappy, value: currentPage)
        .accessibilityHidden(true)
    }

    private var isLastPage: Bool {
        pages.isEmpty || currentPage == pages.count - 1
    }
    
    private func completeOnboarding() {
        // 先触发 success 反馈，再 dismiss（确保震动在视图消失前完成）
        completionFeedbackTrigger.toggle()
        onComplete()
        dismiss()
    }
}

/// 单个引导页面视图
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack {
            Spacer(minLength: 24)

            VStack(spacing: 28) {
                icon

                VStack(spacing: 12) {
                    Text(page.title)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                        .accessibleHeader(page.title)

                    Text(page.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessible(label: page.description)
                }
            }
            .frame(maxWidth: 430)
            .padding(.horizontal, 24)
            .padding(.vertical, 42)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color(uiColor: .separator).opacity(0.18), lineWidth: 1)
            }

            Spacer(minLength: 24)
        }
        .padding(.horizontal, 4)
    }

    private var icon: some View {
        Group {
            if let systemImage = page.systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .accessibleImage(label: page.title)
            } else if !page.imageName.isEmpty {
                Image(page.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .accessibleImage(label: page.title)
            }
        }
        .frame(width: 82, height: 82)
        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

/// 引导管理器
///
/// 负责持久化引导完成状态。功能提示已迁移到 TipKit（见 SnapDrillTips.swift）。
@MainActor
@Observable
public final class OnboardingManager {
    /// 共享实例
    public static let shared = OnboardingManager()

    /// 是否需要显示引导流程（首次启动为 `true`，完成后持久化为 `false`）
    public var shouldShowOnboarding: Bool

    private init() {
        self.shouldShowOnboarding = !UserDefaults.standard.bool(forKey: UDKey.hasCompletedOnboarding)
    }

    /// 完成引导
    public func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: UDKey.hasCompletedOnboarding)
        shouldShowOnboarding = false
    }

    /// 重置引导状态（含 TipKit 设备级提示 + Profile 级提示）
    public func resetAll() {
        UserDefaults.standard.set(false, forKey: UDKey.hasCompletedOnboarding)
        shouldShowOnboarding = true
        do {
            try Tips.resetDatastore()
        } catch {
            SnapDrillLogger.generic.error("TipKit 重置失败: \(error.localizedDescription)")
        }
        ProfileTipState().resetAll()
    }
}

/// 默认引导页面
public extension OnboardingPage {
    static let defaultPages: [OnboardingPage] = [
        OnboardingPage(
            title: L10n.Onboarding.pageWelcomeTitle,
            description: L10n.Onboarding.pageWelcomeDescription,
            systemImage: "folder.fill"
        ),
        OnboardingPage(
            title: L10n.Onboarding.pageCaptureTitle,
            description: L10n.Onboarding.pageCaptureDescription,
            systemImage: "camera.fill"
        ),
        OnboardingPage(
            title: L10n.Onboarding.pageReviewTitle,
            description: L10n.Onboarding.pageReviewDescription,
            systemImage: "calendar.badge.clock"
        ),
        OnboardingPage(
            title: L10n.Onboarding.pageExportTitle,
            description: L10n.Onboarding.pageExportDescription,
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
