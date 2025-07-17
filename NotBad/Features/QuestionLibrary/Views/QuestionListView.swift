import SwiftUI
import SwiftData

struct QuestionListView: View {
    @Environment(\.modelContext) private var context
    @Query var questions: [Question]
    
    @State private var viewModel: QuestionListViewModel?
    @State private var selectedQuestion: Question?
    
    // MARK: - Computed Properties
    private var currentSortDescription: String {
        guard let viewModel = viewModel else { return "加载中..." }
        let filteredCount = viewModel.filteredAndSorted(questions).count
        let sortText = viewModel.sortOption.rawValue
        return "共 \(filteredCount) 道题 · \(sortText)"
    }
    
    private var filteredQuestions: [Question] {
        return viewModel?.filteredAndSorted(questions) ?? []
    }
    
    var body: some View {
        Group {
            if let viewModel = viewModel {
                navigationContent(viewModel: viewModel)
            } else {
                ProgressView("加载中...")
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = QuestionListViewModel(modelContext: context)
            }
            
            Task {
                await viewModel?.loadSearchHistory()
            }
        }
    }
    
    // MARK: - Navigation Content
    @ViewBuilder
    private func navigationContent(viewModel: QuestionListViewModel) -> some View {
        NavigationStack {
            mainContent
                // 移除 .navigationSubtitle，并将其内容合并到 toolbar 的 .principal 位置
                .navigationTitle("") // 清空默认标题，因为我们将在 toolbar 中自定义
                .toolbar {
                    // 主标题和副标题放在 .principal 位置
                    ToolbarItem(placement: .principal) {
                        VStack {
                            Text("题库") // 原始的主标题
                                .font(.headline) // 根据需要调整字体
                            Text(currentSortDescription) // 原始的副标题
                                .font(.subheadline) // 根据需要调整字体
                                .foregroundColor(.secondary)
                        }
                    }

                    // 重新添加 leadingToolbarContent 的内容
                    ToolbarItem(placement: .navigationBarLeading) {
                        leadingToolbarContent(viewModel: viewModel)
                    }

                    // 重新添加 trailingToolbarContent 的内容
                    ToolbarItem(placement: .navigationBarTrailing) {
                        trailingToolbarContent
                    }
                }
                .navigationBarTitleDisplayMode(.inline) // 确保标题区域是紧凑的，便于自定义内容
                .searchable(
                    text: Binding(
                        get: { viewModel.searchText },
                        set: { viewModel.searchText = $0 }
                    ),
                    prompt: "搜索题目、答案或标签"
                ) {
                    searchSuggestions(viewModel: viewModel)
                }
                .onSubmit(of: .search) {
                    handleSearchSubmit(viewModel: viewModel)
                }
                .environment(\.editMode, Binding(
                    get: { viewModel.editMode },
                    set: { viewModel.editMode = $0 }
                ))
                .navigationDestination(item: $selectedQuestion) { question in
                    QuestionDetailView(question: question)
                }
                .sheet(isPresented: Binding(
                    get: { viewModel.showingSortMenu },
                    set: { viewModel.showingSortMenu = $0 }
                )) {
                    sortPicker(viewModel: viewModel)
                }
                .sheet(isPresented: Binding(
                    get: { viewModel.showingFilterMenu },
                    set: { viewModel.showingFilterMenu = $0 }
                )) {
                    filterSheet(viewModel: viewModel)
                }
                .alert("确认删除", isPresented: Binding(
                    get: { viewModel.showingDeleteAlert },
                    set: { viewModel.showingDeleteAlert = $0 }
                )) {
                    deleteAlert(viewModel: viewModel)
                } message: {
                    Text("确定要删除这道题目吗？此操作无法撤销。")
                }
        }
    }
    
