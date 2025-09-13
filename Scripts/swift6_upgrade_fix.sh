#!/bin/bash

# Swift 6 升级修复脚本
# 修复项目中的Swift 6兼容性问题和警告

set -e

echo "🚀 开始Swift 6升级修复..."

# 1. 更新项目配置
echo "📝 更新项目配置..."

# 更新Swift版本到6.0
sed -i '' 's/SWIFT_VERSION = 5.0;/SWIFT_VERSION = 6.0;/g' NotBad.xcodeproj/project.pbxproj

# 更新部署目标到18.0
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 17.0;/IPHONEOS_DEPLOYMENT_TARGET = 18.0;/g' NotBad.xcodeproj/project.pbxproj

echo "✅ 项目配置更新完成"

# 2. 创建Swift 6兼容性修复
echo "🔧 创建Swift 6兼容性修复..."

# 创建Sendable协议扩展
cat > NotBad/Sources/Domain/Extensions/SendableExtensions.swift << 'EOF'
//
//  SendableExtensions.swift
//  NotBad
//
//  Created by Swift 6 Upgrade Script on 2025/9/13.
//

import Foundation

// MARK: - Sendable协议扩展
// 为Swift 6并发安全提供Sendable协议支持

extension ReviewItem: Sendable {}
extension ReviewContent: Sendable {}
extension ReviewMetadata: Sendable {}
extension StudyRecord: Sendable {}
extension MasteryLevel: Sendable {}
extension DifficultyLevel: Sendable {}
extension ParentShareStatus: Sendable {}
extension ItemSource: Sendable {}

// MARK: - 日期范围结构体
struct DateRange: Sendable {
    let startDate: Date
    let endDate: Date
    
    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
}

// MARK: - 统计信息结构体
struct ReviewItemStatistics: Sendable {
    let totalCount: Int
    let masteryLevelCounts: [MasteryLevel: Int]
    let difficultyLevelCounts: [DifficultyLevel: Int]
    let subjectCounts: [String: Int]
}
EOF

# 创建请求/响应结构体
cat > NotBad/Sources/Domain/DataTypes/RequestResponseTypes.swift << 'EOF'
//
//  RequestResponseTypes.swift
//  NotBad
//
//  Created by Swift 6 Upgrade Script on 2025/9/13.
//

import Foundation

// MARK: - 请求/响应类型定义
// 为Swift 6并发安全提供Sendable协议支持

// MARK: - 创建复习项请求/响应
struct CreateReviewItemRequest: Sendable {
    let content: ReviewContent
    let metadata: ReviewMetadata
    let ownerId: UUID
}

struct CreateReviewItemResponse: Sendable {
    let reviewItem: ReviewItem
    let success: Bool
    let message: String?
}

// MARK: - 获取复习项请求/响应
struct GetReviewItemsRequest: Sendable {
    let ownerId: UUID?
    let subject: String?
    let masteryLevel: MasteryLevel?
    let difficulty: DifficultyLevel?
    let tags: [String]?
    let dateRange: DateRange?
    let searchQuery: String?
    let limit: Int?
    let offset: Int?
}

struct GetReviewItemsResponse: Sendable {
    let reviewItems: [ReviewItem]
    let totalCount: Int
    let hasMore: Bool
}

// MARK: - 更新复习项请求/响应
struct UpdateReviewItemRequest: Sendable {
    let id: UUID
    let content: ReviewContent?
    let metadata: ReviewMetadata?
    let masteryLevel: MasteryLevel?
}

struct UpdateReviewItemResponse: Sendable {
    let reviewItem: ReviewItem
    let success: Bool
    let message: String?
}

// MARK: - 删除复习项请求/响应
struct DeleteReviewItemRequest: Sendable {
    let id: UUID
}

struct DeleteReviewItemResponse: Sendable {
    let success: Bool
    let message: String?
}

// MARK: - 添加学习记录请求/响应
struct AddStudyRecordRequest: Sendable {
    let itemId: UUID
    let record: StudyRecord
}

struct AddStudyRecordResponse: Sendable {
    let reviewItem: ReviewItem
    let success: Bool
    let message: String?
}

