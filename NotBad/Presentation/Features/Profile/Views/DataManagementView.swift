//
//  DataManagementView.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - DataManagementView

/// 数据管理视图
///
/// 提供数据导出、导入和清理功能。
struct DataManagementView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [ReviewItem]
    
    // MARK: - State
    
    @State private var showExportSheet = false
    @State private var showDeleteAlert = false
    @State private var showSuccessToast = false
    @State private var toastMessage = ""
    @State private var exportedFileURL: URL?
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    @State private var showImportPicker = false
    
    // MARK: - Body
    
    var body: some View {
        List {
            storageSection
            exportSection
            importSection
            dangerZoneSection
        }
        .navigationTitle("data_management_title")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showExportSheet) {
            if let url = exportedFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.json, .zip],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert("data_confirm_delete_all", isPresented: $showDeleteAlert) {
            Button("common_cancel", role: .cancel) { }
            Button("data_clear", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("data_delete_warning")
        }
        .overlay {
            if showSuccessToast {
                VStack {
                    Spacer()
                    ToastView(toast: Toast(type: toastMessage.contains("失败") ? .error : .success, message: toastMessage))
                        .padding(.bottom, DesignTokens.Spacing.xl)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: showSuccessToast)
            }
        }
    }
    
    // MARK: - Storage Section
    
    private var storageSection: some View {
        Section("data_section_storage") {
            HStack {
                Label("data_item_count", systemImage: "doc.text.fill")
                Spacer()
                Text(String(format: String(localized: "data_items_unit"), allItems.count))
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Label("data_image_count", systemImage: "photo.fill")
                Spacer()
                Text(String(format: String(localized: "data_images_unit"), imageCount))
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Label("data_estimated_size", systemImage: "externaldrive.fill")
                Spacer()
                Text(estimatedSize)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Export Section
    
    private var exportSection: some View {
        Section("data_section_export") {
            Button {
                exportData()
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("data_export_json")
                        Text("data_export_json_description")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "square.and.arrow.up.fill")
                        .foregroundStyle(Color.brand.primary)
                }
            }
            .disabled(allItems.isEmpty || isExporting)
            
            Button {
                exportToCSV()
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("data_export_csv")
                        Text("data_export_csv_description")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "tablecells.fill")
                        .foregroundStyle(Color.brand.success)
                }
            }
            .disabled(allItems.isEmpty || isExporting)
            
            Button {
                Task {
                    await exportFullBackup()
                }
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        HStack {
                            Text("data_full_backup")
                            if isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        Text("data_full_backup_description")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "archivebox.fill")
                        .foregroundStyle(Color.brand.warning)
                }
            }
            .disabled(allItems.isEmpty || isExporting)
        }
    }
    
    // MARK: - Import Section
    
    private var importSection: some View {
        Section("data_section_import") {
            Button {
                showImportPicker = true
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("data_restore_from_backup")
                        Text("data_restore_description")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "square.and.arrow.down.fill")
                        .foregroundStyle(Color.brand.secondary)
                }
            }
            .disabled(isExporting)
        }
    }
    
    // MARK: - Danger Zone Section
    
    private var dangerZoneSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("data_clear_all", systemImage: "trash.fill")
            }
            .disabled(allItems.isEmpty)
        } header: {
            Text("data_section_danger_zone")
        } footer: {
            Text("data_danger_zone_footer")
        }
    }
    
    // MARK: - Computed Properties
    
    private var imageCount: Int {
        allItems.filter { $0.imageData != nil }.count
    }
    
    private var estimatedSize: String {
        let textSize = allItems.reduce(0) { total, item in
            total + item.title.utf8.count + item.note.utf8.count
        }
        let imageSize = allItems.reduce(0) { $0 + ($1.imageData?.count ?? 0) }
        let totalBytes = textSize + imageSize
        
        return ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file)
    }
    
    // MARK: - Methods
    
    private func exportData() {
        let exportItems: [[String: Any]] = allItems.map { item in
            let dict: [String: Any] = [
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
            return dict
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportItems, options: [.prettyPrinted, .sortedKeys])
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("notbad_export_\(Date().timeIntervalSince1970).json")
            try jsonData.write(to: tempURL)
            exportedFileURL = tempURL
            showExportSheet = true
        } catch {
            toastMessage = "导出失败"
            showSuccessToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSuccessToast = false
            }
        }
    }
    
    private func exportToCSV() {
        var csvString = "ID,标题,笔记,科目,题型,难度,来源,年级,掌握程度,复习次数,创建时间,知识点\n"
        
        for item in allItems {
            let row = [
                item.id.uuidString,
                escapeCSV(item.title),
                escapeCSV(item.note),
                item.subject.rawValue,
                item.questionType.rawValue,
                String(item.difficulty.rawValue),
                item.source.rawValue,
                item.grade.rawValue,
                String(item.masteryLevel),
                String(item.reviewCount),
                ISO8601DateFormatter().string(from: item.createdAt),
                escapeCSV(item.knowledgePoints.rawValue)
            ].joined(separator: ",")
            csvString += row + "\n"
        }
        
        do {
            let data = csvString.data(using: .utf8)!
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("notbad_export_\(Date().timeIntervalSince1970).csv")
            try data.write(to: tempURL)
            exportedFileURL = tempURL
            showExportSheet = true
        } catch {
            toastMessage = "导出失败"
            showSuccessToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSuccessToast = false
            }
        }
    }
    
    private func escapeCSV(_ string: String) -> String {
        let escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") || escaped.contains("\"") {
            return "\"\(escaped)\""
        }
        return escaped
    }
    
    private func deleteAllData() {
        for item in allItems {
            modelContext.delete(item)
        }
        
        do {
            try modelContext.save()
            toastMessage = "数据已清空"
            showSuccessToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSuccessToast = false
            }
        } catch {
            toastMessage = "清空失败"
            showSuccessToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSuccessToast = false
            }
        }
    }
    
    // MARK: - Full Backup Export
    
    private func exportFullBackup() async {
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
                toastMessage = "备份失败: \(error.localizedDescription)"
                showSuccessToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSuccessToast = false
                }
            }
        }
    }
    
    private func createZipFile(from sourceDir: URL, to destinationURL: URL) async throws {
        let coordinator = NSFileCoordinator()
        var error: NSError?
        
        coordinator.coordinate(readingItemAt: sourceDir, options: .forUploading, error: &error) { zipURL in
            try? FileManager.default.copyItem(at: zipURL, to: destinationURL)
        }
        
        if let error = error {
            throw error
        }
    }
    
    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
    
    // MARK: - Import
    
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            Task {
                await importData(from: url)
            }
            
        case .failure(let error):
            toastMessage = "导入失败: \(error.localizedDescription)"
            showSuccessToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSuccessToast = false
            }
        }
    }
    
    private func importData(from url: URL) async {
        guard url.startAccessingSecurityScopedResource() else {
            await MainActor.run {
                toastMessage = "无法访问文件"
                showSuccessToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSuccessToast = false
                }
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
                    toastMessage = "文件格式不支持"
                    showSuccessToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showSuccessToast = false
                    }
                }
            }
        } catch {
            await MainActor.run {
                toastMessage = "导入失败: \(error.localizedDescription)"
                showSuccessToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSuccessToast = false
                }
            }
        }
    }
    
    private func importItems(_ items: [[String: Any]], imagesDir: URL?) async {
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
                toastMessage = "成功导入 \(importedCount) 道错题"
                showSuccessToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSuccessToast = false
                }
            } catch {
                toastMessage = "保存失败"
                showSuccessToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSuccessToast = false
                }
            }
        }
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DataManagementView()
            .modelContainer(for: ReviewItem.self, inMemory: true)
    }
}
