//
//  CreateReviewItemView.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//

import SwiftUI
import SwiftData

struct CreateReviewItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // 表单数据
    @State private var title = ""
    @State private var question = ""
    @State private var answer = ""
    @State private var explanation = ""
    @State private var subject = ""
    @State private var difficulty: DifficultyLevel = .medium
    @State private var tags: [String] = []
    @State private var tagInput = ""
    
    // UI状态
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    // 依赖注入
    @State private var repository: (any ReviewItemRepository)?
    @State private var createUseCase: (any CreateReviewItemUseCase)?
    
    // 回调
    let onCreated: (ReviewItem) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("标题", text: $title)
                    TextField("科目", text: $subject)
                    
                    Picker("难度", selection: $difficulty) {
                        ForEach(DifficultyLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("题目内容") {
                    TextField("题目", text: $question, axis: .vertical)
                        .lineLimit(3...6)
                    
                    TextField("答案（可选）", text: $answer, axis: .vertical)
                        .lineLimit(2...4)
                    
                    TextField("解析（可选）", text: $explanation, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("标签") {
                    HStack {
                        TextField("添加标签", text: $tagInput)
                            .onSubmit {
                                addTag()
                            }
                        
                        Button("添加") {
                            addTag()
                        }
                        .disabled(tagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    if !tags.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                TagView(tag: tag) {
                                    removeTag(tag)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("创建复习项")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            await createReviewItem()
                        }
                    }
                    .disabled(!isFormValid || isCreating)
                }
            }
            .task {
                await setupDependencies()
            }
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .overlay {
                if isCreating {
                    ProgressView("创建中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func setupDependencies() async {
        repository = SwiftDataReviewItemRepository(modelContext: modelContext)
        if let repo = repository {
            createUseCase = CreateReviewItemUseCaseImpl(repository: repo)
        }
    }
    
    private func addTag() {
        let newTag = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newTag.isEmpty && !tags.contains(newTag) else { return }
        
        tags.append(newTag)
        tagInput = ""
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    private func createReviewItem() async {
        guard let createUseCase = createUseCase else { return }
        
        isCreating = true
        errorMessage = nil
        
        let request = CreateReviewItemRequest(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            question: question.trimmingCharacters(in: .whitespacesAndNewlines),
            answer: answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : answer.trimmingCharacters(in: .whitespacesAndNewlines),
            explanation: explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : explanation.trimmingCharacters(in: .whitespacesAndNewlines),
            imageData: nil, // TODO: 支持图片上传
            subject: subject.trimmingCharacters(in: .whitespacesAndNewlines),
            difficulty: difficulty,
            tags: tags,
            ownerId: UUID(), // TODO: 从当前用户获取
            source: .manual
        )
        
        do {
            let response = try await createUseCase.execute(request)
            await MainActor.run {
                onCreated(response.reviewItem)
                dismiss()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
        
        await MainActor.run {
            isCreating = false
        }
    }
}

// MARK: - Supporting Views

struct TagView: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(12)
    }
}

#Preview {
    CreateReviewItemView { _ in
        // Preview callback
    }
    .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