// MARK: - 更新掌握程度请求/响应
struct UpdateMasteryLevelRequest: Sendable {
    let itemId: UUID
    let masteryLevel: MasteryLevel
}

struct UpdateMasteryLevelResponse: Sendable {
    let reviewItem: ReviewItem
    let success: Bool
    let message: String?
}

// MARK: - 搜索复习项请求/响应
struct SearchReviewItemsRequest: Sendable {
    let query: String
    let ownerId: UUID?
    let subject: String?
    let limit: Int?
}

struct SearchReviewItemsResponse: Sendable {
    let reviewItems: [ReviewItem]
    let totalCount: Int
}

// MARK: - 获取统计信息请求/响应
struct GetStatisticsRequest: Sendable {
    let ownerId: UUID?
    let dateRange: DateRange?
}

struct GetStatisticsResponse: Sendable {
    let statistics: ReviewItemStatistics
    let subjectStatistics: [String: Int]
    let masteryStatistics: [MasteryLevel: Int]
}

// MARK: - 批量操作请求/响应
struct CreateReviewItemsBatchRequest: Sendable {
    let items: [CreateReviewItemRequest]
}

struct CreateReviewItemsBatchResponse: Sendable {
    let reviewItems: [ReviewItem]
    let successCount: Int
    let failureCount: Int
    let errors: [String]
}

struct UpdateReviewItemsBatchRequest: Sendable {
    let updates: [UpdateReviewItemRequest]
}

struct UpdateReviewItemsBatchResponse: Sendable {
    let reviewItems: [ReviewItem]
    let successCount: Int
    let failureCount: Int
    let errors: [String]
}

struct DeleteReviewItemsBatchRequest: Sendable {
    let ids: [UUID]
}

struct DeleteReviewItemsBatchResponse: Sendable {
    let successCount: Int
    let failureCount: Int
    let errors: [String]
}
EOF

echo "✅ Swift 6兼容性修复创建完成"

# 3. 更新现有文件以支持Swift 6
echo "🔄 更新现有文件..."

# 更新ReviewItem.swift以支持Sendable
sed -i '' 's/public struct ReviewItem: Identifiable, Equatable, Hashable, Codable {/public struct ReviewItem: Identifiable, Equatable, Hashable, Codable, Sendable {/' NotBad/Sources/Domain/Entities/ReviewItem.swift

sed -i '' 's/struct ReviewContent: Equatable, Hashable, Codable {/struct ReviewContent: Equatable, Hashable, Codable, Sendable {/' NotBad/Sources/Domain/Entities/ReviewItem.swift

sed -i '' 's/struct ReviewMetadata: Equatable, Hashable, Codable {/struct ReviewMetadata: Equatable, Hashable, Codable, Sendable {/' NotBad/Sources/Domain/Entities/ReviewItem.swift

sed -i '' 's/struct StudyRecord: Identifiable, Equatable, Hashable, Codable {/struct StudyRecord: Identifiable, Equatable, Hashable, Codable, Sendable {/' NotBad/Sources/Domain/Entities/ReviewItem.swift

sed -i '' 's/public enum MasteryLevel: String, CaseIterable, Equatable, Hashable, Codable {/public enum MasteryLevel: String, CaseIterable, Equatable, Hashable, Codable, Sendable {/' NotBad/Sources/Domain/Entities/ReviewItem.swift

sed -i '' 's/public enum DifficultyLevel: String, CaseIterable, Equatable, Hashable, Codable {/public enum DifficultyLevel: String, CaseIterable, Equatable, Hashable, Codable, Sendable {/' NotBad/Sources/Domain/Entities/ReviewItem.swift

sed -i '' 's/public enum ParentShareStatus: String, CaseIterable, Equatable, Hashable, Codable {/public enum ParentShareStatus: String, CaseIterable, Equatable, Hashable, Codable, Sendable {/' NotBad/Sources/Domain/Entities/ReviewItem.swift

sed -i '' 's/enum ItemSource: String, CaseIterable, Equatable, Hashable, Codable {/enum ItemSource: String, CaseIterable, Equatable, Hashable, Codable, Sendable {/' NotBad/Sources/Domain/Entities/ReviewItem.swift

