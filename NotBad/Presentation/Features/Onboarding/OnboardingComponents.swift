//
//  OnboardingComponents.swift
//  NotBad
//
//  引导流程 UI 组件
//

import SwiftUI

// MARK: - RegionOptionButton

/// 地区选择按钮
///
/// 用于引导流程中选择教育体系地区。
struct RegionOptionButton: View {
    let region: EducationRegion
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            // 触觉反馈
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            action()
        } label: {
            HStack(spacing: DesignTokens.Spacing.md) {
                Text(region.flag)
                    .font(.largeTitle)

                VStack(alignment: .leading, spacing: 2) {
                    Text(region.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(region.educationSystemDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.brand.primary)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                    .fill(Color.semantic.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                    .strokeBorder(
                        isSelected ? Color.brand.primary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(region.displayName)
        .accessibilityHint(region.educationSystemDescription)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - GradeOptionButton

/// 年级选择按钮
///
/// 用于引导流程中选择当前年级。
struct GradeOptionButton: View {
    let grade: Grade
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            // 触觉反馈
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            action()
        } label: {
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text(grade.shortLabel)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                    .fill(isSelected ? Color.brand.primary : Color.semantic.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                    .strokeBorder(
                        isSelected ? Color.brand.primary : Color.semantic.separator,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(grade.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - SubjectOptionButton

/// 学科选择按钮
struct SubjectOptionButton: View {
    let subject: Subject
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            action()
        } label: {
            VStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: subject.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : subject.color)
                
                Text(subject.displayName)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                    .fill(isSelected ? subject.color : Color.semantic.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                    .strokeBorder(
                        isSelected ? subject.color : Color.semantic.separator,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .background(Circle().fill(subject.color))
                        .offset(x: 4, y: -4)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(subject.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - EducationRegion Extensions

extension EducationRegion {
    /// 教育体系描述（用于 Onboarding）
    var educationSystemDescription: String {
        switch self {
        case .china:
            return String(localized: "onboarding_education_system_china")
        case .japan:
            return String(localized: "onboarding_education_system_japan")
        case .korea:
            return String(localized: "onboarding_education_system_korea")
        case .singapore:
            return String(localized: "onboarding_education_system_singapore")
        case .international:
            return String(localized: "onboarding_education_system_international")
        case .usa:
            return String(localized: "onboarding_education_system_usa")
        default:
            return String(localized: "onboarding_education_system_other")
        }
    }
}
