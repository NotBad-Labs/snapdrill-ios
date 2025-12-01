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

    /// 导出部分
    var exportSection: some View {
        Section("data_section_export") {
            // JSON 导出
            Button {
                exportData()
            } label: {
                ExportRowLabel(
                    title: "data_export_json",
                    description: "data_export_json_description",
                    icon: "square.and.arrow.up.fill",
                    color: Color.brand.primary
                )
            }
            .disabled(allItems.isEmpty || isExporting)

            // CSV 导出
            Button {
                exportToCSV()
            } label: {
                ExportRowLabel(
                    title: "data_export_csv",
                    description: "data_export_csv_description",
                    icon: "tablecells.fill",
                    color: Color.brand.success
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

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                HStack {
                    Text(title)
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
