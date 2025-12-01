//
//  OnboardingView.swift
//  NotBad
//
//  首次启动引导视图
//

import SwiftUI

// MARK: - OnboardingView

/// 首次启动引导视图
///
/// 引导用户完成初始设置：
/// 1. 选择国家/地区（确定教育体系）
/// 2. 选择当前年级
struct OnboardingView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var currentStep: OnboardingStep = .welcome
    @State private var selectedRegion: EducationRegion = .china
    @State private var selectedGrade: Grade = .grade7

    // MARK: - Callbacks

    let onComplete: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 进度指示器
            progressIndicator
                .padding(.top, DesignTokens.Spacing.lg)

            // 内容区域
            TabView(selection: $currentStep) {
                welcomeStep
                    .tag(OnboardingStep.welcome)

                regionStep
                    .tag(OnboardingStep.selectRegion)

                gradeStep
                    .tag(OnboardingStep.selectGrade)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)

            // 底部按钮
            bottomButton
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .background(Color.semantic.background)
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(OnboardingStep.allCases) { step in
                Capsule()
                    .fill(step.rawValue <= currentStep.rawValue
                          ? Color.brand.primary
                          : Color.semantic.separator)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
    }

    // MARK: - Welcome Step

    private var welcomeStep: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            // App 图标
            Image(systemName: "checkmark.circle.badge.xmark")
                .font(.system(size: 80))
                .foregroundStyle(Color.brand.primary)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: DesignTokens.Spacing.md) {
                Text("onboarding_welcome_title")
                    .font(.largeTitle.bold())

                Text("onboarding_welcome_subtitle")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Region Step

    private var regionStep: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "globe.asia.australia")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.brand.primary)

                Text("onboarding_region_title")
                    .font(.title.bold())

                Text("onboarding_region_subtitle")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, DesignTokens.Spacing.xl)

            // 地区选择
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(EducationRegion.builtInRegions) { region in
                        RegionOptionButton(
                            region: region,
                            isSelected: selectedRegion == region,
                            action: { selectedRegion = region }
                        )
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
            }

            Spacer()
        }
    }

    // MARK: - Grade Step

    private var gradeStep: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "graduationcap")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.brand.primary)

                Text("onboarding_grade_title")
                    .font(.title.bold())

                Text("onboarding_grade_subtitle")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, DesignTokens.Spacing.xl)

            // 年级选择
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: DesignTokens.Spacing.md) {
                    ForEach(availableGrades) { grade in
                        GradeOptionButton(
                            grade: grade,
                            isSelected: selectedGrade == grade,
                            action: { selectedGrade = grade }
                        )
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
            }
        }
    }

    // MARK: - Bottom Button

    private var bottomButton: some View {
        Button {
            handleButtonTap()
        } label: {
            Text(buttonTitle)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.brand.primary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
        }
    }

    // MARK: - Computed Properties

    private var buttonTitle: LocalizedStringKey {
        switch currentStep {
        case .welcome:
            return "onboarding_button_start"
        case .selectRegion:
            return "onboarding_button_next"
        case .selectGrade:
            return "onboarding_button_done"
        }
    }

    private var availableGrades: [Grade] {
        switch selectedRegion {
        case .china, .japan, .korea, .singapore:
            // 东亚地区：不含幼儿园
            return Grade.allCases.filter { $0 != .kindergarten }
        case .international, .usa:
            // 国际/美国：包含 K-12
            return Grade.allCases
        default:
            return Grade.allCases.filter { $0 != .kindergarten }
        }
    }

    // MARK: - Actions

    private func handleButtonTap() {
        switch currentStep {
        case .welcome:
            withAnimation {
                currentStep = .selectRegion
            }
        case .selectRegion:
            // 保存地区设置
            EducationSystemManager.shared.switchTo(selectedRegion)
            withAnimation {
                currentStep = .selectGrade
            }
        case .selectGrade:
            // 保存年级设置并完成
            UserDefaults.standard.set(selectedGrade.rawValue, forKey: "user_current_grade")
            UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
            onComplete()
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView {
        print("Onboarding completed")
    }
}

