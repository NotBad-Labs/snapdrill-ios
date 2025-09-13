import Foundation
import SwiftData
import SwiftUI

/// SwiftData ReviewItem仓库实现
@MainActor
class SwiftDataReviewItemRepository: ReviewItemRepository {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    init() throws {
        let schema = Schema([
            ReviewItem.self,
            ReviewContent.self,
            ReviewItemMetadata.self,
            StudyRecord.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        self.modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        self.modelContext = ModelContext(modelContainer)
    }
    
    nonisolated func createReviewItem(_ content: ReviewContent, metadata: ReviewItemMetadata) async throws -> ReviewItem {
        let reviewItem = ReviewItem(content: content, metadata: metadata)
        
        return try await MainActor.run {
            modelContext.insert(reviewItem)
            do {
                try modelContext.save()
                return reviewItem
            } catch {
                throw RepositoryError.saveFailed(error)
            }
        }
    }
    
    nonisolated func getReviewItems(predicate: Predicate<ReviewItem>?, sortBy: [SortDescriptor<ReviewItem>]) async throws -> [ReviewItem] {
        let descriptor = FetchDescriptor<ReviewItem>(
            predicate: predicate,
            sortBy: sortBy
        )
        
        return try await MainActor.run {
            do {
                return try modelContext.fetch(descriptor)
            } catch {
                throw RepositoryError.fetchFailed(error)
            }
        }
    }
    
    nonisolated func updateReviewItem(_ item: ReviewItem) async throws {
        try await MainActor.run {
            item.updatedAt = Date()
            
            do {
                try modelContext.save()
            } catch {
                throw RepositoryError.updateFailed(error)
            }
        }
    }
    
    nonisolated func deleteReviewItem(id: UUID) async throws {
        let predicate = #Predicate<ReviewItem> { $0.id == id }
        let descriptor = FetchDescriptor<ReviewItem>(predicate: predicate)
        
        try await MainActor.run {
            do {
                let items = try modelContext.fetch(descriptor)
                for item in items {
                    modelContext.delete(item)
                }
                try modelContext.save()
            } catch {
                throw RepositoryError.deleteFailed(error)
            }
        }
    }
    
    nonisolated func getReviewItem(id: UUID) async throws -> ReviewItem? {
        let predicate = #Predicate<ReviewItem> { $0.id == id }
        let descriptor = FetchDescriptor<ReviewItem>(predicate: predicate)
        
        return try await MainActor.run {
            do {
                let items = try modelContext.fetch(descriptor)
                return items.first
            } catch {
                throw RepositoryError.fetchFailed(error)
            }
        }
    }
}

// MARK: - 错误定义

enum RepositoryError: LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "保存失败: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "获取失败: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "更新失败: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "删除失败: \(error.localizedDescription)"
        }
    }
}
