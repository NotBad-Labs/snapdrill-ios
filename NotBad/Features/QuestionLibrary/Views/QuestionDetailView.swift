//
//  QuestionDetailView.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import SwiftUI
import SwiftData

struct QuestionDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    let question: Question
    @State private var viewModel: QuestionDetailViewModel?
    
    var body: some View {
        Group {
            if let viewModel = viewModel {
                detailContent(viewModel: viewModel)
            } else {
                ProgressView("加载中...")
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = QuestionDetailViewModel(question: question, modelContext: context)
            }
        }
    }
    
    @ViewBuilder
    private func detailContent(viewModel: QuestionDetailViewModel) -> some View {
        NavigationView {
            Form {
                // 基础信息
                Section(header: Text("题目信息")) {
                    if viewModel.isEditing {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("题目内容")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextEditor(text: Binding(
                                get: { viewModel.content },
                                set: { viewModel.content = $0 }
                            ))
                            .frame(minHeight: 60)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("正确答案")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextEditor(text: Binding(
                                get: { viewModel.answer },
                                set: { viewModel.answer = $0 }
                            ))
                            .frame(minHeight: 40)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("题目内容")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(viewModel.content)
                                .font(.body)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("正确答案")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(viewModel.answer)
                                .font(.body)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // 难度和标签
                Section(header: Text("分类信息")) {
                    if viewModel.isEditing {
                        HStack {
                            Text("难度:")
                            Spacer()
                            Stepper(
                                "\(viewModel.difficultyText)(\(viewModel.difficulty)分)",
                                value: Binding(
                                    get: { viewModel.difficulty },
                                    set: { viewModel.difficulty = $0 }
                                ),
                                in: 1...5
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("标签 (用逗号分隔)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("标签", text: Binding(
                                get: { viewModel.tagsInput },
                                set: { viewModel.tagsInput = $0 }
                            ))
                        }
                    } else {
                        HStack {
                            Text("难度:")
                            Spacer()
                            Text("\(viewModel.difficultyText)(\(viewModel.difficulty)分)")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(6)
                        }
                        
                        if !viewModel.tags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("标签")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(viewModel.tags, id: \.self) { tag in
                                            Text(tag)
                                                .font(.caption)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.blue.opacity(0.2))
                                                .foregroundColor(.blue)
                                                .cornerRadius(6)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 错因
                Section(header: Text("错误分析")) {
                    if viewModel.isEditing {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("错因分析 (可选)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextEditor(text: Binding(
                                get: { viewModel.wrongReason },
                                set: { viewModel.wrongReason = $0 }
                            ))
                            .frame(minHeight: 60)
                        }
                    } else {
                        if !viewModel.wrongReason.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("错因分析")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(viewModel.wrongReason)
                                    .font(.body)
                                    .foregroundColor(.red.opacity(0.8))
                            }
                        } else {
                            Text("暂无错因分析")
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                }
                
                // 元数据
                Section(header: Text("题目信息")) {
                    HStack {
                        Text("创建时间:")
                        Spacer()
                        Text(question.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(.secondary)
                    }
                }

                // 复习状态
                Section(header: Text("复习状态")) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("复习状态")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack {
                                Image(systemName: question.isReviewed ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(question.isReviewed ? .green : .gray)
                                Text(question.isReviewed ? "已复习" : "未复习")
                                    .foregroundColor(question.isReviewed ? .green : .primary)
                            }
                        }

                        Spacer()

                        if question.isReviewed {
                            Button("取消复习") {
                                Task {
                                    await viewModel.unmarkAsReviewed()
                                }
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button("标记已复习") {
                                Task {
                                    await viewModel.markAsReviewed()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }

                    if question.reviewCount > 0 {
                        HStack {
                            Text("复习次数:")
                            Spacer()
                            Text("\(question.reviewCount) 次")
                                .foregroundColor(.secondary)
                        }
                    }

                    if let reviewedAt = question.reviewedAt {
                        HStack {
                            Text("最后复习:")
                            Spacer()
                            Text(reviewedAt.formatted(date: .abbreviated, time: .shortened))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("题目详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        if viewModel.hasChanges {
                            viewModel.showingSaveAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isEditing {
                        HStack {
                            Button("取消") {
                                viewModel.discardChanges()
                            }
                            
                            Button("保存") {
                                Task {
                                    await viewModel.saveChanges()
                                }
                            }
                            .disabled(!viewModel.isValid)
                        }
                    } else {
                        Button("编辑") {
                            viewModel.toggleEditing()
                        }
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    if !viewModel.isEditing {
                        Button(role: .destructive) {
                            viewModel.showingDeleteAlert = true
                        } label: {
                            Label("删除题目", systemImage: "trash")
                        }
                    }
                }
            }
            .alert("未保存的更改", isPresented: Binding(
                get: { viewModel.showingSaveAlert },
                set: { viewModel.showingSaveAlert = $0 }
            )) {
                Button("放弃更改") {
                    viewModel.discardChanges()
                    dismiss()
                }
                Button("保存") {
                    Task {
                        await viewModel.saveChanges()
                        dismiss()
                    }
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("您有未保存的更改，要保存吗？")
            }
            .alert("确定删除这道题？", isPresented: Binding(
                get: { viewModel.showingDeleteAlert },
                set: { viewModel.showingDeleteAlert = $0 }
            )) {
                Button("删除", role: .destructive) {
                    Task {
                        await viewModel.deleteQuestion()
                        dismiss()
                    }
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("此操作无法撤销，确定删除这道错题？")
            }
        }
    }
}
