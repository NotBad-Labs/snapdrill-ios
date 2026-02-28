import Foundation
import SwiftData
import SnapDrillCore
import SnapDrillDomain

/// 学科数据仓库的 SwiftData 实现
@MainActor
public final class SubjectRepository: SubjectRepositoryProtocol {
    
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - SubjectRepositoryProtocol
    
    public func fetchAll() throws -> [Subject] {
        let descriptor = FetchDescriptor<SubjectModel>(sortBy: [SortDescriptor(\.sortOrder)])
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }
    
    public func fetchByName(_ name: String) throws -> Subject? {
        let targetName = name
        let predicate = #Predicate<SubjectModel> { $0.name == targetName }
        let descriptor = FetchDescriptor<SubjectModel>(predicate: predicate)
        return try modelContext.fetch(descriptor).first?.toEntity()
    }
    
    public func save(_ subject: Subject) throws {
        if let existing = try fetchModelById(subject.id) {
            updateModel(existing, from: subject)
        } else {
            // 检查名称唯一性
            let name = subject.name
            let namePredicate = #Predicate<SubjectModel> { $0.name == name }
            let descriptor = FetchDescriptor<SubjectModel>(predicate: namePredicate)
            if try modelContext.fetchCount(descriptor) > 0 {
                 throw DataError.duplicateName(name: name, entityType: "Subject")
            }
            
            let model = SubjectModel(
                id: subject.id,
                name: subject.name,
                icon: subject.icon,
                colorHex: subject.colorHex,
                sortOrder: subject.sortOrder
            )
            modelContext.insert(model)
        }
        try modelContext.save()
    }
    
    public func delete(id: UUID) throws {
        if let model = try fetchModelById(id) {
            modelContext.delete(model)
            try modelContext.save()
        }
    }
    
    public func totalCount() throws -> Int {
        let descriptor = FetchDescriptor<SubjectModel>()
        return try modelContext.fetchCount(descriptor)
    }
    
    public func initializeDefaultsIfNeeded() {
        do {
            if try totalCount() == 0 {
                let isChinese = Locale.current.language.languageCode?.identifier == "zh"
                // swiftlint:disable:next large_tuple
                let defaults: [(String, String, String)] = isChinese ? [
                    ("语文", "text.book.closed", "#E57373"),
                    ("数学", "function", "#4FC3F7"),
                    ("英语", "character.book.closed", "#AED581"),
                    ("物理", "atom", "#7986CB"),
                    ("化学", "flask", "#F06292"),
                    ("生物", "leaf", "#81C784"),
                    ("历史", "scroll", "#DCE775"),
                    ("地理", "globe.asia.australia", "#4DB6AC"),
                    ("政治", "building.columns", "#FFB74D")
                ] : [
                    ("Math", "function", "#4FC3F7"),
                    ("English", "character.book.closed", "#AED581"),
                    ("Physics", "atom", "#7986CB"),
                    ("Chemistry", "flask", "#F06292"),
                    ("Biology", "leaf", "#81C784"),
                    ("History", "scroll", "#DCE775"),
                    ("Geography", "globe.americas", "#4DB6AC"),
                    ("Art", "paintbrush", "#FFB74D")
                ]
                
                for (index, item) in defaults.enumerated() {
                    let model = SubjectModel(name: item.0, icon: item.1, colorHex: item.2, sortOrder: index)
                    modelContext.insert(model)
                }
                try modelContext.save()
            }
        } catch {
            SnapDrillLogger.generic.error("初始化默认学科失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Helpers
    
    private func fetchModelById(_ id: UUID) throws -> SubjectModel? {
        let targetId = id
        let predicate = #Predicate<SubjectModel> { $0.id == targetId }
        var descriptor = FetchDescriptor<SubjectModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
    
    private func updateModel(_ model: SubjectModel, from subject: Subject) {
        model.name = subject.name
        model.icon = subject.icon
        model.colorHex = subject.colorHex
        model.sortOrder = subject.sortOrder
    }
    
    public func deleteAll() throws {
        try modelContext.delete(model: SubjectModel.self)
        try modelContext.save()
    }
}
