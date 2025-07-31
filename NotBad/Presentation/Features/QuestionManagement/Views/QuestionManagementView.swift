import SwiftUI

// MARK: - QuestionManagementView
// 位置: Presentation/Features/QuestionManagement/Views/QuestionManagementView.swift

/// 题目管理主视图
struct QuestionManagementView: View {
    
    // MARK: - Properties
    
    @State private var viewModel = QuestionManagementViewModel()
    @State private var showingAddMethodSheet = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                SearchBarView(text: $viewModel.searchText)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        
                        // 添加题目区域
                        AddQuestionSectionView {
                            showingAddMethodSheet = true
                        }
                        
                        // 最近添加的题目
                        RecentQuestionsView(
                            questions: viewModel.filteredQuestions,
                            onQuestionTap: viewModel.viewQuestionDetail,
                            onEditTap: viewModel.editQuestion,
                            onDeleteTap: { question in
                                Task {
                                    await viewModel.deleteQuestion(question)
                                }
                            }
                        )
                        
                        // 底部间距
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("录题")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refreshQuestions()
            }
            .sheet(isPresented: $showingAddMethodSheet) {
                AddMethodSelectionSheet(
                    methods: viewModel.addMethods,
                    onMethodSelected: { method in
                        viewModel.selectAddMethod(method)
                        showingAddMethodSheet = false
                    }
                )
            }
            .overlay {
                if viewModel.isLoading && viewModel.recentQuestions.isEmpty {
                    LoadingView()
                }
            }
            .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("确定") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
        .task {
            await viewModel.refreshQuestions()
        }
    }
}

// MARK: - SearchBarView

/// 搜索栏视图
struct SearchBarView: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索题目、学科或标签...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button("取消") {
                    text = ""
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - AddQuestionSectionView

/// 添加题目区域视图
struct AddQuestionSectionView: View {
    let onAddTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题和描述
            VStack(spacing: 8) {
                Text("添加错题")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("选择你喜欢的方式来记录题目")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 主要添加按钮
            Button(action: onAddTap) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("开始录题")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - RecentQuestionsView

/// 最近题目列表视图
struct RecentQuestionsView: View {
    let questions: [QuestionItem]
    let onQuestionTap: (QuestionItem) -> Void
    let onEditTap: (QuestionItem) -> Void
    let onDeleteTap: (QuestionItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("最近添加")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(questions.count)道题")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if questions.isEmpty {
                EmptyQuestionsView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(questions) { question in
                        QuestionCard(
                            question: question,
                            onTap: { onQuestionTap(question) },
                            onEdit: { onEditTap(question) },
                            onDelete: { onDeleteTap(question) }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - QuestionCard

/// 题目卡片
struct QuestionCard: View {
    let question: QuestionItem
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingActions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部信息
            HStack {
                // 学科标签
                Text(question.subject)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                
                // 难度标识
                HStack(spacing: 4) {
                    Image(systemName: question.difficulty.icon)
                        .font(.caption)
                    Text(question.difficulty.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(question.difficulty.color)
                
                Spacer()
                
                // 更多操作按钮
                Button(action: { showingActions = true }) {
                    Image(systemName: "ellipsis")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 题目内容
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(question.content)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    // 标签
                    if !question.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(question.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(.systemGray5))
                                        .foregroundColor(.secondary)
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                    
                    // 底部信息
                    HStack {
                        // 题目类型
                        HStack(spacing: 4) {
                            Image(systemName: question.type.icon)
                                .font(.caption2)
                            Text(question.type.rawValue)
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // 正确率（如果有练习记录）
                        if question.correctCount + question.incorrectCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "target")
                                    .font(.caption2)
                                Text("\(Int(question.accuracy * 100))%")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(question.accuracy >= 0.8 ? .green : question.accuracy >= 0.6 ? .orange : .red)
                        }
                        
                        // 创建时间
                        Text(formatRelativeTime(question.createdAt))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .confirmationDialog("题目操作", isPresented: $showingActions) {
            Button("编辑") { onEdit() }
            Button("删除", role: .destructive) { onDelete() }
            Button("取消", role: .cancel) { }
        }
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            return "\(Int(interval/60))分钟前"
        } else if interval < 86400 {
            return "\(Int(interval/3600))小时前"
        } else {
            return "\(Int(interval/86400))天前"
        }
    }
}

// MARK: - EmptyQuestionsView

/// 空状态视图
struct EmptyQuestionsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                Text("还没有题目")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("点击上方按钮开始录题吧")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - AddMethodSelectionSheet

/// 添加方式选择弹窗
struct AddMethodSelectionSheet: View {
    let methods: [AddMethodOption]
    let onMethodSelected: (AddMethodOption) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题
                VStack(spacing: 8) {
                    Text("选择录题方式")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("选择最适合的方式来记录你的错题")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // 方式选项
                VStack(spacing: 16) {
                    ForEach(methods) { method in
                        AddMethodCard(method: method) {
                            onMethodSelected(method)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - AddMethodCard

/// 添加方式卡片
struct AddMethodCard: View {
    let method: AddMethodOption
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 图标
                Image(systemName: method.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(method.color)
                    .cornerRadius(12)
                
                // 内容
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(method.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - LoadingView (复用Dashboard的)

/// 加载视图
struct QuestionLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("加载中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

// MARK: - Preview

#if DEBUG
struct QuestionManagementView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionManagementView()
    }
}
#endif