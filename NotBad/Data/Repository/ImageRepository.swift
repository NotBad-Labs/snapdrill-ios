//
//  ImageRepository.swift
//  NotBad
//
//  图片仓库实现 - SwiftData 存储
//

import Foundation
import SwiftData
import OSLog

// MARK: - ImageRepository

/// 图片仓库实现
///
/// 使用 SwiftData 存储图片数据，支持按需加载。
/// 图片数据存储在独立的 `ReviewItemImageModel` 中。
@MainActor
final class ImageRepository: ImageRepositoryProtocol {
    
    // MARK: - Properties
    
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = modelContainer.mainContext
    }
    
    // MARK: - Load Operations
    
    func loadImage(for reviewItemId: UUID) -> Data? {
        guard let model = fetchImageModel(for: reviewItemId) else {
            return nil
        }
        return model.imageData
    }
    
    func hasImage(for reviewItemId: UUID) -> Bool {
        fetchImageModel(for: reviewItemId) != nil
    }
    
    // MARK: - Save Operations
    
    func saveImage(_ imageData: Data, for reviewItemId: UUID) throws {
        // 检查是否已存在
        if fetchImageModel(for: reviewItemId) != nil {
            // 已存在，更新
            try updateImage(imageData, for: reviewItemId)
            return
        }
        
        // 创建新的图片模型
        let imageModel = ReviewItemImageModel(
            reviewItemId: reviewItemId,
            imageData: imageData
        )
        modelContext.insert(imageModel)
        try modelContext.save()
        
        Logger.data.debug("Saved image for review item: \(reviewItemId)")
    }
    
    func updateImage(_ imageData: Data, for reviewItemId: UUID) throws {
        guard let model = fetchImageModel(for: reviewItemId) else {
            // 不存在，创建新的
            try saveImage(imageData, for: reviewItemId)
            return
        }
        
        model.imageData = imageData
        try modelContext.save()
        
        Logger.data.debug("Updated image for review item: \(reviewItemId)")
    }
    
    // MARK: - Delete Operations
    
    func deleteImage(for reviewItemId: UUID) throws {
        guard let model = fetchImageModel(for: reviewItemId) else {
            return // 不存在，无需删除
        }
        
        modelContext.delete(model)
        try modelContext.save()
        
        Logger.data.debug("Deleted image for review item: \(reviewItemId)")
    }
    
    func deleteImages(for reviewItemIds: [UUID]) throws {
        for id in reviewItemIds {
            if let model = fetchImageModel(for: id) {
                modelContext.delete(model)
            }
        }
        try modelContext.save()
        
        Logger.data.debug("Deleted \(reviewItemIds.count) images")
    }
    
    // MARK: - Private Helpers
    
    private func fetchImageModel(for reviewItemId: UUID) -> ReviewItemImageModel? {
        let descriptor = FetchDescriptor<ReviewItemImageModel>(
            predicate: #Predicate<ReviewItemImageModel> { model in
                model.reviewItemId == reviewItemId
            }
        )
        
        do {
            let models = try modelContext.fetch(descriptor)
            return models.first
        } catch {
            Logger.data.error("Failed to fetch image model: \(error.localizedDescription)")
            return nil
        }
    }
}
