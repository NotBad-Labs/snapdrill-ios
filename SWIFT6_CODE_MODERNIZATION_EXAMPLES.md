# Swift 6 代码现代化示例

## 🎯 现代化目标

将NotBad错题本App的代码全面现代化到Swift 6标准，充分利用新语言特性和iOS 18新功能。

---

## 🔄 并发模型现代化

### **1. 服务层Actor化**

#### **当前代码 (Swift 5.0)**
```swift
class OCRService {
    private var isProcessing = false
    private let queue = DispatchQueue(label: "ocr.processing", qos: .userInitiated)
    
    func recognizeText(from image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard !isProcessing else {
            completion(.failure(OCRError.processingInProgress))
            return
        }
        
        isProcessing = true
        queue.async { [weak self] in
            // 处理逻辑
            let result = self?.processImage(image)
            
            DispatchQueue.main.async {
                self?.isProcessing = false
                completion(result ?? .failure(OCRError.processingFailed))
            }
        }
    }
    
    private func processImage(_ image: UIImage) -> Result<String, Error> {
        // OCR处理逻辑
        return .success("识别结果")
    }
}
```

#### **Swift 6 现代化后**
```swift
actor OCRService {
    private var isProcessing = false
    private let visionRequest = VNRecognizeTextRequest()
    
    func recognizeText(from image: UIImage) async throws -> String {
        guard !isProcessing else {
            throw OCRError.processingInProgress
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        return try await processImage(image)
    }
    
    private func processImage(_ image: UIImage) async throws -> String {
        // 类型安全的并发处理
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        
        try handler.perform([visionRequest])
        
        guard let observations = visionRequest.results else {
            throw OCRError.noTextDetected
        }
        
        return observations.compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }
}
```

### **2. 数据层现代化**

#### **当前代码 (Swift 5.0)**
```swift
class ReviewItemRepository {
    private let context: NSManagedObjectContext
    private let queue = DispatchQueue(label: "repository.queue")
    
    func create(_ item: ReviewItem, completion: @escaping (Result<ReviewItem, Error>) -> Void) {
        queue.async { [weak self] in
            guard let self = self else {
                completion(.failure(RepositoryError.contextUnavailable))
                return
            }
            
            do {
                let entity = ReviewItemEntity(context: self.context)
                entity.id = item.id
                entity.title = item.title
                entity.content = item.content
                
                try self.context.save()
                completion(.success(item))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
```

#### **Swift 6 现代化后**
```swift
actor ReviewItemRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func create(_ item: ReviewItem) async throws -> ReviewItem {
        try await withCheckedThrowingContinuation { continuation in
            modelContext.insert(item)
            
            do {
                try modelContext.save()
                continuation.resume(returning: item)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func getAll() async throws -> [ReviewItem] {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let descriptor = FetchDescriptor<ReviewItem>()
                let items = try modelContext.fetch(descriptor)
                continuation.resume(returning: items)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func batchUpdateMasteryLevel(_ items: [ReviewItem], to level: MasteryLevel) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try modelContext.transaction {
                    for item in items {
                        item.masteryLevel = level
                        item.updatedAt = Date()
                    }
                }
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
```

---

## 🎨 SwiftUI 现代化

### **1. 状态管理现代化**

#### **当前代码 (Swift 5.0)**
```swift
class ReviewItemViewModel: ObservableObject {
    @Published var items: [ReviewItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let repository: ReviewItemRepository
    
    init(repository: ReviewItemRepository) {
        self.repository = repository
    }
    
    func loadItems() {
        isLoading = true
        errorMessage = nil
        
        repository.getAll { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let items):
                    self?.items = items
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
```