echo "✅ 现有文件更新完成"

# 4. 创建Swift 6 Actor服务
echo "🎭 创建Swift 6 Actor服务..."

cat > NotBad/Sources/Application/Actors/ReviewItemActor.swift << 'EOF'
//
//  ReviewItemActor.swift
//  NotBad
//
//  Created by Swift 6 Upgrade Script on 2025/9/13.
//

import Foundation

// MARK: - Swift 6 Actor服务
// 使用Swift 6 Actor模型确保并发安全

@MainActor
actor ReviewItemActor {
    private let repository: ReviewItemRepository
    
    init(repository: ReviewItemRepository) {
        self.repository = repository
    }
    
    // MARK: - 并发安全的方法
    
    func createReviewItem(_ request: CreateReviewItemRequest) async throws -> CreateReviewItemResponse {
        let reviewItem = ReviewItem(
            content: request.content,
            metadata: request.metadata,
            masteryLevel: .notMastered
        )
        
        let createdItem = try await repository.create(reviewItem)
        return CreateReviewItemResponse(
            reviewItem: createdItem,
            success: true,
            message: "复习项创建成功"
        )
    }
    
    func getReviewItems(_ request: GetReviewItemsRequest) async throws -> GetReviewItemsResponse {
        var items: [ReviewItem] = []
        
        if let ownerId = request.ownerId {
            items = try await repository.getByOwner(ownerId)
        } else {
            items = try await repository.getAll()
        }
        
        // 应用过滤条件
        if let subject = request.subject {
            items = items.filter { $0.content.subject == subject }
        }
        
        if let masteryLevel = request.masteryLevel {
            items = items.filter { $0.masteryLevel == masteryLevel }
        }
        
        if let difficulty = request.difficulty {
            items = items.filter { $0.content.difficulty == difficulty }
        }
        
        if let tags = request.tags, !tags.isEmpty {
            items = items.filter { item in
                tags.contains { tag in
                    item.content.tags.contains(tag)
                }
            }
        }
        
        if let dateRange = request.dateRange {
            items = items.filter { item in
                item.metadata.createdAt >= dateRange.startDate && 
                item.metadata.createdAt <= dateRange.endDate
            }
        }
        
        if let searchQuery = request.searchQuery, !searchQuery.isEmpty {
            items = items.filter { item in
                item.content.title.localizedCaseInsensitiveContains(searchQuery) ||
                item.content.question.localizedCaseInsensitiveContains(searchQuery) ||
                (item.content.answer?.localizedCaseInsensitiveContains(searchQuery) ?? false)
            }
        }
        
        // 应用分页
        let totalCount = items.count
        let limit = request.limit ?? 50
        let offset = request.offset ?? 0
        let startIndex = min(offset, items.count)
        let endIndex = min(startIndex + limit, items.count)
        
        if startIndex < items.count {
            items = Array(items[startIndex..<endIndex])
        } else {
            items = []
        }
        
        return GetReviewItemsResponse(
            reviewItems: items,
            totalCount: totalCount,
            hasMore: endIndex < totalCount
        )
    }
    
    func updateReviewItem(_ request: UpdateReviewItemRequest) async throws -> UpdateReviewItemResponse {
        guard var existingItem = try await repository.getById(request.id) else {
            throw ReviewItemRepositoryError.itemNotFound(request.id)
        }
        
        // 更新内容
        if let content = request.content {
            existingItem.content = content
        }
        
        // 更新元数据
        if let metadata = request.metadata {
            existingItem.metadata = metadata
        }
        
        // 更新掌握程度
        if let masteryLevel = request.masteryLevel {
            existingItem.masteryLevel = masteryLevel
        }
        
        let updatedItem = try await repository.update(existingItem)
        return UpdateReviewItemResponse(
            reviewItem: updatedItem,
            success: true,
            message: "复习项更新成功"
        )
    }
    
    func deleteReviewItem(_ request: DeleteReviewItemRequest) async throws -> DeleteReviewItemResponse {
        try await repository.delete(request.id)
        return DeleteReviewItemResponse(
            success: true,
            message: "复习项删除成功"
        )
    }
    
    func addStudyRecord(_ request: AddStudyRecordRequest) async throws -> AddStudyRecordResponse {
        let updatedItem = try await repository.addStudyRecord(
            itemId: request.itemId,
            record: request.record
        )
        return AddStudyRecordResponse(
            reviewItem: updatedItem,
            success: true,
            message: "学习记录添加成功"
        )
    }
    
    func updateMasteryLevel(_ request: UpdateMasteryLevelRequest) async throws -> UpdateMasteryLevelResponse {
        let updatedItem = try await repository.updateMasteryLevel(
            itemId: request.itemId,
            masteryLevel: request.masteryLevel
        )
        return UpdateMasteryLevelResponse(
            reviewItem: updatedItem,
            success: true,
            message: "掌握程度更新成功"
        )
    }
    
    func searchReviewItems(_ request: SearchReviewItemsRequest) async throws -> SearchReviewItemsResponse {
        let items = try await repository.search(request.query)
        
        // 应用额外过滤
        var filteredItems = items
        if let ownerId = request.ownerId {
            filteredItems = filteredItems.filter { $0.metadata.ownerId == ownerId }
        }
        if let subject = request.subject {
            filteredItems = filteredItems.filter { $0.content.subject == subject }
        }
        
        // 应用限制
        if let limit = request.limit {
            filteredItems = Array(filteredItems.prefix(limit))
        }
        
        return SearchReviewItemsResponse(
            reviewItems: filteredItems,
            totalCount: filteredItems.count
        )
    }
    
    func getStatistics(_ request: GetStatisticsRequest) async throws -> GetStatisticsResponse {
        let statistics = try await repository.getStatistics(ownerId: request.ownerId)
        let subjectStatistics = try await repository.getSubjectStatistics(ownerId: request.ownerId)
        let masteryStatistics = try await repository.getMasteryStatistics(ownerId: request.ownerId)
        
        return GetStatisticsResponse(
            statistics: statistics,
            subjectStatistics: subjectStatistics,
            masteryStatistics: masteryStatistics
        )
    }
}
EOF

