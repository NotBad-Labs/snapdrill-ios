import SwiftData
import Foundation

/// 版本化 Schema 定义 - V1
///
/// 包含初始版本的模型定义。
/// 当需要修改模型（如添加字段）时，应创建 SchemaV2，并将 V1 的旧模型代码快照保存到嵌套类型中。
public enum NotBadSchemaV1: VersionedSchema {
    public static let versionIdentifier: Schema.Version = .init(1, 0, 0)
    
    public static var models: [any PersistentModel.Type] {
        [
            ReviewItemModel.self,
            SubjectModel.self,
            TagModel.self
        ]
    }
    
    // Snapshot of V1 Model
    @Model
    public final class ReviewItemModel {
        @Attribute(.unique) public var id: UUID
        public var content: String
        public var imagePath: String?
        public var createdAt: Date
        public var lastReviewedAt: Date?
        public var nextReviewAt: Date?
        public var subjectRawValue: String
        public var sourceRawValue: String
        @Relationship(inverse: \TagModel.items)
        public var tags: [TagModel]? = []
        
        public init(
            id: UUID = UUID(),
            content: String,
            imagePath: String? = nil,
            createdAt: Date = Date(),
            lastReviewedAt: Date? = nil,
            nextReviewAt: Date? = nil,
            subject: String = "其他",
            source: String = "其他",
            tags: [TagModel] = []
        ) {
            self.id = id
            self.content = content
            self.imagePath = imagePath
            self.createdAt = createdAt
            self.lastReviewedAt = lastReviewedAt
            self.nextReviewAt = nextReviewAt
            self.subjectRawValue = subject
            self.sourceRawValue = source
            self.tags = tags
        }
    }
    
    @Model
    public final class SubjectModel {
        @Attribute(.unique) public var name: String
        public var colorHex: String
        public var iconName: String
        
        public init(name: String, colorHex: String, iconName: String) {
            self.name = name
            self.colorHex = colorHex
            self.iconName = iconName
        }
    }
    
    @Model
    public final class TagModel {
        @Attribute(.unique) public var name: String
        public var items: [ReviewItemModel]? = []
        
        public init(name: String) {
            self.name = name
        }
    }
}

public enum NotBadMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [
            NotBadSchemaV1.self,
            NotBadSchemaV2.self
        ]
    }
    
    public static var stages: [MigrationStage] {
        [
            migrateV1toV2
        ]
    }
    
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: NotBadSchemaV1.self,
        toVersion: NotBadSchemaV2.self
    )
}

// MARK: - Schema V2
/// 升级后的 Schema，包含答案和难度字段
public enum NotBadSchemaV2: VersionedSchema {
    public static let versionIdentifier: Schema.Version = .init(2, 0, 0)
    
    public static var models: [any PersistentModel.Type] {
        [
            ReviewItemModel.self, // Points to the new class in this package
            SubjectModel.self,
            TagModel.self
        ]
    }
}