#### **Swift 6 现代化后**
```swift
@Observable
@MainActor
class ReviewItemViewModel {
    var items: [ReviewItem] = []
    var isLoading = false
    var errorMessage: String?
    
    private let repository: any ReviewItemRepository
    
    init(repository: any ReviewItemRepository) {
        self.repository = repository
    }
    
    func loadItems() async {
        isLoading = true
        errorMessage = nil
        
        do {
            items = try await repository.getAll()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createItem(_ item: ReviewItem) async {
        do {
            let createdItem = try await repository.create(item)
            items.append(createdItem)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### **2. 视图现代化**

#### **当前代码 (Swift 5.0)**
```swift
struct ReviewItemListView: View {
    @StateObject private var viewModel = ReviewItemViewModel()
    @State private var showingCreateSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("加载中...")
                } else if viewModel.items.isEmpty {
                    EmptyStateView()
                } else {
                    List(viewModel.items) { item in
                        ReviewItemRowView(item: item)
                    }
                }
            }
            .navigationTitle("复习项")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        showingCreateSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateReviewItemView()
            }
            .onAppear {
                viewModel.loadItems()
            }
        }
    }
}
```

#### **Swift 6 现代化后**
```swift
struct ReviewItemListView: View {
    @State private var viewModel: ReviewItemViewModel?
    @State private var showingCreateSheet = false
    @State private var selectedItem: ReviewItem?
    
    var body: some View {
        NavigationStack {
            VStack {
                if let viewModel = viewModel {
                    if viewModel.isLoading {
                        ProgressView("加载中...")
                    } else if viewModel.items.isEmpty {
                        EmptyStateView {
                            showingCreateSheet = true
                        }
                    } else {
                        List(viewModel.items) { item in
                            ReviewItemRowView(item: item)
                                .onTapGesture {
                                    selectedItem = item
                                }
                        }
                        .refreshable {
                            await viewModel.loadItems()
                        }
                    }
                } else {
                    ProgressView("初始化中...")
                }
            }
            .navigationTitle("复习项")
            .navigationDestination(item: $selectedItem) { item in
                ReviewItemDetailView(item: item)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        showingCreateSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateReviewItemView { item in
                    Task {
                        await viewModel?.createItem(item)
                    }
                }
            }
            .task {
                await setupViewModel()
            }
        }
    }
    
    @MainActor
    private func setupViewModel() async {
        let repository = SwiftDataRepository(modelContext: ModelContext(try! ModelContainer(for: ReviewItem.self)))
        viewModel = ReviewItemViewModel(repository: repository)
        await viewModel?.loadItems()
    }
}
```

---

## 🔒 类型安全现代化

### **1. Sendable协议**

#### **数据模型**
```swift
// Swift 6 现代化
struct ReviewItem: Sendable, Codable, Identifiable {
    let id: UUID
    let content: ReviewContent
    let metadata: ReviewMetadata
    let studyHistory: [StudyRecord]
    let masteryLevel: MasteryLevel
    
    init(
        id: UUID = UUID(),
        content: ReviewContent,
        metadata: ReviewMetadata,
        studyHistory: [StudyRecord] = [],
        masteryLevel: MasteryLevel = .notMastered
    ) {
        self.id = id
        self.content = content
        self.metadata = metadata
        self.studyHistory = studyHistory
        self.masteryLevel = masteryLevel
    }
}

struct ReviewContent: Sendable, Codable {
    let title: String
    let question: String
    let answer: String?
    let explanation: String?
    let imageData: Data?
    let subject: String
    let difficulty: DifficultyLevel
    let tags: [String]
}

struct ReviewMetadata: Sendable, Codable {
    let createdAt: Date
    let updatedAt: Date
    let lastReviewedAt: Date?
    let parentShareStatus: ParentShareStatus
}
```

### **2. 错误处理现代化**

#### **当前代码 (Swift 5.0)**
```swift
enum OCRError: Error {
    case processingInProgress
    case processingFailed
    case noTextDetected
    case invalidImage
}
```

#### **Swift 6 现代化后**
```swift
enum OCRError: LocalizedError, Sendable {
    case processingInProgress
    case processingFailed(Error)
    case noTextDetected
    case invalidImage
    case unsupportedImageFormat
    
