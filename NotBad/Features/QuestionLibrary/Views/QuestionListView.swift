//
//  QuestionListView.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import SwiftUI
import SwiftData

struct QuestionListView: View {
    @Environment(\.modelContext) private var context
    @Query var questions: [Question]
    
    @State private var viewModel: QuestionListViewModel
    
    init() {
        // 临时初始化，在 onAppear 中设置正确的 context
        _viewModel = State(initialValue: QuestionListViewModel(modelContext: ModelContext()))
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.filteredAndSorted(questions)) { question in
                    VStack(alignment: .leading) {
                        Text(question.content)
                            .font(.headline)
                        Text("答案：\(question.answer)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .onDelete(perform: viewModel.editMode == .active ? batchDelete : showDeleteAlert)
            }
            .navigationTitle("题库")
            .environment(\.editMode, $viewModel.editMode)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink("添加题目") {
                        AddQuestionView()
                    }
                }
            }
            .confirmationDialog("排序方式", isPresented: $viewModel.showingSortMenu) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(option.rawValue) {
                        viewModel.sortOption = option
                    }
                }
                Button("取消", role: .cancel) { }
            }
            .sheet(isPresented: $viewModel.showingFilterMenu) {
                filterSheet
            }
            .alert("确认删除", isPresented: $viewModel.showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    Task {
                        await viewModel.deleteQuestion()
                    }
                }
            } message: {
                Text("确定要删除这道题目吗？此操作无法撤销。")
            }
        }
        .onAppear {
            viewModel = QuestionListViewModel(modelContext: context)
        }
    }
    
    private var filterSheet: some View {
        NavigationView {
            Form {
                Section("难度筛选") {
                    Picker("难度", selection: $viewModel.selectedDifficulty) {
                        Text("全部").tag(nil as Int?)
                        ForEach(1...5, id: \.self) { difficulty in
                            Text(viewModel.difficultyText(for: difficulty)).tag(difficulty as Int?)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Section("标签筛选") {
                    Picker("标签", selection: $viewModel.selectedTag) {
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
    
    private func showDeleteAlert(offsets: IndexSet) {
        if let index = offsets.first {
            viewModel.prepareDelete(viewModel.filteredAndSorted(questions)[index])
        }
    }
    
    private func batchDelete(offsets: IndexSet) {
        let questionsToDelete = offsets.map { viewModel.filteredAndSorted(questions)[$0] }
        Task {
            await viewModel.deleteQuestions(questionsToDelete)
        }
    }
}