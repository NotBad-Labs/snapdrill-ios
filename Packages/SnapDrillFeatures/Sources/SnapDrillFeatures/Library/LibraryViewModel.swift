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
    
    public var items: [ReviewItemModel] = []
    public var subjects: [SubjectModel] = []
    public var allTags: [TagModel] = []
    
    public var searchText: String = ""
    public var selectedSubjects: Set<String> = []
    public var selectedTags: Set<String> = []
    
    public var isLoading: Bool = false
    
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
    
    public func loadDataAsync() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let items = try reviewRepo.fetchAll()
            try Task.checkCancellation()
            
            let subjects = try subjectRepo.fetchAll()
            try Task.checkCancellation()
            
            let tags = try tagRepo.fetchAll()
            try Task.checkCancellation()
            
            self.items = items
            self.subjects = subjects
            self.allTags = tags
        } catch is CancellationError {
            // Context changed, ignore
        } catch {
            SnapDrillLogger.generic.info("LibraryViewModel: Failed to load data: \(error)")
        }
    }
    
    /// 根据当前搜索文本和筛选条件过滤后的题目列表
    public var filteredItems: [ReviewItemModel] {
        items.filter { item in
            // Search text filter
            if !searchText.isEmpty {
                if !item.content.localizedCaseInsensitiveContains(searchText) {
                    return false
                }
            }
            
            // Subject filter
            if !selectedSubjects.isEmpty {
                if !selectedSubjects.contains(item.subject) {
                    return false
                }
            }
            
            // Tag filter
            if !selectedTags.isEmpty {
                guard let itemTags = item.tags else { return false }
                let itemTagNames = Set(itemTags.map { $0.name })
                if itemTagNames.isDisjoint(with: selectedTags) {
                    return false
                }
            }
            
            return true
        }
    }
    
    public func deleteItem(_ item: ReviewItemModel) {
        reviewRepo.delete(item)
        try? reviewRepo.save()
        // Refresh local data
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
        }
    }
    
    public func deleteItems(ids: Set<ReviewItemModel.ID>) {
        let itemsToDelete = items.filter { ids.contains($0.id) }
        for item in itemsToDelete {
            reviewRepo.delete(item)
        }
        try? reviewRepo.save()
        // Refresh local data
        items.removeAll { ids.contains($0.id) }
    }
    
    public func resetFilters() {
        selectedSubjects.removeAll()
        selectedTags.removeAll()
        searchText = ""
    }
}