    var errorDescription: String? {
        switch self {
        case .processingInProgress:
            return "OCR处理正在进行中，请稍后再试"
        case .processingFailed(let error):
            return "OCR处理失败: \(error.localizedDescription)"
        case .noTextDetected:
            return "未检测到文字，请确保图片清晰"
        case .invalidImage:
            return "图片格式无效，请重新选择"
        case .unsupportedImageFormat:
            return "不支持的图片格式"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .processingInProgress:
            return "请等待当前处理完成"
        case .processingFailed:
            return "请检查网络连接后重试"
        case .noTextDetected:
            return "请选择包含清晰文字的图片"
        case .invalidImage, .unsupportedImageFormat:
            return "请选择JPG或PNG格式的图片"
        }
    }
}
```

---

## ⚡ 性能优化现代化

### **1. 并发处理优化**

#### **批量处理**
```swift
// Swift 6 现代化
actor BatchProcessor {
    func processImages(_ images: [UIImage]) async throws -> [String] {
        try await withThrowingTaskGroup(of: String.self) { group in
            for image in images {
                group.addTask {
                    try await self.processSingleImage(image)
                }
            }
            
            var results: [String] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }
    
    private func processSingleImage(_ image: UIImage) async throws -> String {
        // 单个图片处理逻辑
        return "处理结果"
    }
}
```

### **2. 内存管理优化**

#### **图片缓存现代化**
```swift
// Swift 6 现代化
actor ImageCache {
    private var cache: [String: UIImage] = [:]
    private let maxCacheSize: Int
    private let maxMemoryUsage: Int
    
    init(maxCacheSize: Int = 100, maxMemoryUsage: Int = 50 * 1024 * 1024) {
        self.maxCacheSize = maxCacheSize
        self.maxMemoryUsage = maxMemoryUsage
    }
    
    func image(for key: String) -> UIImage? {
        return cache[key]
    }
    
    func setImage(_ image: UIImage, for key: String) {
        // 检查缓存大小
        if cache.count >= maxCacheSize {
            // 移除最旧的缓存
            if let firstKey = cache.keys.first {
                cache.removeValue(forKey: firstKey)
            }
        }
        
        cache[key] = image
    }
    
    func clearCache() {
        cache.removeAll()
    }
    
    func getCacheInfo() -> (count: Int, memoryUsage: Int) {
        let memoryUsage = cache.values.reduce(0) { total, image in
            total + (image.cgImage?.width ?? 0) * (image.cgImage?.height ?? 0) * 4
        }
        return (cache.count, memoryUsage)
    }
}
```

---

## 🧪 测试现代化

### **1. 单元测试现代化**

#### **当前代码 (Swift 5.0)**
```swift
class ReviewItemViewModelTests: XCTestCase {
    var viewModel: ReviewItemViewModel!
    var mockRepository: MockReviewItemRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockReviewItemRepository()
        viewModel = ReviewItemViewModel(repository: mockRepository)
    }
    
    func testLoadItems() {
        // Given
        let expectedItems = [ReviewItem.sample]
        mockRepository.items = expectedItems
        
        // When
        viewModel.loadItems()
        
        // Then
        XCTAssertEqual(viewModel.items, expectedItems)
        XCTAssertFalse(viewModel.isLoading)
    }
}
```

#### **Swift 6 现代化后**
```swift
@MainActor
class ReviewItemViewModelTests: XCTestCase {
    var viewModel: ReviewItemViewModel!
    var mockRepository: MockReviewItemRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockReviewItemRepository()
        viewModel = ReviewItemViewModel(repository: mockRepository)
    }
    
    func testLoadItems() async throws {
        // Given
        let expectedItems = [ReviewItem.sample]
        mockRepository.items = expectedItems
        
        // When
        await viewModel.loadItems()
        
        // Then
        XCTAssertEqual(viewModel.items, expectedItems)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testCreateItem() async throws {
        // Given
        let newItem = ReviewItem.sample
        
        // When
        await viewModel.createItem(newItem)
        
        // Then
        XCTAssertTrue(viewModel.items.contains(newItem))
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testConcurrentOperations() async throws {
        // Given
        let items = (0..<10).map { _ in ReviewItem.sample }
        
        // When
        await withTaskGroup(of: Void.self) { group in
            for item in items {
                group.addTask {
                    await self.viewModel.createItem(item)
                }
            }
        }
        
        // Then
        XCTAssertEqual(viewModel.items.count, items.count)
    }
}
```

### **2. 集成测试现代化**

#### **Swift 6 现代化后**
```swift
@MainActor
class CloudSyncIntegrationTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var syncService: CloudSyncService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建内存中的ModelContainer
        modelContainer = try ModelContainer(
            for: ReviewItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        modelContext = modelContainer.mainContext
        
        let repository = SwiftDataRepository(modelContext: modelContext)
        syncService = CloudSyncService(repository: repository)
    }
    
    func testSyncWithSwiftData() async throws {
        // Given
        let item = ReviewItem.sample
        modelContext.insert(item)
        try modelContext.save()
        
        // When
        try await syncService.syncAll()
        
        // Then
        let fetchedItems = try modelContext.fetch(FetchDescriptor<ReviewItem>())
        XCTAssertFalse(fetchedItems.isEmpty)
    }
    
    func testConcurrentSync() async throws {
        // Given
        let items = (0..<5).map { _ in ReviewItem.sample }
        for item in items {
            modelContext.insert(item)
        }
        try modelContext.save()
        
        // When
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<3 {
                group.addTask {
                    try? await self.syncService.syncAll()
                }
            }
        }
        
        // Then
        let fetchedItems = try modelContext.fetch(FetchDescriptor<ReviewItem>())
        XCTAssertEqual(fetchedItems.count, items.count)
    }
}
```

---

## 📊 性能基准测试

### **Swift 6 性能测试**
```swift
class PerformanceTests: XCTestCase {
    func testOCRPerformance() {
        measure {
            let expectation = XCTestExpectation(description: "OCR Performance")
            
            Task {
                let image = UIImage(systemName: "doc.text")!
                let ocrService = OCRService()
                
                do {
                    _ = try await ocrService.recognizeText(from: image)
                    expectation.fulfill()
                } catch {
                    XCTFail("OCR failed: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testConcurrentProcessing() {
        measure {
            let expectation = XCTestExpectation(description: "Concurrent Processing")
            expectation.expectedFulfillmentCount = 10
            
            Task {
                let images = (0..<10).map { _ in UIImage(systemName: "doc.text")! }
                let processor = BatchProcessor()
                
                do {
                    _ = try await processor.processImages(images)
                    expectation.fulfill()
                } catch {
                    XCTFail("Batch processing failed: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
}
```

---

## 🎯 现代化检查清单

### **并发安全**
- [ ] 关键服务改为Actor
- [ ] 使用async/await替代回调
- [ ] 添加Sendable协议
- [ ] 启用严格并发检查

### **类型安全**
- [ ] 改进错误处理
- [ ] 使用LocalizedError
- [ ] 添加恢复建议
- [ ] 类型安全的数据传输

### **性能优化**
- [ ] 并发处理优化
- [ ] 内存管理优化
- [ ] 缓存策略优化
- [ ] 网络请求优化

### **测试现代化**
- [ ] 单元测试更新
- [ ] 集成测试更新
- [ ] 性能测试添加
- [ ] 并发测试添加

### **文档更新**
- [ ] API文档更新
- [ ] 代码注释更新
- [ ] 用户指南更新
- [ ] 技术文档更新

---

**现代化目标**: 将NotBad错题本App全面现代化到Swift 6标准，获得更好的性能、类型安全和开发体验！

**预计工期**: 2-3周  
**风险等级**: 中等（可控）  
**收益等级**: 高（显著）  
**建议**: 分阶段实施，充分测试
