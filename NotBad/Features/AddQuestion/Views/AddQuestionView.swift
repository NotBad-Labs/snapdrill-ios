//
//  AddQuestionView.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import SwiftUI
import SwiftData

struct AddQuestionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // 直接在 View 中管理状态，但使用 ViewModel 的逻辑
    @State private var content: String = ""
    @State private var answer: String = ""
    @State private var difficulty: Int = 3
    @State private var tagsInput: String = ""
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    // 学科选择相关状态
    @State private var selectedSubjects: Set<Subject> = []
    @State private var customSubjects: [Subject] = []
    @State private var showingAddCustomSubject = false
    @State private var customSubjectName = ""
    
    // 计算属性
    private var isValid: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var tags: [String] {
        tagsInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private var difficultyText: String {
        switch difficulty {
        case 1: return "基础题"
        case 2: return "简单题"
        case 3: return "中等题"
        case 4: return "困难题"
        case 5: return "极难题"
        default: return "中等题"
        }
    }
    
    var body: some View {
        Form {
            // 基础信息
            Section(header: Text("题目内容")) {
                TextField("请输入题干", text: $content)
            }
            
            Section(header: Text("正确答案")) {
                TextField("请输入答案", text: $answer)
            }
            
            // 学科选择
            Section(header: Text("学科")) {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80))
                ], spacing: 8) {
                    ForEach(Subject.coreSubjects + customSubjects) { subject in
                        subjectTagView(subject: subject)
                    }
                    
                    // 添加自定义学科按钮
                    Button(action: {
                        showingAddCustomSubject = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("添加")
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.gray)
                        .cornerRadius(8)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // 可选信息
            Section(header: Text("可选信息")) {
                // 难度选择
                HStack {
                    Text("难度:")
                    Spacer()
                    Stepper(
                        "\(difficultyText)(\(difficulty)分)",
                        value: $difficulty,
                        in: 1...5
                    )
                }
                
                // 标签输入
                VStack(alignment: .leading, spacing: 4) {
                    TextField("标签 (用逗号分隔)", text: $tagsInput)
                    
                    // 标签预览
                    if !tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            }
            
            // 保存按钮
            Section {
                Button("保存题目") {
                    saveQuestion()
                }
                .disabled(!isValid)
            }
        }
        .navigationTitle("添加题目")
        .alert("错误", isPresented: $showError) {
            Button("确定") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveQuestion() {
        do {
            let question = Question(
                content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                answer: answer.trimmingCharacters(in: .whitespacesAndNewlines),
                tags: tags,
                difficulty: difficulty
            )
            
            context.insert(question)
            try context.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    // 学科标签视图
    @ViewBuilder
    private func subjectTagView(subject: Subject) -> some View {
        Button(action: {
            if selectedSubjects.contains(subject) {
                selectedSubjects.remove(subject)
            } else {
                selectedSubjects.insert(subject)
            }
        }) {
            Text(subject.name)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(selectedSubjects.contains(subject) ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(selectedSubjects.contains(subject) ? .white : .primary)
                .cornerRadius(8)
        }
    }
}
