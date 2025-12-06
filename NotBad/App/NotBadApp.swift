//
//  NotBadApp.swift
//  NotBad
//
//  应用入口（实用主义架构）
//

import SwiftUI
import SwiftData

@main
struct NotBadApp: App {
    
    /// SwiftData 模型容器
    let modelContainer: ModelContainer
    
    init() {
        // 初始化 ImageStorageService（确保目录存在）
        _ = ImageStorageService.shared
        
        // 创建 ModelContainer
        modelContainer = Self.createModelContainer()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
    
    /// 创建 ModelContainer
    private static func createModelContainer() -> ModelContainer {
        let schema = Schema([ReviewItemModel.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // 如果失败，尝试删除旧数据库重建
            print("❌ ModelContainer 初始化失败: \(error)")
            
            // 删除旧数据库
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.appendingPathExtension("shm"))
            try? FileManager.default.removeItem(at: url.appendingPathExtension("wal"))
            
            // 重试
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("❌ 无法创建 ModelContainer: \(error)")
            }
        }
    }
}

// MARK: - ContentView（临时入口）

struct ContentView: View {
    var body: some View {
        TabView {
            LibraryView()
                .tabItem {
                    Label("题库", systemImage: "books.vertical")
                }
            
            CaptureView()
                .tabItem {
                    Label("录入", systemImage: "camera")
                }
            
            ReviewView()
                .tabItem {
                    Label("复习", systemImage: "brain")
                }
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
        }
    }
}

// MARK: - Placeholder Views

struct LibraryView: View {
    @Query(sort: \ReviewItemModel.createdAt, order: .reverse)
    private var items: [ReviewItemModel]
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            List {
                if items.isEmpty {
                    ContentUnavailableView(
                        "还没有错题",
                        systemImage: "tray",
                        description: Text("点击录入添加第一道错题")
                    )
                } else {
                    ForEach(items) { item in
                        ItemRow(item: item)
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .navigationTitle("题库")
            .toolbar {
                EditButton()
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            // 删除关联的图片文件
            ImageStorageService.shared.delete(fileName: item.imagePath)
            modelContext.delete(item)
        }
    }
}

struct ItemRow: View {
    let item: ReviewItemModel
    
    var body: some View {
        HStack {
            // 缩略图
            if let image = ImageStorageService.shared.load(fileName: item.imagePath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.secondary.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Text(item.subjectRaw)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.1))
                        .clipShape(Capsule())
                    
                    if item.needsReview {
                        Text("待复习")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            Spacer()
            
            // 掌握程度指示
            Circle()
                .fill(masteryColor(item.masteryLevel))
                .frame(width: 12, height: 12)
        }
        .padding(.vertical, 4)
    }
    
    private func masteryColor(_ level: Int) -> Color {
        switch level {
        case 0: return .red
        case 1: return .orange
        case 2: return .yellow
        case 3: return .green
        default: return .gray
        }
    }
}

struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("图片") {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .onTapGesture { showImagePicker = true }
                    } else {
                        Button("选择图片") {
                            showImagePicker = true
                        }
                    }
                }
                
                Section("信息") {
                    TextField("标题", text: $title)
                }
                
                Section {
                    Button("保存") {
                        saveItem()
                    }
                    .disabled(title.isEmpty && selectedImage == nil)
                }
            }
            .navigationTitle("录入错题")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
    
    private func saveItem() {
        let item = ReviewItemModel(title: title)
        
        // 保存图片到磁盘
        if let image = selectedImage {
            item.imagePath = ImageStorageService.shared.save(image: image, with: item.id)
        }
        
        modelContext.insert(item)
        
        // 重置
        title = ""
        selectedImage = nil
    }
}

struct ReviewView: View {
    @Query(sort: \ReviewItemModel.nextReviewDate)
    private var allItems: [ReviewItemModel]
    
    private var dueItems: [ReviewItemModel] {
        allItems.filter { $0.needsReview }
    }
    
    var body: some View {
        NavigationStack {
            if dueItems.isEmpty {
                ContentUnavailableView(
                    "暂无待复习",
                    systemImage: "checkmark.circle",
                    description: Text("所有错题都已复习完成")
                )
            } else {
                List(dueItems) { item in
                    ItemRow(item: item)
                }
            }
        }
        .navigationTitle("复习")
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("存储") {
                    HStack {
                        Text("图片占用")
                        Spacer()
                        Text(ImageStorageService.shared.formattedSize)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("关于") {
                    Text("NotBad 错题本")
                    Text("版本 1.0")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("设置")
        }
    }
}

// MARK: - ImagePicker

#Preview {
    ContentView()
        .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
