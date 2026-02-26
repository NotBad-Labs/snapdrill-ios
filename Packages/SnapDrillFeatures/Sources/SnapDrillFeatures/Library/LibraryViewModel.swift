import SwiftUI
import Observation
import SnapDrillCore
import SnapDrillData

@Observable
@MainActor
public final class LibraryViewModel {
    
    // MARK: - Dependencies
    
    private let reviewRepo: ReviewRepositoryProtocol
    private let subjectRepo: SubjectRepositoryProtocol
    private let tagRepo: TagRepositoryProtocol
    
    // MARK: - State
    
    public var filteredItems: [ReviewItemModel] = []
    public var subjects: [SubjectModel] = []
    public var allTags: [TagModel] = []
    
    public var searchText: String = "" {
        didSet { triggerRefresh() }
    }
    public var selectedSubjects: Set<String> = [] {
        didSet { triggerRefresh() }
    }
    public var selectedTags: Set<String> = [] {
        didSet { triggerRefresh() }
    }
    
    public var isLoading: Bool = false
    private var currentPage: Int = 0
    private let pageSize: Int = 50
    @ObservationIgnored
    nonisolated(unsafe) private var searchTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    public init(
        reviewRepo: ReviewRepositoryProtocol,
        subjectRepo: SubjectRepositoryProtocol,
        tagRepo: TagRepositoryProtocol
    ) {
        self.reviewRepo = reviewRepo
        self.subjectRepo = subjectRepo
        self.tagRepo = tagRepo
    }
    
    // MARK: - Public API
    
    /// 加载基础元数据与初始数据
    public func loadDataAsync() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            self.subjects = try subjectRepo.fetchAll()
            self.allTags = try tagRepo.fetchAll()
            await refreshData()
        } catch {
            SnapDrillLogger.generic.info("LibraryViewModel: Failed to load meta data: \(error)")
        }
    }
    
    /// 触发防抖搜索/刷新
    public func triggerRefresh() {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            // Add a small debounce to avoid excessive DB hits during fast typing
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
            guard let self = self, !Task.isCancelled else { return }
            await self.refreshData()
        }
    }
    
    // MARK: - Public API
    
    /// 执行数据加载与过滤 (异步)
    public func refreshData() async {
        do {
            currentPage = 0
            let results = try reviewRepo.fetchFiltered(
                searchText: searchText,
                subjects: selectedSubjects,
                tags: selectedTags,
                limit: pageSize,
                offset: 0
            )
            
            guard !Task.isCancelled else { return }
            self.filteredItems = results
        } catch {
            SnapDrillLogger.generic.error("LibraryViewModel: Refresh failed: \(error)")
        }
    }
    
    public func loadMore() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            currentPage += 1
            let nextItems = try reviewRepo.fetchFiltered(
                searchText: searchText,
                subjects: selectedSubjects,
                tags: selectedTags,
                limit: pageSize,
                offset: currentPage * pageSize
            )
            
            guard !Task.isCancelled else { return }
            self.filteredItems.append(contentsOf: nextItems)
        } catch {
            SnapDrillLogger.generic.error("LibraryViewModel: Load more failed: \(error)")
        }
    }
    
    public func deleteItem(_ item: ReviewItemModel) {
        reviewRepo.delete(item)
        try? reviewRepo.save()
        filteredItems.removeAll { $0.id == item.id }
    }
    
    public func deleteItems(ids: Set<ReviewItemModel.ID>) {
        // 先获取这些模型
        do {
            let itemsToDelete = try reviewRepo.fetchByIds(ids)
            for item in itemsToDelete {
                reviewRepo.delete(item)
            }
            try reviewRepo.save()
            filteredItems.removeAll { ids.contains($0.id) }
        } catch {
            SnapDrillLogger.generic.error("LibraryViewModel: Delete failed: \(error)")
        }
    }
    
    public func resetFilters() {
        searchText = ""
        selectedSubjects.removeAll()
        selectedTags.removeAll()
    }
    
    deinit {
        searchTask?.cancel()
    }
}
