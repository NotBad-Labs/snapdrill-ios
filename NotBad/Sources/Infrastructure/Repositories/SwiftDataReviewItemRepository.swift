//
//  SwiftDataReviewItemRepository.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//

import Foundation
import SwiftData

// MARK: - SwiftData Models

@Model
final class ReviewItemModel {
    @Attribute(.unique) var id: UUID
    var title: String
    var question: String
    var answer: String?
    var explanation: String?
    var imageData: Data?
    var subject: String
    var difficulty: String
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
    var ownerId: UUID
    var parentShareStatus: String
    var parentAccessRevokedAt: Date?
    var sharedWithClassIds: [UUID]
    var source: String
    var masteryLevel: String
    
    @Relationship(deleteRule: .cascade, inverse: \StudyRecordModel.reviewItem)
    var studyRecords: [StudyRecordModel] = []
    
    init(
        id: UUID = UUID(),
        title: String,
        question: String,
        answer: String? = nil,
        explanation: String? = nil,
        imageData: Data? = nil,
        subject: String,
        difficulty: String = "medium",
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        ownerId: UUID,
        parentShareStatus: String = "none",
        parentAccessRevokedAt: Date? = nil,
        sharedWithClassIds: [UUID] = [],
        source: String = "manual",
        masteryLevel: String = "not_mastered"
    ) {
        self.id = id
        self.title = title
        self.question = question
        self.answer = answer
        self.explanation = explanation
        self.imageData = imageData
        self.subject = subject
        self.difficulty = difficulty
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ownerId = ownerId
        self.parentShareStatus = parentShareStatus
        self.parentAccessRevokedAt = parentAccessRevokedAt
        self.sharedWithClassIds = sharedWithClassIds
        self.source = source
        self.masteryLevel = masteryLevel
    }
}

@Model
final class StudyRecordModel {
    @Attribute(.unique) var id: UUID
    var studyDate: Date
    var isCorrect: Bool
    var timeSpent: TimeInterval
    var notes: String?
    
    var reviewItem: ReviewItemModel?
    
    init(
        id: UUID = UUID(),
        studyDate: Date = Date(),
        isCorrect: Bool,
        timeSpent: TimeInterval,
        notes: String? = nil
    ) {
        self.id = id
        self.studyDate = studyDate
        self.isCorrect = isCorrect
        self.timeSpent = timeSpent
        self.notes = notes
    }
}

// MARK: - Repository Implementation

