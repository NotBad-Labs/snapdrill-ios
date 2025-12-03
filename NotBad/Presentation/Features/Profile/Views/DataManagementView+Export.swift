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
    
    /// 根据筛选条件获取要导出的项目
    func filteredItemsForExport() -> [ReviewItem] {
        exportFilterConfig.filter(allItems)
    }
    
    /// 执行筛选后的导出
    func performFilteredExport() {
        showExportFilterSheet = false
        
        switch pendingExportType {
        case .pdf:
            exportToPDF()
        case .csv:
            exportToCSV()
        case .none:
            break
        }
        
        // 刷新缓存列表
        refreshCachedFiles()
    }

    /// 导出为 PDF（打印用）
    func exportToPDF() {
        let itemsToExport = filteredItemsForExport()
        
        guard !itemsToExport.isEmpty else {
            showToast(String(localized: "export_no_items_in_range"), isError: true)
            return
        }
        
        let pdfData = PDFExportService.shared.exportToPDF(
            items: itemsToExport,
            title: String(localized: "pdf_export_title"),
            includeImages: true,
            includeNotes: true
        )
        
        do {
            let fileName = exportFileName(type: "pdf", count: itemsToExport.count)
            // 使用缓存管理器保存文件（而非临时目录）
            let cachedURL = try ExportCacheManager.shared.cacheExportFile(data: pdfData, fileName: fileName)
            exportedFileURL = cachedURL
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
        let itemsToExport = filteredItemsForExport()
        
        guard !itemsToExport.isEmpty else {
            showToast(String(localized: "export_no_items_in_range"), isError: true)
            return
        }
        
        // CSV 表头（使用本地化字符串）
        var csvString = "ID,标题,笔记,科目,题型,难度,来源,年级,掌握程度,复习次数,创建时间,知识点\n"

        for item in itemsToExport {
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
            
            let fileName = exportFileName(type: "csv", count: itemsToExport.count)
            // 使用缓存管理器保存文件
            let cachedURL = try ExportCacheManager.shared.cacheExportFile(data: data, fileName: fileName)
            exportedFileURL = cachedURL
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
    
    /// 生成导出文件名（包含筛选条件信息）
    func exportFileName(type: String, count: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        
        // 构建文件名各部分
        var parts: [String] = ["notbad"]
        
        // 时间范围
        switch exportFilterConfig.dateRangeType {
        case .all:
            break // 不添加
        case .thisWeek:
            parts.append("week")
        case .thisMonth:
            parts.append("month_\(dateFormatter.string(from: Date()))")
        case .lastMonth:
            let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            parts.append("month_\(dateFormatter.string(from: lastMonth))")
        case .thisYear:
            let year = Calendar.current.component(.year, from: Date())
            parts.append("year_\(year)")
        case .custom:
            let start = dateFormatter.string(from: exportFilterConfig.customStartDate)
            let end = dateFormatter.string(from: exportFilterConfig.customEndDate)
            parts.append("\(start)-\(end)")
        }
        
        // 学科（如果只选了1-2个）
        if exportFilterConfig.filterBySubject && !exportFilterConfig.selectedSubjects.isEmpty {
            if exportFilterConfig.selectedSubjects.count <= 2 {
                let subjectNames = exportFilterConfig.selectedSubjects.map { $0.rawValue }.joined(separator: "_")
                parts.append(subjectNames)
            }
        }
        
        // 掌握程度
        if exportFilterConfig.filterByMastery {
            switch exportFilterConfig.masteryFilterType {
            case .notMastered:
                parts.append("未掌握")
            case .veryWeak:
                parts.append("薄弱")
            case .needsReview:
                parts.append("需复习")
            case .mastered:
                parts.append("已掌握")
            case .customRange:
                break
            }
        }
        
        // 数量
        parts.append("\(count)题")
        
        return parts.joined(separator: "_") + ".\(type)"
    }
}
