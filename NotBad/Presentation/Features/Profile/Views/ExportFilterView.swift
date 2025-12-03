//
//  ExportFilterView.swift
//  NotBad
//
//  导出筛选视图 - 多维度筛选界面
//

import SwiftUI

// MARK: - Export Filter View

/// 导出筛选视图
///
/// 提供多维度的筛选条件设置，包括：
/// - 快捷预设（一键配置常用场景）
/// - 时间范围
/// - 学科筛选
/// - 难度筛选
/// - 掌握程度筛选
/// - 错误类型筛选
struct ExportFilterView: View {
    
    // MARK: - Properties
    
    let exportType: ExportType
    @Bindable var config: ExportFilterConfig
    let allItems: [ReviewItem]
    let onExport: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showAdvancedOptions = false
    
    /// 筛选后的数量
    private var filteredCount: Int {
        config.filter(allItems).count
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // 预览信息
                previewSection
                
                // 快捷预设
                presetsSection
                
                // 时间范围
                dateRangeSection
                
                // 学科筛选
                subjectSection
                
                // 掌握程度筛选（最重要）
                masterySection
                
                // 高级选项
                advancedSection
            }
            .navigationTitle(exportType == .pdf ? "data_export_pdf" : "data_export_csv")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common_cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onExport()
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Text("export_confirm")
                            Text("(\(filteredCount))")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(filteredCount == 0)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("export_filter_preview")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(config.filterDescription)
                        .font(.headline)
                }
                
                Spacer()
                
                // 数量显示
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(filteredCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(filteredCount > 0 ? Color.brand.primary : .secondary)
                    Text("export_items_count")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
            
            // 重置按钮
            if config.hasAnyFilter {
                Button(role: .destructive) {
                    withAnimation(.spring(response: 0.3)) {
                        config.resetAll()
                    }
                } label: {
                    Label("export_reset_filters", systemImage: "arrow.counterclockwise")
                }
            }
        }
    }
    
    // MARK: - Presets Section
    
    private var presetsSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ExportPreset.allCases) { preset in
                        PresetChip(preset: preset) {
                            withAnimation(.spring(response: 0.3)) {
                                config.applyPreset(preset)
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
        } header: {
            Text("export_quick_presets")
        } footer: {
            Text("export_presets_description")
        }
    }
    
    // MARK: - Date Range Section
    
    private var dateRangeSection: some View {
        Section("export_section_time") {
            Picker("export_date_range", selection: $config.dateRangeType) {
                ForEach(ExportDateRangeType.allCases) { range in
                    Label(range.displayName, systemImage: range.icon)
                        .tag(range)
                }
            }
            
            if config.dateRangeType == .custom {
                DatePicker(
                    "export_start_date",
                    selection: $config.customStartDate,
                    in: ...config.customEndDate,
                    displayedComponents: .date
                )
                
                DatePicker(
                    "export_end_date",
                    selection: $config.customEndDate,
                    in: config.customStartDate...,
                    displayedComponents: .date
                )
            }
        }
    }
    
    // MARK: - Subject Section
    
    private var subjectSection: some View {
        Section {
            Toggle("export_filter_by_subject", isOn: $config.filterBySubject.animation(.spring(response: 0.3)))
            
            if config.filterBySubject {
                // 按类别分组显示学科
                ForEach(SubjectCategory.allCases, id: \.self) { category in
                    let subjects = Subject.allCases.filter { $0.category == category }
                    if !subjects.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(category.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(subjects, id: \.self) { subject in
                                    SubjectChip(
                                        subject: subject,
                                        isSelected: config.selectedSubjects.contains(subject)
                                    ) {
                                        withAnimation(.spring(response: 0.2)) {
                                            if config.selectedSubjects.contains(subject) {
                                                config.selectedSubjects.remove(subject)
                                            } else {
                                                config.selectedSubjects.insert(subject)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } header: {
            Text("export_section_subject")
        }
    }
    
    // MARK: - Mastery Section
    
    private var masterySection: some View {
        Section {
            Toggle("export_filter_by_mastery", isOn: $config.filterByMastery.animation(.spring(response: 0.3)))
            
            if config.filterByMastery {
                ForEach(MasteryFilterType.presets, id: \.self) { type in
                    Button {
                        withAnimation(.spring(response: 0.2)) {
                            config.masteryFilterType = type
                        }
                    } label: {
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundStyle(type.color)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.displayName)
                                    .foregroundStyle(.primary)
                                Text(type.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if config.masteryFilterType == type {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.brand.primary)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
        } header: {
            HStack {
                Text("export_section_mastery")
                Spacer()
                Text("export_section_mastery_tip")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } footer: {
            if config.filterByMastery {
                Text("export_mastery_footer")
            }
        }
    }
    
    // MARK: - Advanced Section
    
    private var advancedSection: some View {
        Section {
            DisclosureGroup("export_advanced_options", isExpanded: $showAdvancedOptions) {
                // 难度筛选
                Toggle("export_filter_by_difficulty", isOn: $config.filterByDifficulty.animation(.spring(response: 0.3)))
                
                if config.filterByDifficulty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("export_difficulty_range")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { level in
                                DifficultyStarButton(
                                    level: level,
                                    isInRange: level >= config.minDifficulty && level <= config.maxDifficulty
                                ) {
                                    withAnimation(.spring(response: 0.2)) {
                                        // 点击逻辑：设置范围
                                        if level < config.minDifficulty {
                                            config.minDifficulty = level
                                        } else if level > config.maxDifficulty {
                                            config.maxDifficulty = level
                                        } else if level == config.minDifficulty && level == config.maxDifficulty {
                                            // 如果只选中一个，重置为全部
                                            config.minDifficulty = 1
                                            config.maxDifficulty = 5
                                        } else if level == config.minDifficulty {
                                            config.minDifficulty = level + 1
                                        } else if level == config.maxDifficulty {
                                            config.maxDifficulty = level - 1
                                        } else {
                                            // 点击中间的，调整为只选这个
                                            config.minDifficulty = level
                                            config.maxDifficulty = level
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // 错误类型筛选
                Toggle("export_filter_by_error_type", isOn: $config.filterByErrorType.animation(.spring(response: 0.3)))
                
                if config.filterByErrorType {
                    FlowLayout(spacing: 8) {
                        ForEach(ErrorType.allCases, id: \.self) { errorType in
                            ErrorTypeChip(
                                errorType: errorType,
                                isSelected: config.selectedErrorTypes.contains(errorType)
                            ) {
                                withAnimation(.spring(response: 0.2)) {
                                    if config.selectedErrorTypes.contains(errorType) {
                                        config.selectedErrorTypes.remove(errorType)
                                    } else {
                                        config.selectedErrorTypes.insert(errorType)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

// MARK: - Preset Chip

private struct PresetChip: View {
    let preset: ExportPreset
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: preset.icon)
                    .font(.title2)
                    .foregroundStyle(preset.color)
                    .frame(width: 44, height: 44)
                    .background(preset.color.opacity(0.15))
                    .clipShape(Circle())
                
                Text(preset.displayName)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(width: 70)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Subject Chip

private struct SubjectChip: View {
    let subject: Subject
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(subject.icon)
                    .font(.caption)
                Text(subject.displayName)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.brand.primary : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Error Type Chip

private struct ErrorTypeChip: View {
    let errorType: ErrorType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(errorType.displayName)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Color.brand.primary : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Difficulty Star Button

private struct DifficultyStarButton: View {
    let level: Int
    let isInRange: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: isInRange ? "star.fill" : "star")
                    .font(.title2)
                    .foregroundStyle(isInRange ? .yellow : .secondary)
                Text("\(level)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 44, height: 50)
            .background(isInRange ? Color.yellow.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ExportFilterView(
        exportType: .pdf,
        config: ExportFilterConfig(),
        allItems: [],
        onExport: {},
        onCancel: {}
    )
}
