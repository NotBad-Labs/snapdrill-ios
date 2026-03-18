//
//  OnboardingView.swift
//  SnapDrillUI
//
//  Created by NotBad Labs on 2026/01/03.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  用户引导视图
//

import SwiftUI
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
    
    /// 总页数（介绍页 + 字段选择页）
    private var totalPages: Int { pages.count + 1 }

    /// 字段选择页的 tag 索引
    private var fieldSelectionIndex: Int { pages.count }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            // 跳过按钮
            HStack {
                Spacer()
                Button(L10n.Common.onboardingSkip) {
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
                FieldSelectionOnboardingView()
                    .tag(fieldSelectionIndex)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // 底部按钮
            HStack(spacing: 16) {
                if currentPage > 0 {
                    Button(L10n.Common.onboardingPrevious) {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                Button(currentPage == totalPages - 1 ? L10n.Common.onboardingGetStarted : L10n.Common.onboardingNext) {
                    if currentPage == totalPages - 1 {
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
        .accessibleGroup(label: L10n.Common.onboardingAccessibilityGroup)
        // HIG：翻页用 light（翻书感），完成引导用 success（正向仪式感）
        .sensoryFeedback(.impact(weight: .light), trigger: currentPage)
        .sensoryFeedback(.success, trigger: completionFeedbackTrigger)
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
    
    /// 创建功能提示气泡
    /// - Parameters:
    ///   - title: 提示标题
    ///   - message: 提示正文
    ///   - onDismiss: 用户关闭时的回调
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
                .accessibleButton(label: L10n.Onboarding.dismissTooltip)
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
///
/// 负责持久化引导完成状态，并判断是否需要展示功能提示气泡。
@Observable
@MainActor
public final class OnboardingManager {
    /// 共享实例
    public static let shared = OnboardingManager()

    /// 是否需要显示引导流程（首次启动为 `true`，完成后持久化为 `false`）
    public var shouldShowOnboarding: Bool
    /// 各功能提示的显示状态缓存，key 为功能标识符
    public var shouldShowFeatureTooltip: [String: Bool] = [:]
    
    private init() {
        self.shouldShowOnboarding = !UserDefaults.standard.bool(forKey: UDKey.hasCompletedOnboarding)
    }
    
    /// 完成引导
    public func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: UDKey.hasCompletedOnboarding)
        shouldShowOnboarding = false
    }
    
    /// 检查是否应该显示功能提示
    public func shouldShowTooltip(for feature: String) -> Bool {
        if let cached = shouldShowFeatureTooltip[feature] {
            return cached
        }
        
        let hasShown = UserDefaults.standard.bool(forKey: "\(UDKey.hasShownTooltipPrefix)\(feature)")
        shouldShowFeatureTooltip[feature] = !hasShown
        return !hasShown
    }
    
    /// 标记功能提示已显示
    public func markTooltipShown(for feature: String) {
        UserDefaults.standard.set(true, forKey: "\(UDKey.hasShownTooltipPrefix)\(feature)")
        shouldShowFeatureTooltip[feature] = false
    }
    
    /// 重置所有引导状态
    public func resetAll() {
        UserDefaults.standard.set(false, forKey: UDKey.hasCompletedOnboarding)
        shouldShowOnboarding = true
        shouldShowFeatureTooltip.removeAll()
        
        // 清除所有提示记录
        let keys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in keys where key.hasPrefix(UDKey.hasShownTooltipPrefix) {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

/// 默认引导页面
public extension OnboardingPage {
    static let defaultPages: [OnboardingPage] = [
        OnboardingPage(
            title: L10n.Onboarding.pageWelcomeTitle,
            description: L10n.Onboarding.pageWelcomeDescription,
            systemImage: "book.fill"
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

// MARK: - Field Selection

/// Onboarding 字段选择页，让用户在首次使用前配置录入字段
struct FieldSelectionOnboardingView: View {

    @AppStorage(UDKey.captureFieldSubject) private var showSubjectField = true
    @AppStorage(UDKey.captureFieldSource) private var showSourceField = false
    @AppStorage(UDKey.captureFieldDifficulty) private var showDifficultyField = false
    @AppStorage(UDKey.captureFieldGrade) private var showGradeField = false
    @AppStorage(UDKey.captureFieldAnswer) private var showAnswerField = false

    var body: some View {
        // ScrollView 确保小屏设备（iPhone SE）不会截断内容
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 24)

                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .accessibleImage(label: L10n.Onboarding.fieldConfigIcon)

                Text(L10n.Onboarding.fieldConfigTitle)
                    .font(.title)
                    .fontWeight(.bold)
                    .accessibleHeader(L10n.Onboarding.fieldConfigHeader)

                Text(L10n.Onboarding.fieldConfigDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(spacing: 0) {
                    fieldToggle(L10n.Onboarding.fieldSubject, icon: "folder.fill", isOn: $showSubjectField)
                    Divider().padding(.leading, 52)
                    fieldToggle(L10n.Onboarding.fieldSource, icon: "doc.text.fill", isOn: $showSourceField)
                    Divider().padding(.leading, 52)
                    fieldToggle(L10n.Onboarding.fieldDifficulty, icon: "star.fill", isOn: $showDifficultyField)
                    Divider().padding(.leading, 52)
                    fieldToggle(L10n.Onboarding.fieldGrade, icon: "graduationcap.fill", isOn: $showGradeField)
                    Divider().padding(.leading, 52)
                    fieldToggle(L10n.Onboarding.fieldAnswer, icon: "text.bubble.fill", isOn: $showAnswerField)
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .padding(.horizontal, 24)

                Spacer(minLength: 24)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func fieldToggle(_ title: String, icon: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.blue)
                    .frame(width: 28)
                Text(title)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(pages: OnboardingPage.defaultPages) {
        SnapDrillLogger.generic.info("Onboarding completed")
    }
}