echo "✅ Swift 6 Actor服务创建完成"

# 5. 更新Xcode项目文件
echo "📁 更新Xcode项目文件..."

# 添加新文件到项目
python3 << 'EOF'
import re

# 读取项目文件
with open('NotBad.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# 添加新文件引用
new_files = [
    'NotBad/Sources/Domain/Extensions/SendableExtensions.swift',
    'NotBad/Sources/Domain/DataTypes/RequestResponseTypes.swift',
    'NotBad/Sources/Application/Actors/ReviewItemActor.swift'
]

# 为每个文件生成UUID和添加引用
for file_path in new_files:
    file_uuid = str(uuid.uuid4()).replace('-', '').upper()[:24]
    file_name = file_path.split('/')[-1]
    
    # 添加文件引用
    file_ref = f'\t\t{file_uuid} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{file_name}"; sourceTree = "<group>"; }};'
    
    # 在PBXFileReference section添加
    content = re.sub(
        r'(/\* End PBXFileReference section \*/)',
        f'{file_ref}\n\\1',
        content
    )

# 保存更新后的文件
with open('NotBad.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✅ Xcode项目文件更新完成")
EOF

echo "✅ 项目文件更新完成"

# 6. 运行构建测试
echo "🔨 运行构建测试..."

if command -v xcodebuild &> /dev/null; then
    echo "正在构建项目..."
    xcodebuild -project NotBad.xcodeproj -scheme NotBad -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
    echo "✅ 构建成功"
else
    echo "⚠️  Xcode未找到，跳过构建测试"
fi

echo "🎉 Swift 6升级修复完成！"
echo ""
echo "主要修复内容："
echo "✅ 更新Swift版本到6.0"
echo "✅ 更新部署目标到iOS 18.0"
echo "✅ 添加Sendable协议支持"
echo "✅ 创建请求/响应类型定义"
echo "✅ 实现Swift 6 Actor服务"
echo "✅ 更新项目配置"
echo ""
echo "请检查Xcode中的警告是否已解决。"