class SwiftDataReviewItemRepository: ReviewItemRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - CRUD Operations
    
    func create(_ item: ReviewItem) async throws -> ReviewItem {
        let model = item.toModel()
        modelContext.insert(model)
        
        do {
            try modelContext.save()
            return model.toDomain()
        } catch {
            throw ReviewItemRepositoryError.storageError("创建失败: \(error.localizedDescription)")
        }
    }
    
    func getById(_ id: UUID) async throws -> ReviewItem? {
        let predicate = #Predicate<ReviewItemModel> { model in
            model.id == id
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        do {
            let models = try modelContext.fetch(descriptor)
            return models.first?.toDomain()
        } catch {
            throw ReviewItemRepositoryError.storageError("查询失败: \(error.localizedDescription)")
        }
    }
    
    func getAll() async throws -> [ReviewItem] {
        let descriptor = FetchDescriptor<ReviewItemModel>()
        
        do {
            let models = try modelContext.fetch(descriptor)
            return models.map { $0.toDomain() }
        } catch {
            throw ReviewItemRepositoryError.storageError("查询失败: \(error.localizedDescription)")
        }
    }
    
    func update(_ item: ReviewItem) async throws -> ReviewItem {
        guard try await getById(item.id) != nil else {
            throw ReviewItemRepositoryError.itemNotFound(item.id)
        }
        
        let predicate = #Predicate<ReviewItemModel> { model in
            model.id == item.id
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        do {
            let models = try modelContext.fetch(descriptor)
            guard let model = models.first else {
                throw ReviewItemRepositoryError.itemNotFound(item.id)
            }
            
            // 更新模型
            model.title = item.content.title
            model.question = item.content.question
            model.answer = item.content.answer
            model.explanation = item.content.explanation
            model.imageData = item.content.imageData
            model.subject = item.content.subject
            model.difficulty = item.content.difficulty.rawValue
            model.tags = item.content.tags
            model.updatedAt = Date()
            model.masteryLevel = item.masteryLevel.rawValue
            
            try modelContext.save()
            return model.toDomain()
        } catch {
            throw ReviewItemRepositoryError.storageError("更新失败: \(error.localizedDescription)")
        }
    }
    
    func delete(_ id: UUID) async throws {
        let predicate = #Predicate<ReviewItemModel> { model in
            model.id == id
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        do {
            let models = try modelContext.fetch(descriptor)
            guard let model = models.first else {
                throw ReviewItemRepositoryError.itemNotFound(id)
            }
            
            modelContext.delete(model)
            try modelContext.save()
        } catch {
            throw ReviewItemRepositoryError.storageError("删除失败: \(error.localizedDescription)")
        }
    }
    
    func deleteBatch(_ ids: [UUID]) async throws {
        for id in ids {
            try await delete(id)
        }
    }
    
    // MARK: - Query Operations
    
    func getByOwner(_ ownerId: UUID) async throws -> [ReviewItem] {
        let predicate = #Predicate<ReviewItemModel> { model in
            model.ownerId == ownerId
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        do {
            let models = try modelContext.fetch(descriptor)
            return models.map { $0.toDomain() }
        } catch {
            throw ReviewItemRepositoryError.storageError("查询失败: \(error.localizedDescription)")
        }
    }
    
    func getBySubject(_ subject: String) async throws -> [ReviewItem] {
        let predicate = #Predicate<ReviewItemModel> { model in
            model.subject == subject
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        do {
            let models = try modelContext.fetch(descriptor)
            return models.map { $0.toDomain() }
        } catch {
            throw ReviewItemRepositoryError.storageError("查询失败: \(error.localizedDescription)")
        }
    }
    
    func getByMasteryLevel(_ masteryLevel: MasteryLevel) async throws -> [ReviewItem] {
        let predicate = #Predicate<ReviewItemModel> { model in
            model.masteryLevel == masteryLevel.rawValue
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        do {
            let models = try modelContext.fetch(descriptor)
            return models.map { $0.toDomain() }
        } catch {
            throw ReviewItemRepositoryError.storageError("查询失败: \(error.localizedDescription)")
        }
    }
    
    func getByDifficulty(_ difficulty: DifficultyLevel) async throws -> [ReviewItem] {
        let predicate = #Predicate<ReviewItemModel> { model in
            model.difficulty == difficulty.rawValue
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        do {
            let models = try modelContext.fetch(descriptor)
            return models.map { $0.toDomain() }
        } catch {
            throw ReviewItemRepositoryError.storageError("查询失败: \(error.localizedDescription)")
        }
    }
    
    func getByTags(_ tags: [String]) async throws -> [ReviewItem] {
        // 简化实现：查找包含任一标签的项目
        let descriptor = FetchDescriptor<ReviewItemModel>()
        
        do {
            let models = try modelContext.fetch(descriptor)
            let filtered = models.filter { model in
                return tags.contains { tag in
                    model.tags.contains(tag)
                }
            }
            return filtered.map { $0.toDomain() }
        } catch {
            throw ReviewItemRepositoryError.storageError("查询失败: \(error.localizedDescription)")
        }
    }
    
    func getByDateRange(_ dateRange: DateRange) async throws -> [ReviewItem] {
        let predicate = #Predicate<ReviewItemModel> { model in
            model.createdAt >= dateRange.startDate && model.createdAt <= dateRange.endDate
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        do {
            let models = try modelContext.fetch(descriptor)
            return models.map { $0.toDomain() }
        } catch {
            throw ReviewItemRepositoryError.storageError("查询失败: \(error.localizedDescription)")
        }
    }
    
    func search(_ query: String) async throws -> [ReviewItem] {
        let descriptor = FetchDescriptor<ReviewItemModel>()
        
        do {
            let models = try modelContext.fetch(descriptor)
            let filtered = models.filter { model in
                model.title.localizedCaseInsensitiveContains(query) ||
                model.question.localizedCaseInsensitiveContains(query) ||
                (model.answer?.localizedCaseInsensitiveContains(query) ?? false)
            }
            return filtered.map { $0.toDomain() }
        } catch {
            throw ReviewItemRepositoryError.storageError("搜索失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Study Record Operations
    
    func addStudyRecord(itemId: UUID, record: StudyRecord) async throws -> ReviewItem {
        let predicate = #Predicate<ReviewItemModel> { model in
            model.id == itemId
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        do {
            let models = try modelContext.fetch(descriptor)
            guard let model = models.first else {
                throw ReviewItemRepositoryError.itemNotFound(itemId)
            }
            
            let recordModel = StudyRecordModel(
                id: record.id,
                studyDate: record.studyDate,
                isCorrect: record.isCorrect,
                timeSpent: record.timeSpent,
                notes: record.notes
            )
            recordModel.reviewItem = model
            
            modelContext.insert(recordModel)
            try modelContext.save()
            
            return model.toDomain()
        } catch {
            throw ReviewItemRepositoryError.storageError("添加学习记录失败: \(error.localizedDescription)")
        }
    }
    
    func updateMasteryLevel(itemId: UUID, masteryLevel: MasteryLevel) async throws -> ReviewItem {
        let predicate = #Predicate<ReviewItemModel> { model in
            model.id == itemId
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        do {
            let models = try modelContext.fetch(descriptor)
            guard let model = models.first else {
                throw ReviewItemRepositoryError.itemNotFound(itemId)
            }
            
            model.masteryLevel = masteryLevel.rawValue
            model.updatedAt = Date()
            
            try modelContext.save()
            return model.toDomain()
        } catch {
            throw ReviewItemRepositoryError.storageError("更新掌握程度失败: \(error.localizedDescription)")
        }
    }
    
    func getStudyHistory(itemId: UUID) async throws -> [StudyRecord] {
        let predicate = #Predicate<StudyRecordModel> { record in
            record.reviewItem?.id == itemId
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        do {
            let recordModels = try modelContext.fetch(descriptor)
            return recordModels.map { $0.toDomain() }
        } catch {
            throw ReviewItemRepositoryError.storageError("查询学习历史失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Statistics Operations
    
    func getStatistics(ownerId: UUID?) async throws -> ReviewItemStatistics {
        let descriptor = FetchDescriptor<ReviewItemModel>()
        
        do {
            let models = try modelContext.fetch(descriptor)
            let filteredModels = ownerId != nil ? models.filter { $0.ownerId == ownerId } : models
            
            let total = filteredModels.count
            let mastered = filteredModels.filter { $0.masteryLevel == MasteryLevel.mastered.rawValue }.count
            let unclear = filteredModels.filter { $0.masteryLevel == MasteryLevel.unclear.rawValue }.count
            let notMastered = filteredModels.filter { $0.masteryLevel == MasteryLevel.notMastered.rawValue }.count
            
            return ReviewItemStatistics(
                totalCount: total,
                masteryLevelCounts: [
                    .mastered: mastered,
                    .unclear: unclear,
                    .notMastered: notMastered
                ],
                difficultyLevelCounts: [:],  // TODO: 实现难度统计
                subjectCounts: [:]  // TODO: 实现科目统计
            )
        } catch {
            throw ReviewItemRepositoryError.storageError("获取统计信息失败: \(error.localizedDescription)")
        }
    }
    
    func getSubjectStatistics(ownerId: UUID?) async throws -> [String: Int] {
        let descriptor = FetchDescriptor<ReviewItemModel>()
        
        do {
            let models = try modelContext.fetch(descriptor)
            let filteredModels = ownerId != nil ? models.filter { $0.ownerId == ownerId } : models
            
            var subjectCounts: [String: Int] = [:]
            for model in filteredModels {
                subjectCounts[model.subject, default: 0] += 1
            }
            
            return subjectCounts
        } catch {
            throw ReviewItemRepositoryError.storageError("获取科目统计失败: \(error.localizedDescription)")
        }
    }
    
    func getMasteryStatistics(ownerId: UUID?) async throws -> [MasteryLevel: Int] {
        let descriptor = FetchDescriptor<ReviewItemModel>()
        
        do {
            let models = try modelContext.fetch(descriptor)
            let filteredModels = ownerId != nil ? models.filter { $0.ownerId == ownerId } : models
            
            var masteryCounts: [MasteryLevel: Int] = [:]
            for model in filteredModels {
                if let masteryLevel = MasteryLevel(rawValue: model.masteryLevel) {
                    masteryCounts[masteryLevel, default: 0] += 1
                }
            }
            
            return masteryCounts
        } catch {
            throw ReviewItemRepositoryError.storageError("获取掌握程度统计失败: \(error.localizedDescription)")
        }
    }
}

// MARK: - Model Extensions

extension ReviewItemModel {
    func toDomain() -> ReviewItem {
        let content = ReviewContent(
            title: title,
            question: question,
            answer: answer,
            explanation: explanation,
            imageData: imageData,
            subject: subject,
            difficulty: DifficultyLevel(rawValue: difficulty) ?? .medium,
            tags: tags
        )
        
        let metadata = ReviewMetadata(
            createdAt: createdAt,
            updatedAt: updatedAt,
            ownerId: ownerId,
            parentShareStatus: ParentShareStatus(rawValue: parentShareStatus) ?? .none,
            parentAccessRevokedAt: parentAccessRevokedAt,
            sharedWithClassIds: sharedWithClassIds,
            source: ItemSource(rawValue: source) ?? .manual
        )
        
        let domainStudyRecords = studyRecords.map { $0.toDomain() }
        let domainMasteryLevel = MasteryLevel(rawValue: masteryLevel) ?? .notMastered
        
        return ReviewItem(
            id: id,
            content: content,
            metadata: metadata,
            studyHistory: domainStudyRecords,
            masteryLevel: domainMasteryLevel
        )
    }
}

extension StudyRecordModel {
    func toDomain() -> StudyRecord {
        return StudyRecord(
            id: id,
            studyDate: studyDate,
            isCorrect: isCorrect,
            timeSpent: timeSpent,
            notes: notes
        )
    }
}

extension ReviewItem {
    func toModel() -> ReviewItemModel {
        return ReviewItemModel(
            id: id,
            title: content.title,
            question: content.question,
            answer: content.answer,
            explanation: content.explanation,
            imageData: content.imageData,
            subject: content.subject,
            difficulty: content.difficulty.rawValue,
            tags: content.tags,
            createdAt: metadata.createdAt,
            updatedAt: metadata.updatedAt,
            ownerId: metadata.ownerId,
            parentShareStatus: metadata.parentShareStatus.rawValue,
            parentAccessRevokedAt: metadata.parentAccessRevokedAt,
            sharedWithClassIds: metadata.sharedWithClassIds,
            source: metadata.source.rawValue,
            masteryLevel: masteryLevel.rawValue
        )
    }
}

