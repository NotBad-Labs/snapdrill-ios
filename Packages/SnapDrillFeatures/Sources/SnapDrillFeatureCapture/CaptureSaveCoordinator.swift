//
//  CaptureSaveCoordinator.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  采集结果的保存事务编排（无状态）：校验 → 标签 fetch/create → 存图 → 插入 →
//  saveContext；失败时回滚 context + 清理孤儿图片。从 CaptureResultViewModel 抽出，
//  使保存逻辑可独立于 @Observable 环境测试。
//

import Foundation
import UIKit
import SnapDrillCore
import SnapDrillData

/// 采集结果保存时的表单数据快照（值类型）
///
/// 把表单各字段打包成一个值，避免 `save` 的长参数列表（SwiftLint function_parameter_count）。
/// 在 MainActor 上同步构造，捕获"保存那一刻"的表单状态。memberwise init 由编译器生成，
/// 不触发参数数量规则。
struct CaptureFormSnapshot {
    let content: String
    let image: UIImage?
    /// L3：所有维度的选中值实例（扁平），写入 ArchiveItemModel.categoryValues
    let selectedValues: [CategoryValueModel]
    let answerText: String
    let answerImage: UIImage?
}

/// 采集结果保存事务编排器（无状态）
///
/// 必须 `@MainActor`：内部触碰 SwiftData `ModelContext`（repositories）与非 Sendable
/// 的 `@Model`（ArchiveItemModel/TagModel），不能跨 actor 搬运。调用方 ViewModel 同为
/// MainActor 隔离，两者在同一隔离域内安全协作。
@MainActor
struct CaptureSaveCoordinator {
    let repositories: RepositoryContainer
    let imageStorage: ImageStorage

    /// 保存题目：校验 → 标签 → 存图 → 插入 → saveContext。
    /// 失败时回滚 context + 清理孤儿图片，再抛错供调用方处理 UI 反馈。
    func save(_ form: CaptureFormSnapshot) async throws {
        // 声明在 do 块外，确保 catch 中可访问以清理孤儿文件
        var savedImagePath: String?
        var savedAnswerImagePath: String?

        do {
            // 业务规则：题目文字和图片至少有一个
            let contentValue = form.content.isEmpty ? nil : form.content
            guard contentValue != nil || form.image != nil else {
                throw CaptureSaveError.contentAndImageEmpty
            }

            // 持久化题目截图，获取本地相对路径
            if let img = form.image {
                savedImagePath = try await imageStorage.saveImage(img)
            }

            // 持久化答案图片
            if let answerImg = form.answerImage {
                savedAnswerImagePath = try await imageStorage.saveImage(answerImg)
            }

            // 构造 @Model 对象并插入（纯内存），再统一 saveContext。
            // L3：分类经动态维度值（categoryValues）；旧裸字符串字段已不再写入。
            let model = ArchiveItemModel(
                content: contentValue,
                imagePath: savedImagePath,
                answerText: form.answerText.isEmpty ? nil : form.answerText,
                answerImagePath: savedAnswerImagePath
            )
            model.categoryValues = form.selectedValues
            repositories.archive.insert(model)
            try repositories.archive.saveContext()
        } catch {
            // 回滚 mainContext：清除本次操作插入的脏 Tag 和脏 ArchiveItemModel。
            // 单用户本地优先架构下，save 执行期间 mainContext 不存在其他并发未保存变更，
            // rollback 影响范围仅限本次调用，不会丢失其他模块的数据。
            repositories.archive.rollbackContext()
            await cleanupOrphanImages(imagePath: savedImagePath, answerImagePath: savedAnswerImagePath)
            throw error
        }
    }

    /// 清理保存失败时已写入磁盘的孤儿图片文件（best-effort，async 避免阻塞主线程）
    private func cleanupOrphanImages(imagePath: String?, answerImagePath: String?) async {
        if let path = imagePath {
            try? await imageStorage.deleteImage(path: path) // best-effort: 孤儿文件删除失败不影响业务流程
        }
        if let path = answerImagePath {
            try? await imageStorage.deleteImage(path: path) // best-effort: 孤儿文件删除失败不影响业务流程
        }
    }
}
