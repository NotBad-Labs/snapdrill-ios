import SwiftUI
import SwiftData

// NotBad App - Swift 6.2 + iOS 26 测试文件
// 用于验证GitHub Copilot集成和代码提示功能

/// 错题实体模型 - 采用Enhanced Actor模式确保并发安全
@Model
final class ReviewItem: Sendable {
    @Attribute(.unique) var id: UUID
    var content: String
    var subject: Subject
    var masteryLevel: MasteryLevel
    var createdAt: Date
    var lastReviewedAt: Date?
    var reviewCount: Int

    init(content: String, subject: Subject) {
        self.id = UUID()
        self.content = content
        self.subject = subject
        self.masteryLevel = .new
        self.createdAt = Date()
        self.reviewCount = 0
    }
}

/// 学科枚举
enum Subject: String, Codable, CaseIterable, Sendable {
    case mathematics = "mathematics"
    case physics = "physics"
    case chemistry = "chemistry"
    case biology = "biology"
    case english = "english"
    case chinese = "chinese"

    var displayName: String {
        switch self {
        case .mathematics: return "数学"
        case .physics: return "物理"
        case .chemistry: return "化学"
        case .biology: return "生物"
        case .english: return "英语"
        case .chinese: return "语文"
        }
    }
}

/// 掌握度级别
enum MasteryLevel: String, Codable, CaseIterable, Sendable {
    case new = "new"
    case learning = "learning"
    case reviewing = "reviewing"
    case mastered = "mastered"

    var description: String {
        switch self {
        case .new: return "新错题"
        case .learning: return "学习中"
        case .reviewing: return "复习中"
        case .mastered: return "已掌握"
        }
    }
}

/// Enhanced Actor模式的复习管理器
@globalActor
actor ReviewManagerActor {
    static let shared = ReviewManagerActor()

    private var reviewItems: [ReviewItem] = []

    func addReviewItem(_ item: ReviewItem) {
        reviewItems.append(item)
    }

    func getItemsForReview() -> [ReviewItem] {
        return reviewItems.filter { item in
            item.masteryLevel != .mastered
        }
    }

    // TODO: Copilot应该能够自动建议间隔重复算法的实现
    func calculateNextReviewDate(for item: ReviewItem) -> Date {
        // 请在这里实现间隔重复算法
        // Copilot提示：基于艾宾浩斯遗忘曲线和SM-2算法

        return Date()
    }
}

/// SwiftUI视图 - 使用iOS 26最新特性
struct ReviewItemListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var reviewItems: [ReviewItem]
    @State private var showingAddItem = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(reviewItems) { item in
                    ReviewItemRow(item: item)
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("错题本")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        showingAddItem = true
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                // TODO: Copilot应该能够建议AddReviewItemView的实现
                AddReviewItemView()
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(reviewItems[index])
            }
        }
    }
}

/// 错题行视图
struct ReviewItemRow: View {
    let item: ReviewItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.subject.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)

                Spacer()

                Text(item.masteryLevel.description)
                    .font(.caption)
                    .foregroundColor(masteryLevelColor)
            }

            Text(item.content)
                .font(.body)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }

    private var masteryLevelColor: Color {
        switch item.masteryLevel {
        case .new: return .red
        case .learning: return .orange
        case .reviewing: return .yellow
        case .mastered: return .green
        }
    }
}

/// 添加错题视图（占位符）
struct AddReviewItemView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var content = ""
    @State private var selectedSubject = Subject.mathematics

    var body: some View {
        NavigationStack {
            Form {
                Section("题目内容") {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                }

                Section("学科") {
                    Picker("选择学科", selection: $selectedSubject) {
                        ForEach(Subject.allCases, id: \.self) { subject in
                            Text(subject.displayName).tag(subject)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("添加错题")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        // TODO: 保存逻辑
                        dismiss()
                    }
                    .disabled(content.isEmpty)
                }
            }
        }
    }
}

// MARK: - Copilot测试区域
// 在下面的区域中，请测试GitHub Copilot的代码建议功能：

// 1. 尝试输入注释："// 实现OCR文本识别功能"，看Copilot是否能建议相关代码

// 2. 尝试输入函数签名："func performOCR(on image: UIImage) async throws -> String"，看是否有实现建议

// 3. 尝试输入类定义："class CloudSyncService"，看是否能建议CloudKit集成代码

// 4. 测试SwiftUI组件建议：输入"struct DiscoveryCard: View"

// 5. 测试Enhanced Actor模式：输入"@globalActor actor OCRServiceActor"
