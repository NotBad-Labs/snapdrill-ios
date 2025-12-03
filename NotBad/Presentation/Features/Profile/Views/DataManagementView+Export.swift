//
//  DataManagementView+Export.swift
//  NotBad
//
//  数据管理 - 导出功能
//

import SwiftUI
import SwiftData

// MARK: - Export Methods

extension DataManagementView {

    /// 导出为 PDF（打印用）
    func exportToPDF() {
        let pdfData = PDFExportService.shared.exportToPDF(
            items: allItems,
            title: String(localized: "pdf_export_title"),
            includeImages: true,
            includeNotes: true
        )
        
        do {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("notbad_错题本_\(dateString()).pdf")
            try pdfData.write(to: tempURL)
            exportedFileURL = tempURL
            showExportSheet = true
        } catch {
            showToast(String(localized: "export_failed"), isError: true)
        }
    }

    /// 导出为 JSON
    func exportData() {
        let exportItems: [[String: Any]] = allItems.map { item in
            [
                "id": item.id.uuidString,
                "title": item.title,
                "note": item.note,
                "subject": item.subject.rawValue,
                "questionType": item.questionType.rawValue,
                "difficulty": item.difficulty.rawValue,
                "source": item.source.rawValue,
                "grade": item.grade.rawValue,
                "masteryLevel": item.masteryLevel,
                "reviewCount": item.reviewCount,
                "createdAt": ISO8601DateFormatter().string(from: item.createdAt),
                "knowledgePoints": item.knowledgePoints.rawValue,
                "nextReviewDate": ISO8601DateFormatter().string(from: item.nextReviewDate)
            ]
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportItems, options: [.prettyPrinted, .sortedKeys])
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("notbad_export_\(Date().timeIntervalSince1970).json")
            try jsonData.write(to: tempURL)
            exportedFileURL = tempURL
            showExportSheet = true
        } catch {
            showToast("导出失败", isError: true)
        }
    }

    /// 导出为 CSV
    func exportToCSV() {
        // CSV 表头（使用本地化字符串）
        var csvString = "ID,标题,笔记,科目,题型,难度,来源,年级,掌握程度,复习次数,创建时间,知识点\n"

        for item in allItems {
            let row = [
                item.id.uuidString,
                escapeCSV(item.title),
                escapeCSV(item.note),
                item.subject.displayName,  // 使用显示名称而非 rawValue
                item.questionType.displayName,
                item.difficulty.displayName,
                item.source.displayName,
                item.grade.displayName,
                String(item.masteryLevel),
                String(item.reviewCount),
                ISO8601DateFormatter().string(from: item.createdAt),
                escapeCSV(item.knowledgePoints.rawValue)
            ].joined(separator: ",")
            csvString += row + "\n"
        }

        do {
            // 添加 UTF-8 BOM，让 Excel 正确识别编码
            var data = Data([0xEF, 0xBB, 0xBF])  // UTF-8 BOM
            data.append(csvString.data(using: .utf8)!)
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("notbad_export_\(Date().timeIntervalSince1970).csv")
            try data.write(to: tempURL)
            exportedFileURL = tempURL
            showExportSheet = true
        } catch {
            showToast("导出失败", isError: true)
        }
    }

    /// 导出完整备份（含图片）
    func exportFullBackup() async {
        await MainActor.run {
            isExporting = true
            exportProgress = 0
        }

        do {
            // 创建临时目录
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("notbad_backup_\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            // 创建图片目录
            let imagesDir = tempDir.appendingPathComponent("images")
            try FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)

            // 导出数据和图片
            var exportItems: [[String: Any]] = []
            let totalItems = allItems.count

            for (index, item) in allItems.enumerated() {
                var dict: [String: Any] = [
                    "id": item.id.uuidString,
                    "title": item.title,
                    "note": item.note,
                    "subject": item.subject.rawValue,
                    "questionType": item.questionType.rawValue,
                    "difficulty": item.difficulty.rawValue,
                    "source": item.source.rawValue,
                    "grade": item.grade.rawValue,
                    "masteryLevel": item.masteryLevel,
                    "reviewCount": item.reviewCount,
                    "createdAt": ISO8601DateFormatter().string(from: item.createdAt),
                    "updatedAt": ISO8601DateFormatter().string(from: item.updatedAt),
                    "knowledgePoints": item.knowledgePoints.rawValue,
                    "nextReviewDate": ISO8601DateFormatter().string(from: item.nextReviewDate),
                    "errorType": item.errorType.rawValue
                ]

                // 导出图片
                if let imageData = item.imageData {
                    let imageName = "\(item.id.uuidString).jpg"
                    let imageURL = imagesDir.appendingPathComponent(imageName)
                    try imageData.write(to: imageURL)
                    dict["imageName"] = imageName
                }

                exportItems.append(dict)

                await MainActor.run {
                    exportProgress = Double(index + 1) / Double(totalItems)
                }
            }

            // 写入 JSON 文件
            let jsonData = try JSONSerialization.data(withJSONObject: exportItems, options: [.prettyPrinted, .sortedKeys])
            let jsonURL = tempDir.appendingPathComponent("data.json")
            try jsonData.write(to: jsonURL)

            // 写入元数据
            let metadata: [String: Any] = [
                "version": "1.0",
                "exportDate": ISO8601DateFormatter().string(from: Date()),
                "itemCount": allItems.count,
                "imageCount": imageCount,
                "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
            ]
            let metadataData = try JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted)
            let metadataURL = tempDir.appendingPathComponent("metadata.json")
            try metadataData.write(to: metadataURL)

            // 创建 ZIP 文件
            let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent("notbad_backup_\(dateString()).zip")
            try await createZipFile(from: tempDir, to: zipURL)

            // 清理临时目录
            try? FileManager.default.removeItem(at: tempDir)

            await MainActor.run {
                exportedFileURL = zipURL
                isExporting = false
                showExportSheet = true
            }
        } catch {
            await MainActor.run {
                isExporting = false
                showToast("备份失败: \(error.localizedDescription)", isError: true)
            }
        }
    }

    // MARK: - Helper Methods

    func escapeCSV(_ string: String) -> String {
        let escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") || escaped.contains("\"") {
            return "\"\(escaped)\""
        }
        return escaped
    }

    func createZipFile(from sourceDir: URL, to destinationURL: URL) async throws {
        let coordinator = NSFileCoordinator()
        var error: NSError?

        coordinator.coordinate(readingItemAt: sourceDir, options: .forUploading, error: &error) { zipURL in
            try? FileManager.default.copyItem(at: zipURL, to: destinationURL)
        }

        if let error = error {
            throw error
        }
    }

    func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
}