    // MARK: - Main Content
    @ViewBuilder
    private var mainContent: some View {
        AdaptiveContainer {
            List {
                ForEach(filteredQuestions) { question in
                    QuestionCard(
                        question: question,
                        searchTerm: viewModel?.searchText ?? "",
                        onTap: {
                            selectedQuestion = question
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(
                        top: .spacingXS,
                        leading: 0,
                        bottom: .spacingXS,
                        trailing: 0
                    ))
                }
                .onDelete(perform: handleDelete)
            }
            .listStyle(.plain)
            // 解决“灰蒙蒙阴影”的关键：隐藏列表的默认滚动内容背景
            .scrollContentBackground(.hidden) // 适用于 iOS 16 及更高版本
            .background(Theme.shared.secondaryBackground) // 应用您的自定义背景色
        }
    }
    
    // MARK: - Search Suggestions
    @ViewBuilder
    private func searchSuggestions(viewModel: QuestionListViewModel) -> some View {
        if viewModel.searchText.isEmpty {
            // 显示搜索历史
            if !viewModel.searchHistory.isEmpty {
                Section("最近搜索") {
                    ForEach(viewModel.searchHistory) { history in
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.gray)
                                .font(.caption)
                            Text(history.term)
                            Spacer()
                            Text("\(history.resultCount)条")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Button(action: {
                                Task {
                                    await viewModel.removeSearchTerm(history.term)
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                        }
                        .searchCompletion(history.term)
                    }
                    
                    if viewModel.searchHistory.count > 1 {
                        Button("清除搜索历史") {
                            Task {
                                await viewModel.clearSearchHistory()
                            }
                        }
                        .foregroundColor(.red)
                        .font(.caption)
                    }
                }
            }
            
            // 显示热门标签
            let suggestions = viewModel.getSearchSuggestions(from: questions)
            if !suggestions.isEmpty {
                Section("热门标签") {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Text(suggestion)
                            .searchCompletion(suggestion)
                    }
                }
            }
        } else {
            // 搜索时显示匹配的建议
            let suggestions = viewModel.getSearchSuggestions(from: questions)
            if !suggestions.isEmpty {
                ForEach(suggestions, id: \.self) { suggestion in
                    Text(suggestion)
                        .searchCompletion(suggestion)
                }
            }
        }
    }
    
    // MARK: - Toolbar Helper Methods (These are now directly used in .toolbar)
    @ViewBuilder
    private func leadingToolbarContent(viewModel: QuestionListViewModel) -> some View {
        if !questions.isEmpty {
            HStack {
                EditButton()
                
                Button(action: {
                    viewModel.showingSortMenu = true
                }) {
                    Image(systemName: viewModel.sortOption.systemImage)
                }
                
                Button(action: {
                    viewModel.showingFilterMenu = true
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(viewModel.hasActiveFilters ? .blue : .primary)
                }
            }
        }
    }
    
    @ViewBuilder
    private var trailingToolbarContent: some View {
        NavigationLink("添加题目") {
            AddQuestionView()
        }
    }
    
    // MARK: - Sort Picker
    @ViewBuilder
    private func sortPicker(viewModel: QuestionListViewModel) -> some View {
        SortPicker(selectedOption: Binding(
            get: { viewModel.sortOption },
            set: { viewModel.sortOption = $0 }
        ))
    }
    
    // MARK: - Filter Sheet
    @ViewBuilder
    private func filterSheet(viewModel: QuestionListViewModel) -> some View {
        NavigationView {
            Form {
                Section("难度筛选") {
                    Picker("难度", selection: Binding(
                        get: { viewModel.selectedDifficulty },
                        set: { viewModel.selectedDifficulty = $0 }
                    )) {
                        Text("全部").tag(nil as Int?)
                        ForEach(1...5, id: \.self) { difficulty in
                            Text(viewModel.difficultyText(for: difficulty)).tag(difficulty as Int?)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Section("标签筛选") {
                    Picker("标签", selection: Binding(
                        get: { viewModel.selectedTag },
                        set: { viewModel.selectedTag = $0 }
                    )) {
                        Text("全部").tag(nil as String?)
                        ForEach(viewModel.availableTags(from: questions), id: \.self) { tag in
                            Text(tag).tag(tag as String?)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            .navigationTitle("筛选条件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("重置") {
                        viewModel.resetFilters()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        viewModel.showingFilterMenu = false
                    }
                }
            }
        }
    }
    
    // MARK: - Delete Alert
    @ViewBuilder
    private func deleteAlert(viewModel: QuestionListViewModel) -> some View {
        Button("取消", role: .cancel) { }
        Button("删除", role: .destructive) {
            Task {
                await viewModel.deleteQuestion()
            }
        }
    }
    
    // MARK: - Helper Methods
    private func handleSearchSubmit(viewModel: QuestionListViewModel) {
        Task {
            await viewModel.saveSearchTerm(viewModel.searchText, resultCount: filteredQuestions.count)
        }
    }
    
    private func handleDelete(offsets: IndexSet) {
        guard let viewModel = viewModel else { return }
        if viewModel.editMode == .active {
            batchDelete(offsets: offsets)
        } else {
            showDeleteAlert(offsets: offsets)
        }
    }
    
    private func showDeleteAlert(offsets: IndexSet) {
        guard let viewModel = viewModel else { return }
        if let index = offsets.first {
            viewModel.prepareDelete(filteredQuestions[index])
        }
    }
    
    private func batchDelete(offsets: IndexSet) {
        guard let viewModel = viewModel else { return }
        let questionsToDelete = offsets.map { filteredQuestions[$0] }
        Task {
            await viewModel.deleteQuestions(questionsToDelete)
        }
    }
}

