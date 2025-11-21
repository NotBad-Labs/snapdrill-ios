import Foundation
import SwiftData

/// 复习项 (Review Item)
/// 代表一个具体的错题或需要复习的知识点
@Model
final class ReviewItem {
    /// 唯一标识符
    var id: UUID
    
    /// 错题图片数据
    @Attribute(.externalStorage) // 允许大数据存储在外部文件中，避免数据库过大
    var imageData: Data?
    
    /// 标题（通常是 OCR 识别出的首行文字或用户自定义）
    var title: String
    
    /// 用户备注/笔记
    var note: String
    
    /// 创建时间
    var createdAt: Date
    
    /// 更新时间
    var updatedAt: Date
    
    /// 掌握程度 (0: 新建, 1: 模糊, 2: 熟悉, 3: 掌握)
    var masteryLevel: Int
    
    /// 下次复习时间 (基于艾宾浩斯或其他算法计算)
    var nextReviewDate: Date
    
    /// 复习次数
    var reviewCount: Int
    
    /// 学科
    var subject: String
    
    /// 年级
    var grade: String
    
    /// 知识点标签 (逗号分隔)
    var tags: String
    
    init(
        id: UUID = UUID(),
        imageData: Data? = nil,
        title: String = "",
        note: String = "",
        createdAt: Date = Date(),
        masteryLevel: Int = 0,
        subject: String = "数学",
        grade: String = "高一",
        tags: String = ""
    ) {
        self.id = id
        self.imageData = imageData
        self.title = title.isEmpty ? "未命名错题" : title
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.masteryLevel = masteryLevel
        self.nextReviewDate = createdAt // 初始状态下，立即需要复习或按策略推迟
        self.reviewCount = 0
        self.subject = subject
        self.grade = grade
        self.tags = tags
    }
}
