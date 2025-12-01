//
//  AdvancedSearchComponents.swift
//  NotBad
//
//  Created by LIAOYIMING on 2025/6/5.
//

import SwiftUI

// MARK: - SubjectSelectionGrid

/// 学科选择网格
struct SubjectSelectionGrid: View {
    @Binding var selectedSubjects: Set<Subject>

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.sm) {
            ForEach(Subject.allCases, id: \.self) { subject in
                SelectionChip(
                    title: subject.displayName,
                    icon: subject.icon,
                    color: subject.color,
                    isSelected: selectedSubjects.contains(subject)
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        if selectedSubjects.contains(subject) {
                            selectedSubjects.remove(subject)
                        } else {
                            selectedSubjects.insert(subject)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - DifficultySelectionRow

/// 难度选择行
struct DifficultySelectionRow: View {
    @Binding var selectedDifficulties: Set<Difficulty>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    SelectionChip(
                        title: difficulty.displayName,
                        icon: "star.fill",
                        color: difficulty.color,
                        isSelected: selectedDifficulties.contains(difficulty)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            if selectedDifficulties.contains(difficulty) {
                                selectedDifficulties.remove(difficulty)
                            } else {
                                selectedDifficulties.insert(difficulty)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - MasterySelectionRow

/// 掌握程度选择行
struct MasterySelectionRow: View {
    @Binding var selectedMasteries: Set<MasteryLevel>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(MasteryLevel.allCases, id: \.self) { mastery in
                    SelectionChip(
                        title: mastery.displayName,
                        icon: mastery.icon,
                        color: mastery.color,
                        isSelected: selectedMasteries.contains(mastery)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            if selectedMasteries.contains(mastery) {
                                selectedMasteries.remove(mastery)
                            } else {
                                selectedMasteries.insert(mastery)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - DateRangeRow

/// 日期范围选择行
struct DateRangeRow: View {
    @Binding var dateRange: DateRangeOption

    var body: some View {
        Picker("日期范围", selection: $dateRange) {
            ForEach(DateRangeOption.allCases.filter { $0 != .custom }, id: \.self) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(.menu)
    }
}

// MARK: - SelectionChip

/// 可选择的筛选芯片
struct SelectionChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(isSelected ? color.opacity(0.2) : Color.secondary.opacity(0.1))
            .foregroundStyle(isSelected ? color : .secondary)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(isSelected ? color : .clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
