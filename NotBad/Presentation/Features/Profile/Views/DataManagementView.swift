//
//  DataManagementView.swift
//  NotBad
//
//  数据管理视图 - 主文件
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - DataManagementView

/// 数据管理视图
///
/// 提供数据导出、导入和清理功能。
///
/// ## 文件结构
///
/// - `DataManagementView.swift` - 主视图和 UI 部分
/// - `DataManagementView+Export.swift` - 导出相关方法
/// - `DataManagementView+Import.swift` - 导入相关方法
struct DataManagementView: View {

    // MARK: - Environment

    @Environment(\.modelContext) var modelContext
    @Query var allItems: [ReviewItem]

    // MARK: - State

    @State var showExportSheet = false
    @State var showDeleteAlert = false
    @State var showSuccessToast = false
    @State var toastMessage = ""
    @State var exportedFileURL: URL?
    @State var isExporting = false
    @State var exportProgress: Double = 0
    @State var showImportPicker = false
    
    // 导出筛选状态
    @State var showExportFilterSheet = false
    @State var pendingExportType: ExportType?
    @State var exportFilterConfig = ExportFilterConfig()
    
    // 最近导出缓存
    @State private var cachedFiles: [CachedExportFile] = []
    @State private var showClearCacheAlert = false

    // MARK: - Body

    var body: some View {
        List {
            storageSection
            recentExportsSection
            exportSection
            importSection
            dangerZoneSection
        }
        .navigationTitle("data_management_title")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshCachedFiles()
        }
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
        .sheet(isPresented: $showExportFilterSheet) {
            ExportFilterView(
                exportType: pendingExportType ?? .pdf,
                config: exportFilterConfig,
                allItems: allItems,
                onExport: { performFilteredExport() },
                onCancel: { showExportFilterSheet = false }
            )
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
                toastOverlay
            }
        }
    }

    // MARK: - Toast Overlay

    private var toastOverlay: some View {
        VStack {
            Spacer()
            ToastView(toast: Toast(type: toastMessage.contains("失败") ? .error : .success, message: toastMessage))
                .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(), value: showSuccessToast)
    }

    // MARK: - Computed Properties

    var imageCount: Int {
        allItems.filter { $0.imageData != nil }.count
    }

    var estimatedSize: String {
        let textSize = allItems.reduce(0) { total, item in
            total + item.title.utf8.count + item.note.utf8.count
        }
        let imageSize = allItems.reduce(0) { $0 + ($1.imageData?.count ?? 0) }
        let totalBytes = textSize + imageSize

        return ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file)
    }
    
    /// 刷新缓存文件列表
    func refreshCachedFiles() {
        cachedFiles = ExportCacheManager.shared.getCachedFiles()
    }
}

// MARK: - Sections

extension DataManagementView {

    /// 存储信息部分
    var storageSection: some View {
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
    
    /// 最近导出部分
    @ViewBuilder
    var recentExportsSection: some View {
        if !cachedFiles.isEmpty {
            Section {
                ForEach(cachedFiles) { file in
                    Button {
                        exportedFileURL = file.url
                        showExportSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            // 文件类型图标
                            Image(systemName: file.icon)
                                .font(.title2)
                                .foregroundStyle(fileColor(for: file))
                                .frame(width: 32)
                            
                            // 文件信息
                            VStack(alignment: .leading, spacing: 2) {
                                Text(file.fileName)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                
                                HStack(spacing: 8) {
                                    Text(file.formattedSize)
                                    Text("•")
                                    Text(file.formattedDate)
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            // 分享图标
                            Image(systemName: "square.and.arrow.up")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation {
                                ExportCacheManager.shared.deleteFile(file)
                                refreshCachedFiles()
                            }
                        } label: {
                            Label("common_delete", systemImage: "trash")
                        }
                    }
                }
                
                // 清除所有缓存
                if cachedFiles.count > 1 {
                    Button(role: .destructive) {
                        showClearCacheAlert = true
                    } label: {
                        Label("export_clear_cache", systemImage: "trash")
                    }
                    .alert("export_clear_cache_confirm", isPresented: $showClearCacheAlert) {
                        Button("common_cancel", role: .cancel) { }
                        Button("common_delete", role: .destructive) {
                            withAnimation {
                                ExportCacheManager.shared.deleteAllFiles()
                                refreshCachedFiles()
                            }
                        }
                    } message: {
                        Text("export_clear_cache_message")
                    }
                }
            } header: {
                Text("export_recent_files")
            } footer: {
                Text("export_recent_files_footer")
            }
        }
    }
    
    /// 根据文件类型获取颜色
    private func fileColor(for file: CachedExportFile) -> Color {
        switch file.color {
        case "primary": return Color.brand.primary
        case "success": return Color.brand.success
        case "warning": return Color.brand.warning
        default: return .secondary
        }
    }

    /// 导出部分
    var exportSection: some View {
        Section("data_section_export") {
            // PDF 导出（打印用）- 支持筛选
            Button {
                pendingExportType = .pdf
                showExportFilterSheet = true
            } label: {
                ExportRowLabel(
                    title: "data_export_pdf",
                    description: "data_export_pdf_description",
                    icon: "doc.richtext.fill",
                    color: Color.brand.primary,
                    badge: "export_filterable"
                )
            }
            .disabled(allItems.isEmpty || isExporting)
            
            // CSV 导出（推荐给普通用户）- 支持筛选
            Button {
                pendingExportType = .csv
                showExportFilterSheet = true
            } label: {
                ExportRowLabel(
                    title: "data_export_csv",
                    description: "data_export_csv_description",
                    icon: "tablecells.fill",
                    color: Color.brand.success,
                    badge: "export_filterable"
                )
            }
            .disabled(allItems.isEmpty || isExporting)

            // 完整备份
            Button {
                Task {
                    await exportFullBackup()
                }
            } label: {
                ExportRowLabel(
                    title: "data_full_backup",
                    description: "data_full_backup_description",
                    icon: "archivebox.fill",
                    color: Color.brand.warning,
                    isLoading: isExporting
                )
            }
            .disabled(allItems.isEmpty || isExporting)

            // JSON 导出（给技术用户）
            Button {
                exportData()
            } label: {
                ExportRowLabel(
                    title: "data_export_json",
                    description: "data_export_json_description",
                    icon: "curlybraces",
                    color: .secondary
                )
            }
            .disabled(allItems.isEmpty || isExporting)
            .disabled(allItems.isEmpty || isExporting)
        }
    }

    /// 导入部分
    var importSection: some View {
        Section("data_section_import") {
            Button {
                showImportPicker = true
            } label: {
                ExportRowLabel(
                    title: "data_restore_from_backup",
                    description: "data_restore_description",
                    icon: "square.and.arrow.down.fill",
                    color: Color.brand.secondary
                )
            }
            .disabled(isExporting)
        }
    }

    /// 危险区域部分
    var dangerZoneSection: some View {
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
}

// MARK: - ExportRowLabel

/// 导出行标签组件
private struct ExportRowLabel: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let icon: String
    let color: Color
    var isLoading: Bool = false
    var badge: LocalizedStringKey? = nil

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                HStack {
                    Text(title)
                    if let badge = badge {
                        Text(badge)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.brand.primary.opacity(0.15))
                            .foregroundStyle(Color.brand.primary)
                            .clipShape(Capsule())
                    }
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Export Types

/// 导出类型
enum ExportType {
    case pdf
    case csv
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
