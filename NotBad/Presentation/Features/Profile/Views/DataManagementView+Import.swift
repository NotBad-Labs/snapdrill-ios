//
//  DataManagementView+Import.swift
//  NotBad
//
//  数据管理 - 导入功能
//

import SwiftUI

// MARK: - Import Methods

extension DataManagementView {

    /// 处理文件导入
    func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            Task {
                await importData(from: url)
            }

        case .failure(let error):
            showToast("导入失败: \(error.localizedDescription)", isError: true)
        }
    }

    /// 从 URL 导入数据
    func importData(from url: URL) async {
        guard url.startAccessingSecurityScopedResource() else {
            await MainActor.run {
                showToast("无法访问文件", isError: true)
            }
            return
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        do {
            let data = try Data(contentsOf: url)

            // 尝试解析 JSON
            if let items = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                await importItems(items, imagesDir: nil)
            } else {
                await MainActor.run {
                    showToast("文件格式不支持", isError: true)
                }
            }
        } catch {
            await MainActor.run {
                showToast("导入失败: \(error.localizedDescription)", isError: true)
            }
        }
    }

    /// 导入错题数据
    func importItems(_ items: [[String: Any]], imagesDir: URL?) async {
        guard let factory = dependencyFactory else {
            await MainActor.run {
                showToast("导入失败：依赖未初始化", isError: true)
            }
            return
        }
        
        var importedItems: [ReviewItem] = []

        for itemDict in items {
            guard let title = itemDict["title"] as? String else { continue }

            // 创建领域实体
            let reviewItem = ReviewItem(
                imageData: nil,
                title: title,
                note: itemDict["note"] as? String ?? "",
                subject: Subject(rawValue: itemDict["subject"] as? String ?? "") ?? .other,
                grade: Grade(rawValue: itemDict["grade"] as? String ?? "") ?? .grade10,
                knowledgePoints: KnowledgePoints(from: itemDict["knowledgePoints"] as? String ?? "")
            )

            // 设置其他属性
            if let difficultyRaw = itemDict["difficulty"] as? Int {
                reviewItem.difficulty = Difficulty(rawValue: difficultyRaw) ?? .medium
            }
            if let sourceRaw = itemDict["source"] as? String {
                reviewItem.source = Source(rawValue: sourceRaw) ?? .other
            }
            // 兼容旧版 "questionType" 和新版 "reviewItemType" 键名
            if let reviewItemTypeRaw = itemDict["reviewItemType"] as? String ?? itemDict["questionType"] as? String {
                reviewItem.reviewItemType = ReviewItemType(rawValue: reviewItemTypeRaw) ?? .other
            }
            if let masteryLevel = itemDict["masteryLevel"] as? Int {
                reviewItem.masteryLevel = masteryLevel
            }
            if let reviewCount = itemDict["reviewCount"] as? Int {
                reviewItem.reviewCount = reviewCount
            }

            // 导入图片
            if let imageName = itemDict["imageName"] as? String,
               let imagesDir = imagesDir {
                let imageURL = imagesDir.appendingPathComponent(imageName)
                if let imageData = try? Data(contentsOf: imageURL) {
                    reviewItem.imageData = imageData
                }
            }

            importedItems.append(reviewItem)
        }

        // 使用 Repository 批量保存
        await MainActor.run {
            let repository = factory.makeReviewItemRepository()
            do {
                try repository.save(importedItems)
                showToast("成功导入 \(importedItems.count) 道错题", isError: false)
                // 刷新数据（强制重新加载）
                Task { await loadData(forceRefresh: true) }
            } catch {
                showToast("保存失败: \(error.localizedDescription)", isError: true)
            }
        }
    }

    /// 删除所有数据
    func deleteAllData() {
        Task {
            // 使用 Use Case 删除所有数据
            guard let factory = dependencyFactory else {
                showToast("删除失败：依赖未初始化", isError: true)
                return
            }
            
            let deleteUseCase = factory.makeDeleteReviewItemUseCase()
            
            // 批量删除所有 item
            let itemIds = allItems.map { $0.id }
            do {
                try await deleteUseCase.execute(itemIds: itemIds)
                // 刷新数据（强制重新加载）
                allItems = []
                await loadData(forceRefresh: true)
                showToast("数据已清空", isError: false)
            } catch {
                showToast("删除失败", isError: true)
            }
        }
    }

    // MARK: - Toast Helper

    func showToast(_ message: String, isError: Bool) {
        toastMessage = message
        showSuccessToast = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            showSuccessToast = false
        }
    }
}
