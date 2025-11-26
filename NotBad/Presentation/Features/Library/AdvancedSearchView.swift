//
//  AdvancedSearchView.swift
//  NotBad
//
//  高级搜索视图
//

import SwiftUI
import SwiftData

// MARK: - AdvancedSearchView

/// 高级搜索视图
///
/// 提供多条件筛选功能，支持按学科、难度、掌握程度、日期等条件组合搜索。
struct AdvancedSearchView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Bindings
    
    /// 筛选条件
    @Binding var searchCriteria: SearchCriteria
    
    // MARK: - State
    
    /// 本地编辑的条件副本
    @State private var localCriteria: SearchCriteria
    
    // MARK: - Init
    
    init(searchCriteria: Binding<SearchCriteria>) {
        _searchCriteria = searchCriteria
        _localCriteria = State(initialValue: searchCriteria.wrappedValue)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // 关键词搜索
                Section("关键词") {
                    TextField("搜索标题、笔记、知识点", text: $localCriteria.keyword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                // 学科筛选
                Section("学科") {
                    SubjectSelectionGrid(selectedSubjects: $localCriteria.subjects)
                }
                
                // 难度筛选
                Section("难度") {
                    DifficultySelectionRow(selectedDifficulties: $localCriteria.difficulties)
                }
                
                // 掌握程度筛选
                Section("掌握程度") {
                    MasterySelectionRow(selectedMasteries: $localCriteria.masteryLevels)
                }
                
                // 日期范围
                Section("创建日期") {
                    DateRangeRow(dateRange: $localCriteria.dateRange)
                }
                
                // 其他条件
                Section("其他条件") {
                    Toggle("仅显示待复习", isOn: $localCriteria.needsReviewOnly)
                    Toggle("仅显示已逾期", isOn: $localCriteria.overdueOnly)
                    Toggle("仅显示有图片", isOn: $localCriteria.hasImageOnly)
                    Toggle("仅显示有笔记", isOn: $localCriteria.hasNoteOnly)
                }
                
                // 重置按钮
                Section {
                    Button("重置所有条件", role: .destructive) {
                        withAnimation {
                            localCriteria = SearchCriteria()
                        }
                    }
                }
            }
            .navigationTitle("高级搜索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("应用") {
                        searchCriteria = localCriteria
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - SearchCriteria

/// 搜索条件模型
struct SearchCriteria: Equatable, Sendable {
    /// 关键词
    var keyword: String = ""
    
    /// 选中的学科
    var subjects: Set<Subject> = []
    
    /// 选中的难度
    var difficulties: Set<Difficulty> = []
    
    /// 选中的掌握程度
    var masteryLevels: Set<MasteryLevel> = []
    
    /// 日期范围
    var dateRange: DateRangeOption = .all
    
    /// 仅显示待复习
    var needsReviewOnly: Bool = false
    
    /// 仅显示已逾期
    var overdueOnly: Bool = false
    
    /// 仅显示有图片
    var hasImageOnly: Bool = false
    
    /// 仅显示有笔记
    var hasNoteOnly: Bool = false
    
    /// 是否有活动筛选条件
    var hasActiveFilters: Bool {
        !keyword.isEmpty ||
        !subjects.isEmpty ||
        !difficulties.isEmpty ||
        !masteryLevels.isEmpty ||
        dateRange != .all ||
        needsReviewOnly ||
        overdueOnly ||
        hasImageOnly ||
        hasNoteOnly
    }
    
    /// 活动筛选条件数量
    var activeFilterCount: Int {
        var count = 0
        if !keyword.isEmpty { count += 1 }
        if !subjects.isEmpty { count += 1 }
        if !difficulties.isEmpty { count += 1 }
        if !masteryLevels.isEmpty { count += 1 }
        if dateRange != .all { count += 1 }
        if needsReviewOnly { count += 1 }
        if overdueOnly { count += 1 }
        if hasImageOnly { count += 1 }
        if hasNoteOnly { count += 1 }
        return count
    }
}

// MARK: - DateRangeOption

/// 日期范围选项
enum DateRangeOption: String, CaseIterable, Sendable {
    case all = "全部时间"
    case today = "今天"
    case thisWeek = "本周"
    case thisMonth = "本月"
    case lastMonth = "上月"
    case thisYear = "今年"
    case custom = "自定义"
    
    /// 获取日期范围
    var dateRange: ClosedRange<Date>? {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .all:
            return nil
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return start...end
        case .thisWeek:
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
            return start...end
        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return start...end
        case .lastMonth:
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let start = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)!
            return start...thisMonthStart
        case .thisYear:
            let start = calendar.date(from: calendar.dateComponents([.year], from: now))!
            let end = calendar.date(byAdding: .year, value: 1, to: start)!
            return start...end
        case .custom:
            return nil
        }
    }
}

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

// MARK: - SearchCriteria Extension for Filtering

extension SearchCriteria {
    
    /// 应用筛选条件到错题列表
    func filter(_ items: [ReviewItem]) -> [ReviewItem] {
        items.filter { item in
            // 关键词筛选
            if !keyword.isEmpty {
                let lowercasedKeyword = keyword.lowercased()
                let matchesKeyword = item.title.lowercased().contains(lowercasedKeyword) ||
                    item.note.lowercased().contains(lowercasedKeyword) ||
                    item.knowledgePoints.matches(keyword)
                if !matchesKeyword { return false }
            }
            
            // 学科筛选
            if !subjects.isEmpty && !subjects.contains(item.subject) {
                return false
            }
            
            // 难度筛选
            if !difficulties.isEmpty && !difficulties.contains(item.difficulty) {
                return false
            }
            
            // 掌握程度筛选
            if !masteryLevels.isEmpty && !masteryLevels.contains(item.mastery) {
                return false
            }
            
            // 日期范围筛选
            if let range = dateRange.dateRange {
                if !range.contains(item.createdAt) {
                    return false
                }
            }
            
            // 待复习筛选
            if needsReviewOnly && !item.needsReview {
                return false
            }
            
            // 逾期筛选
            if overdueOnly && !item.isOverdue {
                return false
            }
            
            // 有图片筛选
            if hasImageOnly && !item.hasImage {
                return false
            }
            
            // 有笔记筛选
            if hasNoteOnly && !item.hasNote {
                return false
            }
            
            return true
        }
    }
}

// MARK: - Preview

#Preview {
    AdvancedSearchView(searchCriteria: .constant(SearchCriteria()))
}
