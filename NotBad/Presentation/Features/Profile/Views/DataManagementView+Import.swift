//
//  DataManagementView+Import.swift
//  NotBad
//
//  数据管理 - 导入功能
//

import SwiftUI
import SwiftData

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
        var importedCount = 0

        for itemDict in items {
            guard let title = itemDict["title"] as? String else { continue }

            let item = ReviewItem(
                imageData: nil,
                title: title,
                note: itemDict["note"] as? String ?? "",
                subject: Subject(rawValue: itemDict["subject"] as? String ?? "") ?? .other,
                grade: Grade(rawValue: itemDict["grade"] as? String ?? "") ?? .grade10,
                knowledgePoints: KnowledgePoints(from: itemDict["knowledgePoints"] as? String ?? "")
            )

            // 设置其他属性
            if let difficultyRaw = itemDict["difficulty"] as? Int {
                item.difficulty = Difficulty(rawValue: difficultyRaw) ?? .medium
            }
            if let sourceRaw = itemDict["source"] as? String {
                item.source = Source(rawValue: sourceRaw) ?? .other
            }
            if let questionTypeRaw = itemDict["questionType"] as? String {
                item.questionType = ReviewItemType(rawValue: questionTypeRaw) ?? .other
            }
            if let masteryLevel = itemDict["masteryLevel"] as? Int {
                item.masteryLevel = masteryLevel
            }
            if let reviewCount = itemDict["reviewCount"] as? Int {
                item.reviewCount = reviewCount
            }

            // 导入图片
            if let imageName = itemDict["imageName"] as? String,
               let imagesDir = imagesDir {
                let imageURL = imagesDir.appendingPathComponent(imageName)
                if let imageData = try? Data(contentsOf: imageURL) {
                    item.imageData = imageData
                }
            }

            await MainActor.run {
                modelContext.insert(item)
            }
            importedCount += 1
        }

        await MainActor.run {
            do {
                try modelContext.save()
                showToast("成功导入 \(importedCount) 道错题", isError: false)
            } catch {
                showToast("保存失败", isError: true)
            }
        }
    }

    /// 删除所有数据
    func deleteAllData() {
        for item in allItems {
            modelContext.delete(item)
        }

        do {
            try modelContext.save()
            showToast("数据已清空", isError: false)
        } catch {
            showToast("清空失败", isError: true)
        }
    }

    // MARK: - Toast Helper

    func showToast(_ message: String, isError: Bool) {
        toastMessage = message
        showSuccessToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSuccessToast = false
        }
    }
}
