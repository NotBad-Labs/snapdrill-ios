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
    
    // MARK: - Body
    
    var body: some View {
        List {
            storageSection
            exportSection
            dangerZoneSection
        }
        .navigationTitle("数据管理")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showExportSheet) {
            if let url = exportedFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("确认清空所有数据？", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("此操作不可恢复，所有错题记录将被永久删除。")
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
        Section("存储信息") {
            HStack {
                Label("错题数量", systemImage: "doc.text.fill")
                Spacer()
                Text("\(allItems.count) 道")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Label("图片数量", systemImage: "photo.fill")
                Spacer()
                Text("\(imageCount) 张")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Label("预估大小", systemImage: "externaldrive.fill")
                Spacer()
                Text(estimatedSize)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Export Section
    
    private var exportSection: some View {
        Section("数据导出") {
            Button {
                exportData()
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("导出为 JSON")
                        Text("导出所有错题数据（不含图片）")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "square.and.arrow.up.fill")
                        .foregroundStyle(Color.brand.primary)
                }
            }
            .disabled(allItems.isEmpty)
            
            Button {
                exportToCSV()
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("导出为 CSV")
                        Text("可用 Excel 打开查看")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "tablecells.fill")
                        .foregroundStyle(Color.brand.success)
                }
            }
            .disabled(allItems.isEmpty)
        }
    }
    
    // MARK: - Danger Zone Section
    
    private var dangerZoneSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("清空所有数据", systemImage: "trash.fill")
            }
            .disabled(allItems.isEmpty)
        } header: {
            Text("危险操作")
        } footer: {
            Text("清空数据后无法恢复，请谨慎操作。建议先导出备份。")
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
