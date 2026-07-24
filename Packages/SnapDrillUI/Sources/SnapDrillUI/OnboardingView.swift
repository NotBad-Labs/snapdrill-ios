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
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                topBar
                pager
                bottomControls
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
            .padding(.bottom, 20)
        }
        .accessibleGroup(label: L10n.Onboarding.accessibilityGroup, combineChildren: false)
        // HIG：翻页用 light（翻书感），完成引导用 success（正向仪式感）
        .sensoryFeedback(.impact(weight: .light), trigger: currentPage)
        .sensoryFeedback(.success, trigger: completionFeedbackTrigger)
    }

    // 顶栏：左「上一页」（page>0 才出现）+ 右「跳过」，都用无边框文字，克制不抢焦点。
    private var topBar: some View {
        HStack {
            if currentPage > 0 {
                Button {
                    withAnimation(.snappy) { currentPage -= 1 }
                } label: {
                    Label(L10n.Onboarding.previous, systemImage: "chevron.backward")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityIdentifier("onboarding.previous")
            }

            Spacer()

            Button(L10n.Onboarding.skip) {
                completeOnboarding()
            }
            .font(.subheadline.weight(.medium))
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityIdentifier("onboarding.skip")
        }
        .frame(minHeight: 44)
        .padding(.bottom, 4)
    }

    private var pager: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                OnboardingPageView(page: page, index: index)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    // 底部：进度点 + 一个自信的全宽胶囊主按钮，主行动点独占底部、层级清晰（Apple 现代引导页做法）。
    private var bottomControls: some View {
        VStack(spacing: 20) {
            progressDots

            Button(isLastPage ? L10n.Onboarding.getStarted : L10n.Onboarding.next) {
                if isLastPage {
                    completeOnboarding()
                } else {
                    withAnimation(.snappy) {
                        currentPage += 1
                    }
                }
            }
            .font(.headline)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(Color(red: 0.03, green: 0.29, blue: 0.60))
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier(isLastPage ? "onboarding.getStarted" : "onboarding.next")
        }
        .padding(.top, 8)
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.22))
                    .frame(width: index == currentPage ? 24 : 7, height: 7)
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
    let index: Int
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 24)

                    // 全屏留白，无卡片：大图标 + 大标题 + 次级描述，垂直居中。
                    VStack(spacing: dynamicTypeSize.isAccessibilitySize ? 24 : 36) {
                        if !dynamicTypeSize.isAccessibilitySize {
                            icon
                        }

                        VStack(spacing: 14) {
                            Text(page.title)
                                .font(.largeTitle.bold())
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibleHeader(page.title)

                            Text(page.description)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: 340)
                                .accessible(label: page.description)
                        }
                    }
                    .padding(.horizontal, 8)
                    .accessibilityIdentifier("onboarding.page.\(index)")

                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: proxy.size.height)
            }
            .scrollIndicators(.hidden)
        }
    }

    // Hero 图标：SF Symbol（hierarchical 渲染，有层次不扁平）坐在柔和同色圆里，
    // 给图标存在感又不落入「设置行小方块」的模板感。
    private var icon: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.12))
                .frame(width: 128, height: 128)

            Group {
                if let systemImage = page.systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 54, weight: .regular))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.accentColor)
                        .accessibleImage(label: page.title)
                } else if !page.imageName.isEmpty {
                    Image(page.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .accessibleImage(label: page.title)
                }
            }
        }
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
            title: L10n.Onboarding.pageOrganizeTitle,
            description: L10n.Onboarding.pageOrganizeDescription,
            systemImage: "magnifyingglass"
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
