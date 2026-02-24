//
//  PrivacySettingsView.swift
//  SnapDrillFeatures
//
//  Created by SnapDrill Labs on 2026/01/02.
//

import SwiftUI
import SwiftData
import SnapDrillData
import UniformTypeIdentifiers

/// 隐私设置页面
struct PrivacySettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("analyticsEnabled") private var analyticsEnabled = false
    @AppStorage("crashReportingEnabled") private var crashReportingEnabled = true
    
    @State private var showingExportOptions = false
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var isExporting = false
    @State private var exportError: String?
    
    var body: some View {
        List {
            Section {
                Toggle("使用数据分析", isOn: $analyticsEnabled)
                Toggle("崩溃报告", isOn: $crashReportingEnabled)
            } header: {
                Text("数据收集")
            } footer: {
                Text("帮助我们改进应用体验，您的数据将被匿名处理")
            }
            
            Section {
                Button {
                    showingExportOptions = true
                } label: {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .controlSize(.small)
                            Text("导出中...")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("导出我的数据")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(isExporting)
            } header: {
                Text("数据管理")
            } footer: {
                Text("导出所有学习数据为 JSON 或 CSV 格式")
            }
            
            if let error = exportError {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("隐私与安全")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("选择导出格式", isPresented: $showingExportOptions) {
            Button("JSON 格式") {
                Task {
                    await exportData(format: .json)
                }
            }
            Button("CSV 格式") {
                Task {
                    await exportData(format: .csv)
                }
            }
            Button("取消", role: .cancel) {}
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    private func exportData(format: ExportFormat) async {
        isExporting = true
        exportError = nil
        
        do {
            let repository = ReviewRepository(modelContext: modelContext)
            let items = try repository.fetchAll()
            
            // Convert to Sendable value types before crossing actor boundary
            let exportableItems = items.map { item in
                ExportableItem(
                    id: item.id,
                    content: item.content,
                    subject: item.subject,
                    source: item.source,
                    difficulty: item.difficulty,
                    answerText: item.answerText,
                    createdAt: item.createdAt,
                    lastReviewedAt: item.lastReviewedAt,
                    nextReviewAt: item.nextReviewAt,
                    tags: item.tags?.map { $0.name } ?? []
                )
            }
            
            let exporter = DataExporter()
            let fileURL = try await exporter.export(items: exportableItems, format: format)
            
            await MainActor.run {
                exportedFileURL = fileURL
                showingShareSheet = true
                isExporting = false
            }
        } catch {
            await MainActor.run {
                exportError = "导出失败: \(error.localizedDescription)"
                isExporting = false
            }
        }
    }
}

/// Sendable value type for export
struct ExportableItem: Sendable {
    let id: UUID
    let content: String
    let subject: String
    let source: String
    let difficulty: Int
    let answerText: String
    let createdAt: Date
    let lastReviewedAt: Date?
    let nextReviewAt: Date?
    let tags: [String]
}

/// 导出格式
enum ExportFormat {
    case json
    case csv
    
    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        }
    }
    
    var mimeType: String {
        switch self {
        case .json: return "application/json"
        case .csv: return "text/csv"
        }
    }
}

/// 数据导出器
actor DataExporter {
    func export(items: [ExportableItem], format: ExportFormat) throws -> URL {
        let data: Data
        
        switch format {
        case .json:
            data = try exportJSON(items: items)
        case .csv:
            data = try exportCSV(items: items)
        }
        
        // 保存到临时目录
        let fileName = "SnapDrill_Export_\(Date().formatted(date: .numeric, time: .omitted)).\(format.fileExtension)"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try data.write(to: fileURL)
        return fileURL
    }
    
    private func exportJSON(items: [ExportableItem]) throws -> Data {
        let exportItems = items.map { item in
            [
                "id": item.id.uuidString,
                "content": item.content,
                "subject": item.subject,
                "source": item.source,
                "difficulty": item.difficulty,
                "answerText": item.answerText,
                "createdAt": item.createdAt.ISO8601Format(),
                "lastReviewedAt": item.lastReviewedAt?.ISO8601Format() ?? "",
                "nextReviewAt": item.nextReviewAt?.ISO8601Format() ?? "",
                "tags": item.tags.joined(separator: ", ")
            ] as [String: Any]
        }
        
        return try JSONSerialization.data(withJSONObject: exportItems, options: .prettyPrinted)
    }
    
    private func exportCSV(items: [ExportableItem]) throws -> Data {
        var csv = "ID,内容,学科,来源,难度,答案,创建时间,上次复习,下次复习,标签\n"
        
        for item in items {
            let row = [
                item.id.uuidString,
                escapeCSV(item.content),
                escapeCSV(item.subject),
                escapeCSV(item.source),
                "\(item.difficulty)",
                escapeCSV(item.answerText),
                item.createdAt.ISO8601Format(),
                item.lastReviewedAt?.ISO8601Format() ?? "",
                item.nextReviewAt?.ISO8601Format() ?? "",
                escapeCSV(item.tags.joined(separator: "; "))
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        guard let data = csv.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        
        return data
    }
    
    private func escapeCSV(_ string: String) -> String {
        let escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}

enum ExportError: LocalizedError {
    case encodingFailed
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "数据编码失败"
        }
    }
}

/// ShareSheet for UIKit integration
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        PrivacySettingsView()
            .modelContainer(for: ReviewItemModel.self, inMemory: true)
    }
}
