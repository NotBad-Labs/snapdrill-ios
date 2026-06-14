//
//  ResolvedExportSheet.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  导出结果预览 Sheet，展示生成的 PDF 并提供分享功能。
//

import SwiftUI
import SnapDrillCore
import SnapDrillData

/// Helper to resolve IDs to Models for Export Sheet
struct ResolvedExportSheet: View {
    let ids: Set<UUID>
    @Environment(\.repositories) private var repositories
    @State private var phase: ResolvePhase = .loading

    var body: some View {
        Group {
            switch phase {
            case .loading:
                ProgressView(L10n.Library.generating)
                    .accessible(label: L10n.Common.loading)
            case .loaded(let resolvedItems):
                ExportOptionsSheet(items: resolvedItems)
            case .failed(let loadError):
                // 读取失败时显式反馈，避免渲染成 0 项空白导出表（家长以为选的题没了）
                ContentUnavailableView {
                    Label(L10n.Errors.loadFailed, systemImage: "exclamationmark.triangle")
                } description: {
                    Text(loadError)
                } actions: {
                    Button(L10n.Common.retry) { resolveItems() }
                }
            }
        }
        .task {
            resolveItems()
        }
    }

    private func resolveItems() {
        phase = .loading
        do {
            let resolvedItems = try repositories.review.fetchModels(by: ids).map { $0.toExportSnapshot() }
            phase = .loaded(resolvedItems)
        } catch {
            SnapDrillLogger.generic.error("解析导出题目失败: \(error.localizedDescription)")
            phase = .failed(error.localizedDescription)
        }
    }
}

private enum ResolvePhase {
    case loading
    case loaded([ReviewExportSnapshot])
    case failed(String)
}

#Preview {
    ResolvedExportSheet(ids: [])
}
